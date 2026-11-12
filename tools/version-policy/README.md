# Version-policy signing

This directory holds the **public** signing material and the signed policy
template. The private seed lives outside the repository (for example
`%USERPROFILE%\quranyahdi-keys\version-policy.seed`) and must never be
committed, pasted into chat, or copied into `web/`.

## Files

- `version-policy-public.txt` — raw Ed25519 public key, base64 (safe to commit).
- `version-policy/version.json` — signed policy template; **not deployed**.
- `../build_release.ps1` — release wrapper that refuses to build without the
  public key.
- `../version_policy_key.dart` — generate/sign/verify tool.

## Signing a policy

Update `min_supported`, `latest` and `expires_at` first, then:

```powershell
dart run tools/version_policy_key.dart sign `
  "tools\version-policy\version.json" `
  "$env:USERPROFILE\quranyahdi-keys\version-policy.seed"
```

Verify with the public key:

```powershell
$pub = (Get-Content tools\version-policy-public.txt -Raw).Trim()
dart run tools/version_policy_key.dart verify `
  "tools\version-policy\version.json" $pub
```

Publish only after the key-bearing build is live. Copy the signed file to
`web/public/version.json` (or the Cloudflare Pages root) as a deliberate
release step; the app fetches `https://quranyahdi.pages.dev/version.json`.

See `docs/version-policy-signing.md` for the full runbook, including Play App
Signing and rollback.
