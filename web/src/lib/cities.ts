/**
 * The city index shared by the prayer-times pages and the Qibla city picker.
 *
 * The list is generated into web/public/data/prayer-times/index.json; Vite resolves
 * it at build time through import.meta.glob, so nothing here depends on
 * process.cwd() (which changes with the runner that happens to start the build).
 */
export interface City {
  id: string;
  nameAr: string;
  nameEn: string;
}

const INDEX_FILES = import.meta.glob('../../public/data/prayer-times/index.json', {
  eager: true,
  query: '?raw',
  import: 'default',
}) as Record<string, string>;

function readIndexRaw(): string {
  const raw = Object.values(INDEX_FILES)[0];
  if (raw === undefined) throw new Error('prayer-times index.json not found');
  return raw;
}

const index = JSON.parse(readIndexRaw()) as { cities: City[] };

/** Every city with prayer times, in generator order. */
export function getCities(): City[] {
  return index.cities;
}
