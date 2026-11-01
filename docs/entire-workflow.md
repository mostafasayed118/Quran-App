# Entire — checkpoints, trails and the review agents

> Runbook for any session (human or agent) working in this repository with Entire.
> Verified 2026-11-01 against CLI 0.12.2 on Windows 11. Anything here that is
> machine-specific is marked **local-only**.

## 1. What is set up

| Piece | Where | Tracked? |
|---|---|---|
| Enable + checkpoint backend (`git-refs`) | `.entire/settings.json` | **yes** |
| Private checkpoint remote + external agents | `.entire/settings.local.json` | no (`tmp/`, `settings.local.json`, `metadata/`, `logs/`, `redactors/local/` are ignored by `.entire/.gitignore`) |
| OpenCode 2 bridge (spawns `entire.exe` per hook) | `.opencode/plugins/entire-external.ts` | no — generated per device |
| Adapter the bridge calls | `~/.local/share/entire-agent-opencode2/agent.cjs` + `~/.local/bin/entire-agent-opencode2.cmd` | **local-only** |
| Checkpoint archive | private repo `mostafasayed118/quran-app-checkpoints` | separate |
| Project on entire.com | `gh/mostafasayed118` (mirror of origin) | — |
| Review agents | Code review · Security review · Slop — they run per push to a trail branch | — |

`entire status` is the single source of truth for whether any of this is live.

## 2. Start gate — run before touching anything

```powershell
entire status                 # Enabled · branch X · "Checkpoints sync to: dedicated checkpoint remote (…)"
entire agent list             # expect ✓ opencode2
git remote -v                 # expect origin (GitHub) and entire (entire://…)
Get-Content .entire/settings.local.json
```

Expected `settings.local.json`:

```json
{
  "enabled": true,
  "external_agents": true,
  "strategy_options": {
    "checkpoint_remote": {
      "provider": "github",
      "repo": "mostafasayed118/quran-app-checkpoints"
    }
  }
}
```

If `opencode2` is missing, or the file is absent, stop and say so — do not improvise.

## 3. Hard rules

1. **Never hand-edit** `.entire/settings.json` (shared) or `.entire/settings.local.json` (per machine).
2. **Never commit** `.opencode/plugins/entire-external.ts`. It is regenerated per device and it is not part of the product.
3. **Push branches to `origin`** (GitHub). That is the only push that makes checkpoints sync by themselves. Pushing to the `entire` remote breaks the sync — see §6.
4. `refs/entire/*` carries session transcripts. They go to the private checkpoint repo, never to the public `origin`.
5. After `entire agent add opencode2 --force`, **re-add `windowsHide: true`** to the plugin's `spawn` options — see §6.

## 4. The loop

```powershell
git switch -c <type>/<short-name>
# … commits with explicit pathspecs (never `git add -A`) …
git push -u origin <branch>          # checkpoints sync automatically here

entire trail create --title "<title>" --type feature   # or: entire trail link <n> --branch <branch>
# the three agents start on their own: agent.updated goes queued → running → succeeded, ~60-90s

entire trail finding                 # dashboard: open / resolved / dismissed / stale
entire trail finding list --json     # full bodies, file:line, severity, confidence
entire trail watch --once --json     # live events (agent.updated, comment.created, gate.updated)
```

Fix → commit → push again: the new head is re-evaluated automatically.

Close a finding that is not worth acting on, with the reason recorded:

```powershell
entire trail finding dismiss <finding-id> -m "<why>"
```

After the work lands on `main`:

```powershell
entire trail update <trail-id> --status closed
```

## 5. Fresh clone or new machine

Once per machine:

1. Recreate `.entire/settings.local.json` with the JSON in §2.
2. `entire repo remote add entire` — adds the `entire://` remote for the mirror.
3. `entire agent add opencode2` — regenerates `.opencode/plugins/entire-external.ts`, then re-apply `windowsHide: true` (§6).
4. Make sure the adapter exists: `~/.local/share/entire-agent-opencode2/agent.cjs` and `~/.local/bin/entire-agent-opencode2.cmd`. These are **not** in the repo; copy them from a working machine.

## 6. Known failure modes

**Checkpoint refs fail on push to `entire`.**

```
fatal: repository gh/mostafasayed118/quran-app-checkpoints not found on aws-us-east-2.entire.io
```

The CLI derives the checkpoint URL from the **protocol of the remote you push to**. An
`entire://` remote yields `gh/<owner>/<repo>` on the Entire forge, which is not where the
private archive lives. Reference: `checkpoint/remote/util.go` → `PushURL`.

Two fixes, in order of preference:

- push the branch to `origin` instead (sync then works by itself), or
- flush the queued refs to the private archive:

```powershell
git for-each-ref --format="%(refname)" | Select-String "refs/entire/checkpoints" |
  ForEach-Object { $n = $_.ToString().Trim();
    git push https://github.com/mostafasayed118/quran-app-checkpoints.git "$($n):$($n)" }
```

**A console window flashes on every step.** The plugin spawns `entire.exe` per hook; without
`windowsHide` Windows allocates a console for each one (measured: 204 windows in 15 minutes).
The generated plugin does not set it, so after every regeneration:

```ts
const proc = spawn(ENTIRE, ["hooks", AGENT, hook], {
  cwd: directory,
  stdio: ["pipe", "ignore", "ignore"],
  windowsHide: true,   // required on Windows
})
```

**The built-in `opencode` agent logs a load warning.** Harmless — `opencode2` is the adapter in use.

## 7. Cheat sheet

| Task | Command |
|---|---|
| Is it live? | `entire status` |
| Checkpoints on this branch | `entire checkpoint list` |
| Read one checkpoint | `entire checkpoint explain <id>` |
| Queued checkpoints | `entire checkpoint list --outgoing` |
| Trails on this project | `entire trail list --project gh/mostafasayed118` |
| Merge through Entire | `entire trail merge` (checks gates first; `up_to_date` is non-blocking) |
