import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/auth/data/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_data_providers.g.dart';

@riverpod
Future<AuthRepository> authRepository(AuthRepositoryRef ref) async {
  final sharedPreferences = await ref.watch(sharedPreferencesProvider.future);
  return AuthRepositoryImpl(
    sharedPreferences: sharedPreferences,
  );
}

@riverpod
Future<bool> isAuthenticated(IsAuthenticatedRef ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return repository.isAuthenticated();
}

@riverpod
Future<AuthRepository?> authenticatedRepository(
  AuthenticatedRepositoryRef ref,
) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  if (repository.isAuthenticated()) {
    return repository;
  }
  return null;
}


