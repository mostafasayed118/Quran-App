import { describe, it, expect, afterEach, vi } from 'vitest';
import { shareOrCopy } from '../../src/lib/share';

const URL_ = 'https://quranyahdi.pages.dev/surah/1#ayah-1';
const TEXT = 'بسم الله الرحمن الرحيم';

describe('shareOrCopy', () => {
  it('resolves "shared" when navigator.share succeeds (text + url payload)', async () => {
    const share = vi.fn().mockResolvedValue(undefined);
    const writeText = vi.fn().mockResolvedValue(undefined);
    const result = await shareOrCopy(URL_, TEXT, { share, writeText });
    expect(result).toBe('shared');
    expect(share).toHaveBeenCalledTimes(1);
    expect(share).toHaveBeenCalledWith({ text: TEXT, url: URL_ });
    expect(writeText).not.toHaveBeenCalled();
  });

  it('falls back to the clipboard when navigator.share is unavailable', async () => {
    const writeText = vi.fn().mockResolvedValue(undefined);
    const result = await shareOrCopy(URL_, TEXT, { share: undefined, writeText });
    expect(result).toBe('copied');
    expect(writeText).toHaveBeenCalledTimes(1);
    expect(writeText).toHaveBeenCalledWith(`${TEXT}\n${URL_}`);
  });

  it('falls back to the clipboard when share rejects (cancelled / no activation)', async () => {
    const share = vi.fn().mockRejectedValue(new Error('AbortError'));
    const writeText = vi.fn().mockResolvedValue(undefined);
    const result = await shareOrCopy(URL_, TEXT, { share, writeText });
    expect(result).toBe('copied');
    expect(writeText).toHaveBeenCalledTimes(1);
    expect(writeText).toHaveBeenCalledWith(`${TEXT}\n${URL_}`);
  });

  it('propagates clipboard failures instead of pretending success', async () => {
    const writeText = vi.fn().mockRejectedValue(new Error('clipboard denied'));
    await expect(shareOrCopy(URL_, TEXT, { share: undefined, writeText })).rejects.toThrow(
      'clipboard denied',
    );
  });

  it('defaults to the browser navigator: stubbed clipboard is used when share is absent', async () => {
    const writeText = vi.fn().mockResolvedValue(undefined);
    vi.stubGlobal('navigator', { clipboard: { writeText } });
    const result = await shareOrCopy(URL_, TEXT);
    expect(result).toBe('copied');
    expect(writeText).toHaveBeenCalledWith(`${TEXT}\n${URL_}`);
  });
});

afterEach(() => {
  vi.unstubAllGlobals();
});
