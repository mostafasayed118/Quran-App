import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';

FileSystemException _writeError({
  int code = 28,
  String message = 'No space left on device',
}) =>
    FileSystemException(
      'Failed to write file',
      '/tmp/001.mp3.part',
      OSError(message, code),
    );

void main() {
  test('ENOSPC and the Windows disk-full code are recognised', () {
    expect(isOutOfSpaceError(_writeError()), isTrue);
    expect(
      isOutOfSpaceError(_writeError(
        code: 112,
        message: 'There is not enough space on the disk.',
      )),
      isTrue,
    );
  });

  test('other write failures stay ordinary failures', () {
    expect(
        isOutOfSpaceError(_writeError(code: 13, message: 'Permission denied')),
        isFalse);
    expect(isOutOfSpaceError(StateError('not a file error')), isFalse);
  });

  test('a DioException wrapping the write error is recognised', () {
    expect(
      isOutOfSpaceError(DioException(
        requestOptions: RequestOptions(path: '/001.mp3'),
        error: _writeError(),
      )),
      isTrue,
    );
  });

  test('the out-of-space failure is flagged and never auto-retried', () {
    final failure = DownloadFailure.outOfSpace();

    expect(failure.outOfSpace, isTrue);
    expect(failure.retryable, isFalse);
    expect(DownloadFailure('network').outOfSpace, isFalse);
  });
}
