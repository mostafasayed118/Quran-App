import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/download_status.dart';

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

    /// True when the last failure was a full disk; the screen shows the
    /// localized "not enough space" strip until the user dismisses it or a
    /// later download succeeds.
    @Default(false) bool outOfSpace,
  }) = _DownloadsState;
}
