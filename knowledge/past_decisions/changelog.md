# Changelog page

Design: https://claude.ai/artifact/4J2onga87b5WAJMJBGuQsy (1280 / 1920 / 390 px boards).

## Decision

One file, `assets/resources/changelog.json`, embedded at compile time (like `openings.json`). Array order is display order: newest first. Adding an update = pasting one object at the top.

```json
[
    {
        "date": "2026-10-12",
        "title": {"en": "Update title", "ru": "Название обновления"},
        "description": {
            "en": ["First paragraph.", "Second paragraph."],
            "ru": ["Первый абзац.", "Второй абзац."]
        }
    },
    {"date": "2021-03-17", "title": {"en": "Added changelog", "ru": "Добавлен список изменений"}}
]
```

- `date`: ISO `yyyy-mm-dd`. Same-day updates are told apart by array order only (no `/1`, `/2` suffixes).
- `title`: required; `en` required, `ru` optional.
- `description`: optional; `en`/`ru` are arrays of plain-text paragraphs. Absent = title-only row (all pre-description entries).
- A missing `ru` falls back to `en`, so a new entry can be written in English alone.
- The page shows whatever has a description in the expanded layout and the rest as compact rows; no cutoff date in the data.

- Updates sharing a date are numbered 1-based, oldest first, and shown as a dimmed `#n` under the date; a lone update on its date has no number. Derived from the array order, not stored.
- When `ru` is given for a description, it must have as many paragraphs as `en` (checked on load).
- Dates render as `12 Oct 2026` / `12 окт 2026` through `ProfileFormatters.shortDateWithYear`.
