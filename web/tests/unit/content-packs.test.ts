import { describe, it, expect, vi, afterEach } from 'vitest';
import { PACKS, fetchPackAyahs, type PackInfo } from '../../src/lib/content-packs';
import tafsirFixture from '../fixtures/tafsir-1.json';
import translationFixture from '../fixtures/translation-1.json';

function pack(id: string): PackInfo {
  const found = PACKS.find((p) => p.id === id);
  if (!found) throw new Error(`missing pack ${id}`);
  return found;
}

const okJson = (body: unknown) =>
  new Response(JSON.stringify(body), { status: 200, headers: { 'content-type': 'application/json' } });

afterEach(() => {
  vi.unstubAllGlobals();
});

describe('PACKS catalog', () => {
  it('ships exactly the five curated packs in order', () => {
    expect(PACKS.map((p) => `${p.kind}:${p.id}`)).toEqual([
      'tafsir:ar-tafsir-muyassar',
      'tafsir:ar-tafsir-al-jalalayn',
      'translation:ara-sirajtafseer',
      'translation:eng-safiurrahmanalm',
      'translation:eng-mustafakhattabg',
    ]);
  });

  it('carries the Arabic display titles', () => {
    expect(pack('ar-tafsir-muyassar').titleAr).toBe('التفسير الميسر');
    expect(pack('ar-tafsir-al-jalalayn').titleAr).toBe('تفسير الجلالين');
    expect(pack('eng-safiurrahmanalm').titleAr).toBe('صحيح إنترناشيونال');
  });

  it('builds spa5k tafsir URLs verbatim', () => {
    expect(pack('ar-tafsir-muyassar').url(1)).toBe(
      'https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@v1.2.2/tafsir/ar-tafsir-muyassar/1.json',
    );
    expect(pack('ar-tafsir-al-jalalayn').url(114)).toBe(
      'https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@v1.2.2/tafsir/ar-tafsir-al-jalalayn/114.json',
    );
  });

  it('builds fawazahmed0 translation URLs verbatim', () => {
    expect(pack('ara-sirajtafseer').url(2)).toBe(
      'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@47ca096b0976443ba2eab2e45cdf0fb4096a2610/editions/ara-sirajtafseer/2.json',
    );
    expect(pack('eng-mustafakhattabg').url(108)).toBe(
      'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@47ca096b0976443ba2eab2e45cdf0fb4096a2610/editions/eng-mustafakhattabg/108.json',
    );
  });

  it('never floats on a mutable ref - every pack base is tag- or commit-pinned', () => {
    for (const p of PACKS) expect(p.url(1)).toMatch(/@(v\d+\.\d+\.\d+|[0-9a-f]{40})\//);
  });
});

describe('pack parsers', () => {
  it('maps the spa5k array shape to ayah-indexed text', () => {
    const map = pack('ar-tafsir-muyassar').parse(tafsirFixture);
    expect(map.size).toBe(7);
    expect(map.get(1)).toBe(tafsirFixture[0].text);
    expect(map.get(7)).toBe(tafsirFixture[6].text);
  });

  it('maps the fawazahmed0 chapter shape to verse-indexed text', () => {
    const map = pack('eng-safiurrahmanalm').parse(translationFixture);
    expect(map.size).toBe(7);
    expect(map.get(1)).toBe(translationFixture.chapter[0].text);
    expect(map.get(7)).toBe(translationFixture.chapter[6].text);
  });

  it('throws on invalid tafsir payloads', () => {
    const parse = pack('ar-tafsir-muyassar').parse;
    expect(() => parse(null)).toThrow();
    expect(() => parse({})).toThrow();
    expect(() => parse('nope')).toThrow();
    expect(() => parse([{ nope: 1 }])).toThrow();
    expect(() => parse([])).toThrow();
  });

  it('throws on invalid translation payloads', () => {
    const parse = pack('eng-safiurrahmanalm').parse;
    expect(() => parse(null)).toThrow();
    expect(() => parse({})).toThrow();
    expect(() => parse({ chapter: 'nope' })).toThrow();
    expect(() => parse({ chapter: [{ verse: 'x', text: 'y' }] })).toThrow();
    expect(() => parse({ chapter: [] })).toThrow();
  });
});

describe('fetchPackAyahs', () => {
  it('fetches the pack URL and returns the parsed map', async () => {
    const fetchMock = vi.fn(async (_url: string) => okJson(tafsirFixture));
    vi.stubGlobal('fetch', fetchMock);
    const map = await fetchPackAyahs(pack('ar-tafsir-muyassar'), 1);
    expect(map.get(1)).toBe(tafsirFixture[0].text);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(fetchMock.mock.calls[0][0]).toBe(pack('ar-tafsir-muyassar').url(1));
  });

  it('serves a repeated call from the in-memory cache', async () => {
    const fetchMock = vi.fn(async () => okJson(tafsirFixture));
    vi.stubGlobal('fetch', fetchMock);
    await fetchPackAyahs(pack('ar-tafsir-muyassar'), 2);
    await fetchPackAyahs(pack('ar-tafsir-muyassar'), 2);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('throws on an HTTP error and re-fetches on retry (errors are not cached)', async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(new Response('boom', { status: 500 }))
      .mockResolvedValueOnce(okJson(translationFixture));
    vi.stubGlobal('fetch', fetchMock);
    await expect(fetchPackAyahs(pack('eng-safiurrahmanalm'), 3)).rejects.toThrow('HTTP 500');
    const map = await fetchPackAyahs(pack('eng-safiurrahmanalm'), 3);
    expect(map.size).toBe(7);
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it('throws when the payload does not match the pack shape', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => okJson({ nope: true })));
    await expect(fetchPackAyahs(pack('ar-tafsir-al-jalalayn'), 4)).rejects.toThrow();
  });
});
