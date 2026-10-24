// Pure great-circle initial bearing to the Kaaba (WW1 C3) — no dependencies.
export const KAABA = { lat: 21.4225, lng: 39.8262 } as const;

const toRad = (deg: number): number => (deg * Math.PI) / 180;
const toDeg = (rad: number): number => (rad * 180) / Math.PI;

/** Initial bearing in degrees clockwise from true north, in [0, 360). */
export function qiblaBearing(lat: number, lng: number): number {
  const phi1 = toRad(lat);
  const phi2 = toRad(KAABA.lat);
  const dLng = toRad(KAABA.lng - lng);
  const y = Math.sin(dLng) * Math.cos(phi2);
  const x = Math.cos(phi1) * Math.sin(phi2) - Math.sin(phi1) * Math.cos(phi2) * Math.cos(dLng);
  return (toDeg(Math.atan2(y, x)) + 360) % 360;
}
