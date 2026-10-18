const AR = '٠١٢٣٤٥٦٧٨٩';
export function toArabicDigits(n: number | string): string {
  return String(n).replace(/\d/g, (d) => AR[Number(d)]);
}
