const AR = '٠١٢٣٤٥٦٧٨٩';
export function toArabicDigits(n: number | string): string {
  return String(n).replace(/\d/g, (d) => AR[Number(d)]);
}
export function toAsciiDigits(s: string): string {
  return s.replace(/[٠-٩]/g, (d) => String(AR.indexOf(d)));
}
