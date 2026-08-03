import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String functionSource;
  late String repositorySource;

  setUpAll(() async {
    functionSource = await File(
      'supabase/functions/delete-account/index.ts',
    ).readAsString();
    repositorySource = await File(
      'lib/app/auth/supabase_auth_repository.dart',
    ).readAsString();
  });

  test('delete-account function enforces POST and bearer authentication', () {
    expect(functionSource, contains('request.method === "OPTIONS"'));
    expect(functionSource, contains('Access-Control-Allow-Origin'));
    expect(functionSource, contains('Access-Control-Allow-Headers'));
    expect(functionSource, contains('request.method !== "POST"'));
    expect(functionSource, contains('Authorization'));
    expect(functionSource, contains('Bearer '));
    expect(functionSource, contains('adminClient.auth.getUser(accessToken)'));
    expect(functionSource, contains('admin.deleteUser'));
    expect(functionSource, contains('{ success: true }'));
  });

  test('privileged key stays in Edge Function environment only', () {
    const serviceRoleVariable =
        'SUPABASE'
        '_SERVICE_ROLE_KEY';
    expect(functionSource, contains('Deno.env.get("$serviceRoleVariable")'));
    expect(functionSource, isNot(contains('eyJ')));
    expect(repositorySource, isNot(contains('SERVICE_ROLE')));
    expect(repositorySource, contains("'delete-account'"));
    expect(repositorySource, contains('HttpMethod.post'));
  });

  test('function dependency is exactly pinned', () async {
    final denoConfig = await File(
      'supabase/functions/delete-account/deno.json',
    ).readAsString();
    expect(denoConfig, contains('@supabase/supabase-js@2.110.8'));
    expect(denoConfig, isNot(contains('@supabase/supabase-js@2"')));
  });
}
