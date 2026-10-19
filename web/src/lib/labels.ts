/** Collapses upstream "X - X" duplicates; conservative — only when both sides are byte-equal after trim. */
export function dedupeLabel(name: string): string {
  const m = /^(.*?)\s+-\s+(.*)$/.exec(name);
  if (!m) return name;
  const left = m[1].trim();
  const right = m[2].trim();
  return left !== '' && left === right ? left : name;
}
