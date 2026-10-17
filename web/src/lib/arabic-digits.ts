const AR = '٠١٢٣٤٥٦٧٨٩';
export function toArabicDigits(n: number): string {
  return String(n).replace(/\d/g, (d) => AR[Number(d)]);
}
