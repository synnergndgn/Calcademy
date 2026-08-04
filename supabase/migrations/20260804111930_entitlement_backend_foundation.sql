begin;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists email text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

create table if not exists public.premium_entitlements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  status text not null,
  source text not null,
  plan_id text,
  product_id text,
  base_plan_id text,
  current_period_start timestamptz,
  current_period_end timestamptz,
  cancel_at_period_end boolean not null default false,
  last_validated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint premium_entitlements_status_check check (
    status in (
      'inactive',
      'active',
      'grace_period',
      'expired',
      'canceled',
      'revoked',
      'pending_validation'
    )
  ),
  constraint premium_entitlements_source_check check (
    source in ('google_play', 'manual', 'test', 'unknown')
  )
);

create table if not exists public.subscription_purchases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null default 'google_play',
  product_id text not null,
  base_plan_id text,
  purchase_token_hash text not null,
  purchase_token_last4 text,
  order_id text,
  status text not null,
  acknowledged boolean not null default false,
  auto_renewing boolean,
  purchased_at timestamptz,
  expires_at timestamptz,
  last_validated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint subscription_purchases_platform_check check (
    platform in ('google_play')
  ),
  constraint subscription_purchases_status_check check (
    status in (
      'pending_validation',
      'active',
      'expired',
      'canceled',
      'refunded',
      'revoked',
      'validation_failed'
    )
  )
);

create table if not exists public.purchase_validation_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  platform text not null,
  product_id text,
  purchase_token_hash text,
  event_type text not null,
  message text,
  created_at timestamptz not null default now(),
  constraint purchase_validation_events_platform_check check (
    platform in ('google_play')
  ),
  constraint purchase_validation_events_type_check check (
    event_type in (
      'received',
      'validation_started',
      'validation_succeeded',
      'validation_failed',
      'entitlement_updated',
      'acknowledged',
      'rejected'
    )
  )
);

create table if not exists public.usage_quotas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  feature text not null,
  period_start timestamptz not null,
  period_end timestamptz not null,
  used_count integer not null default 0,
  limit_count integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint usage_quotas_period_check check (period_end > period_start),
  constraint usage_quotas_counts_check check (
    used_count >= 0 and limit_count >= 0
  ),
  constraint usage_quotas_user_feature_period_key unique (
    user_id,
    feature,
    period_start
  )
);

create index if not exists subscription_purchases_user_id_idx
  on public.subscription_purchases (user_id);
create unique index if not exists subscription_purchases_token_hash_idx
  on public.subscription_purchases (purchase_token_hash);
create index if not exists purchase_validation_events_user_id_idx
  on public.purchase_validation_events (user_id);
create index if not exists usage_quotas_user_id_idx
  on public.usage_quotas (user_id);

alter table public.profiles enable row level security;
alter table public.premium_entitlements enable row level security;
alter table public.subscription_purchases enable row level security;
alter table public.purchase_validation_events enable row level security;
alter table public.usage_quotas enable row level security;

revoke all on table public.profiles from anon, authenticated;
revoke all on table public.premium_entitlements from anon, authenticated;
revoke all on table public.subscription_purchases from anon, authenticated;
revoke all on table public.purchase_validation_events from anon, authenticated;
revoke all on table public.usage_quotas from anon, authenticated;

grant select on table public.profiles to authenticated;
grant update (email) on table public.profiles to authenticated;
grant select on table public.premium_entitlements to authenticated;
grant select on table public.subscription_purchases to authenticated;
grant select on table public.usage_quotas to authenticated;

grant select, insert, update, delete on table public.profiles to service_role;
grant select, insert, update, delete on table public.premium_entitlements
  to service_role;
grant select, insert, update, delete on table public.subscription_purchases
  to service_role;
grant select, insert, update, delete on table public.purchase_validation_events
  to service_role;
grant select, insert, update, delete on table public.usage_quotas to service_role;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles
  for select
  to authenticated
  using ((select auth.uid()) = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles
  for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

drop policy if exists "premium_entitlements_select_own"
  on public.premium_entitlements;
create policy "premium_entitlements_select_own"
  on public.premium_entitlements
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "subscription_purchases_select_own"
  on public.subscription_purchases;
create policy "subscription_purchases_select_own"
  on public.subscription_purchases
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "usage_quotas_select_own" on public.usage_quotas;
create policy "usage_quotas_select_own"
  on public.usage_quotas
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke execute on function public.set_updated_at() from public, anon, authenticated;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists premium_entitlements_set_updated_at
  on public.premium_entitlements;
create trigger premium_entitlements_set_updated_at
before update on public.premium_entitlements
for each row execute function public.set_updated_at();

drop trigger if exists subscription_purchases_set_updated_at
  on public.subscription_purchases;
create trigger subscription_purchases_set_updated_at
before update on public.subscription_purchases
for each row execute function public.set_updated_at();

drop trigger if exists usage_quotas_set_updated_at on public.usage_quotas;
create trigger usage_quotas_set_updated_at
before update on public.usage_quotas
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do update
    set email = excluded.email,
        updated_at = now();
  return new;
end;
$$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.get_my_premium_status()
returns table (
  is_premium_active boolean,
  status text,
  source text,
  product_id text,
  current_period_end timestamptz,
  cancel_at_period_end boolean
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    coalesce(
      entitlement.status in ('active', 'grace_period')
      and (
        entitlement.current_period_end is null
        or entitlement.current_period_end > now()
      ),
      false
    ) as is_premium_active,
    coalesce(entitlement.status, 'inactive') as status,
    coalesce(entitlement.source, 'unknown') as source,
    entitlement.product_id,
    entitlement.current_period_end,
    coalesce(entitlement.cancel_at_period_end, false) as cancel_at_period_end
  from (select (select auth.uid()) as user_id) as caller
  left join public.premium_entitlements as entitlement
    on entitlement.user_id = caller.user_id;
$$;

revoke execute on function public.get_my_premium_status() from public, anon;
grant execute on function public.get_my_premium_status() to authenticated;

commit;
