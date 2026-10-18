import { useEffect, useMemo, useState } from 'react';
import { filterSurahs } from '../lib/surah-filter';
import { loadSearchIndex, matchSpan, searchAyahs, type Hit } from '../lib/search';
import { surahDisplayName } from '../lib/surah-name';
import { t, type Locale } from '../lib/strings';
import surahs from '../data/surahs.json';

function HitText({ text, query }: { text: string; query: string }) {
  const span = matchSpan(text, query);
  if (!span) return <>{text}</>;
  return (
    <>
      {text.slice(0, span.start)}
      <mark>{text.slice(span.start, span.end)}</mark>
      {text.slice(span.end)}
    </>
  );
}

export default function SurahIndexFilter({ locale = 'ar' as Locale }) {
  const [q, setQ] = useState('');
  const [ready, setReady] = useState(false);
  const [failed, setFailed] = useState(false);
  const [loading, setLoading] = useState(false);
  const [hits, setHits] = useState<Hit[]>([]);
  const results = useMemo(() => filterSurahs(surahs.surahs, q), [q]);
  const active = q.trim().length >= 2;
  const base = locale === 'en' ? '/en' : '';
  // Verse search is AR-only (EN chrome hides it and never loads the index) and is
  // pointless for digit-only queries, which the surah-number filter already answers.
  const showAyahSearch = active && locale !== 'en' && !/^[0-9٠-٩]+$/.test(q.trim());

  useEffect(() => {
    if (!showAyahSearch || ready || failed) return;
    let cancelled = false;
    setLoading(true);
    loadSearchIndex()
      .then(() => {
        if (cancelled) return;
        setReady(true);
        setLoading(false);
      })
      .catch(() => {
        if (cancelled) return;
        setLoading(false);
        setFailed(true);
      });
    return () => {
      cancelled = true;
    };
  }, [showAyahSearch, ready, failed]);

  useEffect(() => {
    if (ready) setHits(searchAyahs(q));
  }, [ready, q]);

  return (
    <div>
      <input
        type="search" value={q} onChange={(e) => setQ(e.target.value)}
        placeholder={t(locale, 'indexSearchPlaceholder')}
        aria-label={t(locale, 'indexSearchPlaceholder')}
        className="index-search"
      />
      {results.length === 0 && <p className="empty">{t(locale, 'noResults')}</p>}
      <ol className="surah-list">
        {results.map((s) => (
          <li key={s.id}>
            <a href={`${base}/surah/${s.id}/`}>
              <span className="surah-num">{s.id}</span>
              <span className="surah-name">{surahDisplayName(s, locale)}</span>
              <span className="surah-meta">{s.revelationType === 'makkah' ? t(locale, 'chipMeccan') : t(locale, 'chipMedinan')} · {s.ayahCount}</span>
            </a>
          </li>
        ))}
      </ol>
      {showAyahSearch && (
        <section className="ayah-search" aria-labelledby="ayah-search-title">
          <h2 id="ayah-search-title" className="ayah-search-title">{t(locale, 'searchAyahsTitle')}</h2>
          {loading && <p className="search-loading" role="status">{t(locale, 'searchLoading')}</p>}
          {failed && (
            <div className="panel-error">
              <span>{t(locale, 'panelError')}</span>
              <button type="button" className="rc-btn" onClick={() => setFailed(false)}>{t(locale, 'panelRetry')}</button>
            </div>
          )}
          {!loading && !failed && hits.length === 0 && <p className="empty">{t(locale, 'noResults')}</p>}
          <ol className="ayah-hits">
            {hits.map((h) => (
              <li key={`${h.s}:${h.a}`}>
                <a href={`${base}/surah/${h.s}/#ayah-${h.a}`}>
                  <HitText text={h.text} query={q} />
                </a>
              </li>
            ))}
          </ol>
        </section>
      )}
    </div>
  );
}
