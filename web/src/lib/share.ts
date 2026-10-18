export type ShareOutcome = 'shared' | 'copied';

export interface ShareEnv {
  share?: (data: { text: string; url: string }) => Promise<void>;
  writeText: (text: string) => Promise<void>;
}

function browserEnv(): ShareEnv {
  const nav = navigator as Navigator & { share?: (data: { text: string; url: string }) => Promise<void> };
  return {
    share: typeof nav.share === 'function' ? nav.share.bind(nav) : undefined,
    writeText: (text) => navigator.clipboard.writeText(text),
  };
}

export async function shareOrCopy(
  url: string,
  text: string,
  env: ShareEnv = browserEnv(),
): Promise<ShareOutcome> {
  if (typeof env.share === 'function') {
    try {
      await env.share({ text, url });
      return 'shared';
    } catch {
      /* cancelled or blocked (no transient activation) — fall through to the clipboard */
    }
  }
  await env.writeText(`${text}\n${url}`);
  return 'copied';
}
