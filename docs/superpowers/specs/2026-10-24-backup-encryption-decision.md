# Decision — backup-file encryption (2026-10-24)

Status: **accepted for v1.0** (plaintext + explicit warning) · encryption designed for a
v1.1 opt-in · owner: Mustafa Sayed · author: pairing session.

## Context

The backup is a **manual, user-initiated export**: the user taps «تصدير البيانات», the app
writes a JSON file to a temp path and hands it to the system share sheet
(`lib/features/backup/presentation/backup_cubit.dart:53-69`). The payload is
bookmarks, last-read position, khatma progress, the prayer log, tasbih state and the
whitelisted settings (the selected-city value is redacted on both export and import).

`lib/features/backup/data/backup_codec.dart:167` encodes the document with `jsonEncode`
— the file is **plaintext JSON**.

The live database is a plaintext SQLite file inside the Android app sandbox; Android
file-based encryption protects it at rest, and `allowBackup="false"` plus the
data-extraction rules keep it out of OS backup/transfer
(`android/app/src/main/AndroidManifest.xml:14-15`). The exported file is the only copy
that leaves that boundary.

The 2026-10-22 audit recorded this as a P2 finding and allowed either an encrypted
envelope or an explicit “unencrypted file” warning.

## Options considered

| Option | Verdict |
|---|---|
| A. Mandatory passphrase on every export | Rejected for v1.0: the backup exists for disaster recovery, and a forgotten passphrase turns a recoverable situation into permanent loss. It also adds a dependency, two passphrase flows (export + import) and recovery-support burden before the first store release. |
| B. Optional passphrase, default off | Rejected for v1.0: it adds the same surface and dependency while most users would leave it off, so the real-world benefit is small. Worth revisiting if the threat model changes. |
| C. Plaintext + explicit in-app warning + policy disclosure | **Chosen for v1.0.** Proportional to the data (bookmarks / worship log, no credentials or identifiers), keeps the file portable and recoverable, and satisfies the audit’s accepted mitigation. Implemented as a visible warning directly under the export row. |
| D. Device-generated key held in the keystore | Rejected: the file would only be restorable on the same device, which defeats the purpose of a backup. |

## Decision (v1.0)

1. The exported file stays **plaintext JSON** and portable.
2. The backup section shows a permanent, localized warning next to the export action:
   the file is not encrypted and should be stored somewhere safe
   (`lib/features/backup/presentation/backup_section.dart`).
3. The privacy policy discloses that the exported file is unencrypted
   (`PRIVACY.md:34`, `PRIVACY.en.md:34`).
4. The audit finding is closed as **risk-mitigated for v1.0**, not as “encryption done”.

## v1.1 design (only if a concrete need appears)

Trigger conditions: a store/legal requirement, a user report of an exposed file, or a
change that makes the payload more sensitive (accounts, health data, precise location).

- Dependency: `cryptography` (AES-GCM + Argon2id/PBKDF2); adding it requires the
  project’s usual explicit owner grant.
- Cipher: **AES-256-GCM**, a fresh random 96-bit nonce per file, header as AAD.
- KDF: **Argon2id** `m=19 MiB, t=2, p=1` (OWASP minimum configuration); fall back to
  **PBKDF2-HMAC-SHA256 with 600,000 iterations** only if Argon2id is unavailable on a
  target platform.
- Envelope: magic `QYBAK`, version byte, KDF id + params, 16-byte salt, 12-byte nonce,
  ciphertext + tag. Import sniffs the magic; plaintext files keep importing unchanged.
- Key handling: a generated 128-bit recovery key shown **once** at export and required
  at import; never stored, never recoverable. The export flow must force an explicit
  “I saved the key” confirmation before sharing.
- Failure semantics: a wrong key or a tampered/truncated file is a localized failure and
  never a partial import (the existing transactional apply stays the last line).
- Tests: fixed known-answer vectors, round-trip, wrong key, tampered ciphertext,
  truncated header, oversized ciphertext.

## References

- OWASP Cryptographic Storage Cheat Sheet — AES-GCM, unique IV, key management.
- OWASP Password Storage Cheat Sheet — PBKDF2-HMAC-SHA256 600k, Argon2id minimum
  configurations (`m=19 MiB, t=2, p=1`).
- `cryptography` 2.9.x — cross-platform AES-GCM, PBKDF2, Argon2id.
- Signal’s encrypted-backup model (passphrase/recovery-key with explicit no-recovery
  warning) was used as the UX reference.
