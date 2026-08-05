begin;

-- Constrain the reserved quota feature names to the client's UsageFeature enum.
alter table public.usage_quotas
  drop constraint if exists usage_quotas_feature_check;
alter table public.usage_quotas
  add constraint usage_quotas_feature_check check (
    feature in ('local_assistant', 'gemini_assistant', 'camera_solver')
  );

-- Backend-only audit trail for remote assistant calls.
-- It must never contain prompt text, model output, an API key, or a token.
create table if not exists public.ai_assistant_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  feature text not null,
  event_type text not null,
  model text,
  intent text,
  input_characters integer,
  output_characters integer,
  latency_ms integer,
  reason text,
  created_at timestamptz not null default now(),
  constraint ai_assistant_events_feature_check check (
    feature in ('gemini_assistant', 'camera_solver')
  ),
  constraint ai_assistant_events_type_check check (
    event_type in (
      'request_received',
      'input_rejected',
      'entitlement_denied',
      'quota_denied',
      'provider_called',
      'provider_failed',
      'response_returned',
      'response_rejected'
    )
  ),
  constraint ai_assistant_events_counts_check check (
    (input_characters is null or input_characters >= 0)
    and (output_characters is null or output_characters >= 0)
    and (latency_ms is null or latency_ms >= 0)
  )
);

create index if not exists ai_assistant_events_user_id_idx
  on public.ai_assistant_events (user_id);
create index if not exists ai_assistant_events_created_at_idx
  on public.ai_assistant_events (created_at);

alter table public.ai_assistant_events enable row level security;

revoke all on table public.ai_assistant_events from anon, authenticated;
grant select, insert, update, delete on table public.ai_assistant_events
  to service_role;

drop trigger if exists usage_quotas_set_updated_at on public.usage_quotas;
create trigger usage_quotas_set_updated_at
before update on public.usage_quotas
for each row execute function public.set_updated_at();

-- The quota window is the UTC day. Both the consume and the read path derive it
-- here so a client and the backend can never disagree about the boundary.
create or replace function public.current_usage_period_start()
returns timestamptz
language sql
stable
set search_path = ''
as $$
  select date_trunc('day', now() at time zone 'utc') at time zone 'utc';
$$;

revoke execute on function public.current_usage_period_start()
  from public, anon, authenticated;
grant execute on function public.current_usage_period_start() to service_role;

-- Atomically reserve one unit of quota. Returns allowed = false without
-- incrementing when the caller is already at the limit, so the counter can
-- never exceed limit_count no matter how many callers race.
create or replace function public.consume_ai_usage_quota(
  p_user_id uuid,
  p_feature text,
  p_limit integer
)
returns table (
  allowed boolean,
  used_count integer,
  limit_count integer,
  period_end timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_period_start timestamptz := public.current_usage_period_start();
  v_period_end timestamptz := v_period_start + interval '1 day';
  v_used integer;
  v_limit integer;
begin
  if p_user_id is null or p_feature is null or p_limit is null then
    raise exception 'invalid_quota_request';
  end if;

  -- A zero or negative limit is "feature unavailable"; never create a row that
  -- would sit above its own limit.
  if p_limit <= 0 then
    return query select false, 0, greatest(p_limit, 0), v_period_end;
    return;
  end if;

  insert into public.usage_quotas as quota (
    user_id,
    feature,
    period_start,
    period_end,
    used_count,
    limit_count
  )
  values (p_user_id, p_feature, v_period_start, v_period_end, 1, p_limit)
  on conflict (user_id, feature, period_start) do update
    set used_count = quota.used_count + 1,
        limit_count = excluded.limit_count,
        period_end = excluded.period_end
    where quota.used_count < excluded.limit_count
  returning quota.used_count, quota.limit_count
  into v_used, v_limit;

  if found then
    return query select true, v_used, v_limit, v_period_end;
    return;
  end if;

  -- The conflict target matched but the guard rejected the update: the caller
  -- is at or above the limit. Report the current state without changing it.
  select quota.used_count, quota.limit_count
  into v_used, v_limit
  from public.usage_quotas as quota
  where quota.user_id = p_user_id
    and quota.feature = p_feature
    and quota.period_start = v_period_start;

  return query select
    false,
    coalesce(v_used, 0),
    coalesce(v_limit, p_limit),
    v_period_end;
end;
$$;

revoke execute on function public.consume_ai_usage_quota(uuid, text, integer)
  from public, anon, authenticated;
grant execute on function public.consume_ai_usage_quota(uuid, text, integer)
  to service_role;

-- Return a unit reserved by consume_ai_usage_quota when the downstream call
-- never happened, so an upstream outage does not spend a user's daily quota.
create or replace function public.release_ai_usage_quota(
  p_user_id uuid,
  p_feature text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_period_start timestamptz := public.current_usage_period_start();
begin
  update public.usage_quotas as quota
  set used_count = quota.used_count - 1
  where quota.user_id = p_user_id
    and quota.feature = p_feature
    and quota.period_start = v_period_start
    and quota.used_count > 0;
end;
$$;

revoke execute on function public.release_ai_usage_quota(uuid, text)
  from public, anon, authenticated;
grant execute on function public.release_ai_usage_quota(uuid, text)
  to service_role;

-- Owner-scoped read so the app can show remaining quota. It observes RLS and
-- exposes counters only; it can never change them.
create or replace function public.get_my_usage_quota(p_feature text)
returns table (
  feature text,
  used_count integer,
  limit_count integer,
  period_end timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    p_feature as feature,
    coalesce(quota.used_count, 0) as used_count,
    coalesce(quota.limit_count, 0) as limit_count,
    coalesce(
      quota.period_end,
      date_trunc('day', now() at time zone 'utc') at time zone 'utc'
        + interval '1 day'
    ) as period_end
  from (select (select auth.uid()) as user_id) as caller
  left join public.usage_quotas as quota
    on quota.user_id = caller.user_id
   and quota.feature = p_feature
   and quota.period_start =
       date_trunc('day', now() at time zone 'utc') at time zone 'utc';
$$;

revoke execute on function public.get_my_usage_quota(text) from public, anon;
grant execute on function public.get_my_usage_quota(text) to authenticated;

commit;
