import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/package/data/package_repository.dart';
import 'package:hiddify/features/package/model/package_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'package_data_providers.g.dart';

@riverpod
Future<PackageRepository> packageRepository(PackageRepositoryRef ref) async {
  final sharedPreferences = await ref.watch(sharedPreferencesProvider.future);
  return PackageRepositoryImpl(
    sharedPreferences: sharedPreferences,
  );
}

@riverpod
Future<List<Package>> packages(PackagesRef ref) async {
  final repository = await ref.watch(packageRepositoryProvider.future);
  final result = await repository.getPackages().run();
  return result.fold(
    (failure) => throw failure.message,
    (packages) => packages,
  );
}
