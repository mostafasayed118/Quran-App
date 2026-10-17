import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/download_status.dart';

part 'downloads_state.freezed.dart';

@freezed
sealed class DownloadItem with _$DownloadItem {
  const factory DownloadItem({
    @Default(DownloadStatus.queued) DownloadStatus status,
    @Default(0) int received,
    @Default(0) int total,
  }) = _DownloadItem;
}

@freezed
sealed class DownloadsState with _$DownloadsState {
  const factory DownloadsState({
    @Default(<String, DownloadItem>{}) Map<String, DownloadItem> items,
  }) = _DownloadsState;
}
