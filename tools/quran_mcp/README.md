# quran_mcp — experimental MCP server

Read-only MCP tools over the Quran Yahdi offline content.

## Tools

- `quran_search` — FTS5 trigram search over `ayah_search`, built from the
  imla'i text and normalized the same way as the app. Tokens shorter than a
  trigram fall back to a `LIKE` scan over the same index. Returns `total`,
  `offset`, `returned` and `has_more`, so a page can be walked without losing
  the match count.
- `quran_surah` — surah name, ayah count, the Uthmani text from
  `assets/quran/uthmani/<id>.json`, and each ayah's imla'i text for searching.

## Run

From the app root:

```
dart run tools/quran_mcp/bin/server.dart
```

Or from this directory, pointing at the checkout:

```
dart run bin/server.dart --root ..\..
```

## opencode

```json
{
  "mcp": {
    "servers": {
      "quran-assets": {
        "type": "local",
        "command": ["dart", "run", "bin/server.dart", "--root", "..\\.."],
        "cwd": "tools/quran_mcp",
        "disabled": false
      }
    }
  }
}
```

## Scripts

Search runs over the **imla'i** text. The Uthmani script spells some words
differently (e.g. الصلوة vs الصلاة), so search the `text_imlaei` returned by
`quran_surah` or `quran_search`. The database's `text_uthmani` column is
private-use glyph data for the HafsSmart font; the readable Uthmani text is
the JSON asset.

## Tests

```
dart pub get
dart test
```

The suite starts the real server over stdio and checks the search contract,
paging, the surah payload, and the failure paths (missing FTS index, corrupt
Uthmani JSON). It needs the app checkout next to this package.

## Limits

- No fallback when `ayah_search` is missing: search fails closed with a clear
  message, while `quran_surah` keeps working from the JSON assets.
- The first run downloads the `sqlite3` native asset (cached under
  `.dart_tool/lib`).
