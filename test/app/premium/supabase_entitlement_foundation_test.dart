import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260804111930_entitlement_backend_foundation.sql';

  test('entitlement migration defines all tables with RLS', () async {
    final sql = await File(migrationPath).readAsString();
    for (final table in [
      'profiles',
      'premium_entitlements',
      'subscription_purchases',
      'purchase_validation_events',
      'usage_quotas',
    ]) {
      expect(sql, contains('create table if not exists public.$table'));
      expect(
        sql,
        contains('alter table public.$table enable row level security'),
      );
    }
    expect(sql, contains('premium_entitlements_status_check'));
    expect(sql, contains('premium_entitlements_source_check'));
    expect(sql, contains("'active'"));
    expect(sql, contains("'grace_period'"));
    expect(sql, contains("'pending_validation'"));
  });

  test('purchase token storage is hash-only', () async {
    final sql = await File(migrationPath).readAsString();
    expect(sql, contains('purchase_token_hash text'));
    expect(sql, isNot(matches(RegExp(r'\bpurchase_token\s+text\b'))));
  });

  test('client writes are not granted on backend-owned tables', () async {
    final sql = await File(migrationPath).readAsString();
    for (final table in [
      'premium_entitlements',
      'subscription_purchases',
      'purchase_validation_events',
      'usage_quotas',
    ]) {
      expect(
        sql,
        isNot(contains('grant insert on table public.$table to authenticated')),
      );
      expect(
        sql,
        isNot(contains('grant update on table public.$table to authenticated')),
      );
      expect(
        sql,
        isNot(contains('grant delete on table public.$table to authenticated')),
      );
    }
    expect(sql, isNot(contains('purchase_validation_events_select_own')));
    expect(sql, contains('grant update (email) on table public.profiles'));
    expect(sql, isNot(contains('grant all on table')));
    expect(sql, contains('security invoker'));
    expect(sql, contains("set search_path = ''"));
  });

  test('Edge Function contract and token safety are covered', () async {
    final index = await File(
      'supabase/functions/validate-play-purchase/index.ts',
    ).readAsString();
    final handler = await File(
      'supabase/functions/validate-play-purchase/handler.ts',
    ).readAsString();
    final functionTests = await File(
      'supabase/functions/validate-play-purchase/index_test.ts',
    ).readAsString();
    final config = await File('supabase/config.toml').readAsString();

    expect(
      index,
      contains(
        'SUPABASE'
        '_SERVICE_ROLE_KEY',
      ),
    );
    expect(index, contains('auth.getUser'));
    expect(handler, contains('crypto.subtle.digest("SHA-256"'));
    expect(handler, contains('request.method === "OPTIONS"'));
    expect(handler, contains('request.method !== "POST"'));
    expect(handler, contains('authentication_required'));
    expect(handler, contains('invalid_body'));
    expect(handler, contains('status: "unsupported"'));
    expect('$index\n$handler', isNot(contains('console.log')));
    expect('$index\n$handler', isNot(contains('private_key')));
    expect(functionTests, contains('valid request returns unsupported'));
    expect(functionTests, contains('body.includes(secretToken)'));
    expect(config, contains('verify_jwt = true'));
  });
}
