import 'dart:async';

import 'package:calcademy/app/auth/auth_repository.dart';
import 'package:calcademy/app/auth/local_auth_repository.dart';
import 'package:calcademy/app/auth/supabase_auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) => null);

final isAuthConfiguredProvider = Provider<bool>(
  (ref) => ref.watch(supabaseClientProvider) != null,
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) return SupabaseAuthRepository(client);
  final repository = LocalAuthRepository();
  ref.onDispose(() => unawaited(repository.dispose()));
  return repository;
});
