import 'offline_model_state.dart';

abstract class OfflineModelManager {
  Stream<OfflineModelState> watchState();

  Future<OfflineModelState> getState();

  Future<void> checkAvailability();

  Future<void> download();

  Future<void> cancelDownload();

  Future<void> initialize();

  Future<void> deleteModel();

  OfflineModelDownloadSettings getDownloadSettings();

  Future<void> setDownloadSettings(OfflineModelDownloadSettings settings);

  void dispose();
}
