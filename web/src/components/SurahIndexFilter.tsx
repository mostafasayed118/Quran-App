import { useMemo, useState } from 'react';
import { filterSurahs } from '../lib/surah-filter';
import { t, type Locale } from '../lib/strings';
import surahs from '../data/surahs.json';

export default function SurahIndexFilter({ locale = 'ar' as Locale }) {
  const [q, setQ] = useState('');
  const results = useMemo(() => filterSurahs(surahs.surahs, q), [q]);
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
            <a href={`/surah/${s.id}`}>
              <span className="surah-num">{s.id}</span>
              <span className="surah-name">{s.nameAr}</span>
              <span className="surah-meta">{s.revelationType === 'makkah' ? t(locale, 'chipMeccan') : t(locale, 'chipMedinan')} · {s.ayahCount}</span>
            </a>
          </li>
        ))}
      </ol>
    </div>
  );
}
