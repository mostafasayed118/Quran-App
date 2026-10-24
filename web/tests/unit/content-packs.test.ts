import { describe, it, expect, vi, afterEach } from 'vitest';
import { PACKS, fetchPackAyahs, type PackInfo } from '../../src/lib/content-packs';
import translationFixture from '../fixtures/translation-1.json';

function pack(id: string): PackInfo {
  const found = PACKS.find((p) => p.id === id);
  if (!found) throw new Error(`missing pack ${id}`);
  return found;
}

const okJson = (body: unknown) =>
  new Response(JSON.stringify(body), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  });

afterEach(() => {
  vi.unstubAllGlobals();
});

describe('PACKS catalog', () => {
  it('ships exactly the two licensed packs in order', () => {
    expect(PACKS.map((p) => `${p.kind}:${p.id}`)).toEqual([
      'translation:ara-sirajtafseer',
      'translation:eng-mohammedmarmadu',
    ]);
  });

  it('carries the Arabic display titles and the required attribution', () => {
    expect(pack('ara-sirajtafseer').titleAr).toBe('المختصر في التفسير - سِراج');
    expect(pack('ara-sirajtafseer').attribution).toBe(
      'QuranEnc.com · version 47ca096b0976443ba2eab2e45cdf0fb4096a2610',
    );
    expect(pack('eng-mohammedmarmadu').titleAr).toBe('ترجمة بيكثال الإنجليزية');
    expect(pack('eng-mohammedmarmadu').attribution).toBe(
      'fawazahmed0/quran-api · public domain · 47ca096b0976443ba2eab2e45cdf0fb4096a2610',
    );
  });

  it('builds fawazahmed0 per-surah URLs verbatim at the pinned commit', () => {
    expect(pack('ara-sirajtafseer').url(2)).toBe(
      'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@47ca096b0976443ba2eab2e45cdf0fb4096a2610/editions/ara-sirajtafseer/2.json',
    );
    expect(pack('eng-mohammedmarmadu').url(108)).toBe(
      'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@47ca096b0976443ba2eab2e45cdf0fb4096a2610/editions/eng-mohammedmarmadu/108.json',
    );
  });

  it('never floats on a mutable ref - every pack base is tag- or commit-pinned', () => {
    for (const p of PACKS) expect(p.url(1)).toMatch(/@(v\d+\.\d+\.\d+|[0-9a-f]{40})\//);
  });
});

describe('pack parsers', () => {
  it('maps the fawazahmed0 chapter shape to verse-indexed text', () => {
    const map = pack('eng-mohammedmarmadu').parse(translationFixture);
    expect(map.size).toBe(7);
    expect(map.get(1)).toBe(translationFixture.chapter[0].text);
    expect(map.get(7)).toBe(translationFixture.chapter[6].text);
  });

  it('throws on invalid translation payloads', () => {
    const parse = pack('eng-mohammedmarmadu').parse;
    expect(() => parse(null)).toThrow();
    expect(() => parse({})).toThrow();
    expect(() => parse({ chapter: 'nope' })).toThrow();
    expect(() => parse({ chapter: [{ verse: 'x', text: 'y' }] })).toThrow();
    expect(() => parse({ chapter: [] })).toThrow();
  });
});

describe('fetchPackAyahs', () => {
  it('fetches the pack URL and returns the parsed map', async () => {
    const fetchMock = vi.fn(async (_url: string) => okJson(translationFixture));
    vi.stubGlobal('fetch', fetchMock);
    const map = await fetchPackAyahs(pack('ara-sirajtafseer'), 1);
    expect(map.get(1)).toBe(translationFixture.chapter[0].text);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(fetchMock.mock.calls[0][0]).toBe(pack('ara-sirajtafseer').url(1));
  });

  it('serves a repeated call from the in-memory cache', async () => {
    const fetchMock = vi.fn(async () => okJson(translationFixture));
    vi.stubGlobal('fetch', fetchMock);
    await fetchPackAyahs(pack('ara-sirajtafseer'), 2);
    await fetchPackAyahs(pack('ara-sirajtafseer'), 2);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('throws on an HTTP error and re-fetches on retry (errors are not cached)', async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(new Response('boom', { status: 500 }))
      .mockResolvedValueOnce(okJson(translationFixture));
    vi.stubGlobal('fetch', fetchMock);
    await expect(fetchPackAyahs(pack('eng-mohammedmarmadu'), 3)).rejects.toThrow('HTTP 500');
    const map = await fetchPackAyahs(pack('eng-mohammedmarmadu'), 3);
    expect(map.size).toBe(7);
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it('throws when the payload does not match the pack shape', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async () => okJson({ nope: true })),
    );
    await expect(fetchPackAyahs(pack('eng-mohammedmarmadu'), 4)).rejects.toThrow();
  });
});
