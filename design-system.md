# brain — design system

Working title: **Ledger.**

A quiet, paper-shaped language for one person's books. Inspired by 19th-century
ledger pages and modern fintech (Mercury, Brex, Linear documents): generous
margins, tabular numbers in monospace, restrained color, one distinctive
accent. Functional first; if it doesn't help Luis read his books at 11pm on
a Tuesday, it doesn't ship.

---

## Principles

1. **Documents, not screens.** An invoice, a receipt, a bank statement —
   they're documents. The app frames them with whitespace and rules, not
   cards-on-cards-on-cards.
2. **Numbers are typography.** Every monetary value, every quantity, every
   date, every reference number is in monospace with tabular figures. Columns
   align by glyph, not by negotiation.
3. **One accent, sparingly.** A single warm umber for primary actions and
   document marks. Status uses tone (positive green, alert rust) only where
   absolutely needed. Almost everything is neutral.
4. **No decoration without function.** Rules separate sections because we
   need separation. Pills exist where status genuinely matters. Icons appear
   when typography alone is ambiguous. Nothing for vibe.
5. **Dense, not loose.** Use the spacing scale, but lean dense. One row
   per ledger entry, title + meta inline, ~30px row height. The user is
   reading a book of accounts, not browsing a landing page.
6. **Fewer clicks to done.** Every flow has a click-count target; if a
   reasonable redesign cuts a click, take it. Specifically:
   - Capture is one tap from anywhere (header button + bottom-nav action).
   - Send invoice fires straight from the tray Send pill — no detour.
   - Match a bank tx → candidates should be inline on the home tray when
     possible, not a separate page navigation. (Currently a separate
     page; revisit if it adds friction.)
   - Dismiss is one tap from the same surface that surfaces the item.
   - Auto-save is the default for any document edit — no explicit save.
   Rule of thumb: if a routine task takes more than two taps from the
   home page, it's a bug in the design, not a feature.

---

## Voice

- Plain English. No "Awesome!" — "Saved" is enough.
- Lowercase microcopy where it doesn't start a sentence: "saves automatically
  as you type", not "Saves Automatically As You Type".
- Action verbs over nouns: "Send to Lab900", not "Send Invoice".
- No exclamation marks. No emoji in product UI (CLAUDE.md rule).
- Spanish where the law requires it (legal mentions, fiscal terms); English
  for everything else. Future i18n via Rails I18n.

---

## Color tokens

Warm-neutral palette built around a paper background and a deep ink. One
accent (umber) earns its keep on primary actions and document marks.

```css
:root {
  /* Surfaces */
  --paper:        #f8f6f1;   /* page bg — slightly warm off-white */
  --paper-deep:   #f1ede4;   /* hover / pressed surfaces */
  --surface:      #ffffff;   /* a document on the paper */
  --ink:          #1a1816;   /* primary text — almost-black, warm */
  --ink-soft:     #3a3530;   /* h2 / labels */
  --muted:        #88847d;   /* meta, hint, placeholder */

  /* Rules */
  --line:         #e7e3d8;
  --line-strong:  #c9c2b1;

  /* Accent — the umber. Used for primary buttons and document marks. */
  --accent:       #7a4f1f;
  --accent-deep:  #5a3914;
  --accent-soft:  #f0e6d3;

  /* Status (sparingly) */
  --positive:     #2b6e3e;
  --positive-bg:  #e1eedb;
  --alert:        #b04a2c;
  --alert-bg:     #fbe8db;
}
```

**Rule of thumb:** if it's not `ink` / `muted` / `line` / `accent`, ask why.

---

## Typography

Two families. No build, no font files — system stacks resolve to refined
fonts on every modern OS.

```css
:root {
  --sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue",
          Arial, sans-serif;
  --mono: ui-monospace, "SF Mono", SFMono-Regular, "JetBrains Mono", Menlo,
          Consolas, "Liberation Mono", monospace;
}
```

### Where mono is used (ALWAYS)

- Every monetary value: `€1,234.56`, `170`, `50.00`
- Quantities and rates in line items
- Invoice numbers (`#2026-0001`)
- Reference numbers (`VeriFactu vf-…`, `Holded ref hld_…`)
- VAT/NIF numbers (`BE0707.779.108`)
- IBANs (`ES00 0000 0000 0000 0000 0000`)
- Dates in document headers (`01/05/2026 → 31/05/2026`)
- Tabular columns in any list (stream entries' time column, totals)

### Where sans is used

- Headings (`Invoice`, `Home`, `Capture`)
- Body copy, labels, descriptions
- Button labels
- Brand mark (`brain`)

### Type scale

| Token        | Size       | Use                                            |
|--------------|------------|------------------------------------------------|
| `--t-xs`     | 0.6875rem  | UPPERCASE labels, micro-meta, table headers    |
| `--t-sm`     | 0.8125rem  | Meta, hints, payment terms footer              |
| `--t-base`   | 0.9375rem  | Body, form inputs, list rows                   |
| `--t-md`     | 1.0625rem  | Lead paragraph, hero numbers                   |
| `--t-lg`     | 1.25rem    | Section titles, invoice total                  |
| `--t-xl`     | 1.5rem     | Page titles (Invoice, Home)                    |
| `--t-2xl`    | 2.5rem     | Receipt amount, brand                          |

### Weights

- 400 default body
- 500 for table headers, button labels, totals row
- 600 for page titles
- 300 for the receipt-saved amount (delicate)

### Letterspacing

- Uppercase labels: `letter-spacing: 0.08em` (improves readability)
- Body: default
- Mono numbers: default

### `font-variant-numeric`

`tabular-nums` everywhere mono is used. Belt and suspenders, even though
most mono fonts already are tabular.

---

## Spacing scale

```css
:root {
  --s-0:  0;
  --s-1:  0.25rem;   /* 4 */
  --s-2:  0.5rem;    /* 8 */
  --s-3:  0.75rem;   /* 12 */
  --s-4:  1rem;      /* 16 */
  --s-5:  1.5rem;    /* 24 */
  --s-6:  2rem;      /* 32 */
  --s-7:  3rem;      /* 48 */
  --s-8:  4rem;      /* 64 */
}
```

Use the scale. Don't invent in-between values without a reason.

---

## Borders & rules

- **`--line`** 1px for everyday separators (rows, gentle divisions).
- **`--line-strong`** 1px for emphatic separators (totals row, section breaks).
- **No box shadows.** Documents don't float. The paper is flat.
- **Cards are a deprecated concept.** Use whitespace + a thin top/bottom rule.

### Radius

| Token        | Value     | Use                                |
|--------------|-----------|------------------------------------|
| `--r-sm`     | 0.25rem   | Inputs, small pills                |
| `--r-md`     | 0.5rem    | Tray items, secondary buttons      |
| `--r-pill`   | 999px     | Status pills (DRAFT, SENT, …)      |

Most things use `--r-sm`. The pill radius is for genuine pills only.

---

## Components

### Document

The shape of an invoice, receipt, statement: a white surface on paper, with
a thin top rule, generous interior padding, and a thin bottom rule. No
shadow, no rounded card frame.

```
┌─────────────────────────────────────┐
│ ─────────────────────────────────── │   thin --line-strong rule
│                                     │
│    Invoice                  DRAFT   │
│    #2026-0001 · 01/05–31/05         │   mono dates
│                                     │
│    ───                              │   thin --line rule
│    FROM             TO              │
│    ...              ...             │
│                                     │
│    [line items table]               │
│                                     │
│    ───                              │
│                  Subtotal  €8,500   │   mono numbers
│                  Total     €8,500   │
│                                     │
└─────────────────────────────────────┘
```

### Field (input)

Calm ash background, no border, 1px inset bottom rule. Hover deepens the
background; focus shifts to outlined `--ink`.

### Number / money

Always inside `<span class="num">` (or any element with `font-family: var(--mono); font-variant-numeric: tabular-nums;`). Money is right-aligned in
columns. Quantities are right-aligned. Reference numbers are wherever they
sit naturally in copy but stay mono.

### Pill / status

Two flavors:

1. **Inline label** for everyday status (DRAFT, FILED, etc.) — small caps,
   no background, letterspaced. Reads as part of typography.
2. **Pill** for truly distinct states (needs review, sending) — rounded
   background with one accent or alert color.

Don't use pills for everything. Most "status" reads better as small-caps
text.

### Button

| Variant      | Use                                |
|--------------|------------------------------------|
| `primary`    | The one action that moves state — Send, Save Capture |
| `quiet`      | Secondary actions — Save (when auto-save is in play), Cancel |
| `link`       | Tertiary — Edit, View detail        |

Primary uses `--accent` background, `--paper` text. Quiet is transparent
with `--muted` text, hover to `--ink`. Link is just `text-decoration: none`
with hover underline.

### Tray item

`--paper-deep` background, 1px `--line` border, `--r-md` radius. Lives in
the sidebar tray. Has a one-line title, a one-line meta, and a row of
action pills.

### Stream entry

A row in the day-grouped list on `/home`. Three-column grid: time / body /
right. Time is mono. The whole row is `<a>`, hover deepens the bg subtly.

---

## Motion

- Default transition: `120ms ease` for color/background changes on hover.
- No bouncing, no scaling, no slide-in animations. Things appear because
  they're there.
- Loading: show a quiet text indicator ("Saving…"), not a spinner.
- Focus rings: `outline: 2px solid var(--ink); outline-offset: -1px;`

---

## Number-formatting rules

These are app-wide conventions, enforced by helpers:

| Value type        | Format                          | Helper                |
|-------------------|---------------------------------|-----------------------|
| Money (display)   | `€1,234.56` — `,` thousands     | `display_money(v)`    |
| Money (edit)      | `1234.56` — no `€`, no `,`      | `format_money(v)`     |
| Quantity (display)| `170` or `1.5`                  | `format_quantity(v)`  |
| Date (header)     | `01/05/2026` per locale         | `l(date)`             |
| Date range        | `01/05/2026 → 31/05/2026`       |                       |
| Reference number  | `#2026-0001` with `#` prefix    |                       |
| VAT / NIF         | as provided, mono               |                       |
| IBAN              | with spaces every 4, mono       |                       |

Comma-tolerant parsing on the server: `650,00` and `650.00` mean the same
thing. Spanish users type comma; we normalize.

---

## File locations

- This document: `design-system.md` at the project root.
- CSS tokens + components: `app/assets/stylesheets/application.css` —
  organized in this order: tokens → resets → typography → utilities →
  components.
- Helpers for number formatting: `app/helpers/invoices_helper.rb` (will be
  promoted to `app/helpers/numbers_helper.rb` once a second consumer exists).

---

## How to change this document

This file is the source of truth. To deviate:

1. Update this document first.
2. Then update the CSS.
3. Then update components.

If a value drifts in the CSS without updating this doc, it's a bug.
