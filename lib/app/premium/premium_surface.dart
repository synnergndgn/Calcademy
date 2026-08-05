import 'package:calcademy/app/auth/auth_repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether this build ships the account-and-Premium product surface at all.
///
/// Calcademy ships two products from one codebase. The ad-supported release is
/// compiled **without** Supabase config, and in that build accounts,
/// subscriptions, the assistant, and the camera solver do not exist — not as
/// locked teasers, not as "coming soon" pages, not as settings rows. A user of
/// the free product should never encounter a door they cannot open.
///
/// Supplying the Supabase `--dart-define` values turns the whole surface on, so
/// no separate branch or build flavor is needed.
///
/// This is a presentation gate, not a security boundary. Entitlement is still
/// decided by the backend, and every remote path fails closed on its own.
final premiumSurfaceEnabledProvider = Provider<bool>(
  (ref) => ref.watch(isAuthConfiguredProvider),
);
