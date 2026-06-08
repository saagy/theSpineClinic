import 'package:spine_clinic_app/core/utils/file_cache_manager.dart';

/// Mobile/desktop implementation caching files locally.
Future<void> downloadFileImpl(String url, String filename) async {
  await FileCacheManager.instance.getFile(url, filename);
}
