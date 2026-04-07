# blockr.admiral — Design Extensions

Extends the base blockr block design system documented in `blockr.dplyr/dev/design-system.md`.

## What's new in admiral

### Two-level labels

Argument labels show both human-readable and R code names:

```
Date column              ← primary: 0.8125rem, --blockr-color-text-primary
dtc                      ← secondary: 0.6875rem, mono, --blockr-grey-400
```

170px fixed width. Human name helps new users, code name helps admiral users map to the actual function signature.

### Function selector with rich dropdown

The function selector uses `Blockr.SelectRich` with `groupColors` to render:
- Colored icon square (white bg, colored 1px border, colored SVG fill)
- Bold label in system font
- Category badge pill
- Description line with function name in text
- Group headers (uppercase, 10px, grey)

Icon squares are 36px in dropdown, 22px in selected state. Each function group has a color:
- Simple Derivations: `#10b981` (green)
- Dates & Times: `#3b82f6` (blue)
- Duration: `#8b5cf6` (purple)
- Flags: `#f59e0b` (amber)
- Baseline: `#ef4444` (red)
- Merge & Lookup: `#06b6d4` (cyan)

Icons are per-function (Bootstrap Icons paths stored in the catalog JSON). The white-bg + colored-border style distinguishes them from blockr.dock's filled block icons.

### Enum selects with value codes

When `Blockr.SelectRich` is used without `groupColors` (argument enums), no icons render. Items show:
- Human label in bold ("Year", "First day of period")
- Actual R value in mono muted ("Y", "first")
- Description line

This lets users see both what the option means and what value gets sent to admiral.

### Form layout (not row builder)

Unlike dplyr (add/remove condition/mutation rows), admiral uses a fixed form layout — arguments are predetermined by the selected function. The layout is:

```
[ Function selector ]           ← Blockr.SelectRich, bordered, 42px

  Human label        [ input ]  ← required args, always visible
  code_name
  
  Human label        [ input ]
  code_name

                           [⚙]  ← gear button, right-aligned, 8px margin-top

  ┌─ popover ─────────────┐     ← inline below gear, full width
  │ Human label   [ input ]│       not absolute/overlay
  │ code_name              │
  └────────────────────────┘
```

### Popover is inline, not absolute

The gear popover is rendered in normal document flow below the gear button — not absolutely positioned. It spans the full width of the block (`left: 0; right: 0` not needed since it's inline). Dropdowns inside it are left-aligned and also full width.

This differs from the dplyr popover pattern (absolute, right-anchored, fixed min-width). The inline approach avoids overflow issues and keeps the gear button always visible.

### All inputs match the 42px standard

Text inputs, expression inputs, bordered selects, and column selects all use `min-height: 42px` with `padding: 10px 14px`. This matches blockr.dock's standard form control sizing. No special reduced heights for admiral — all inputs are visually consistent.

### Inputs inherit font

All text/expression inputs use `font: inherit` — no monospace. The system font from blockr.dock applies everywhere except explicit code labels.

## TODOs

- **Code label font size (0.6875rem / 11px):** Not aligned with dock's `--blockr-font-size-xs` (0.75rem / 12px). Either bump to 0.75rem or add a new tier to the dock variables.

- **SelectRich extraction:** `Blockr.SelectRich` (blockr-select-rich.js/css) is reusable and not admiral-specific. Currently lives in blockr.admiral but should move to blockr.core alongside Blockr.Select and Blockr.Input.

- **Group color palette:** The function group colors (green, blue, purple, amber, red, cyan) are arbitrary hex values. If other packages add group-colored selectors, there's no shared palette. Consider defining a `--blockr-category-*` variable set in blockr.dock.
