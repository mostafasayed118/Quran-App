import 'package:freezed_annotation/freezed_annotation.dart';

part 'downloads_state.freezed.dart';

@freezed
sealed class DownloadItem with _$DownloadItem {
  const factory DownloadItem({
    @Default('queued') String status,
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
