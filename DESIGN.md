---
name: ShakeStir
description: "Warm, practical cocktail discovery and readable preparation."
colors:
  primary: "#4d5b2e"
  primary-hover: "#35421e"
  background: "#f7f5ee"
  text: "#202923"
  muted: "#596155"
  border: "#d9dbcf"
  input-surface: "#fffef9"
  input-border: "#a7ad9b"
  placeholder: "#62695d"
  focus: "#63733a"
  danger: "#9a3126"
  panel: "#fffef8"
  checked: "#eff2e7"
  chip: "#e9ecd9"
  chip-text: "#435226"
typography:
  headline:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif"
    fontSize: "3rem"
    fontWeight: 600
    lineHeight: 1.12
    letterSpacing: "-.035em"
  page-title:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif"
    fontSize: "2.5rem"
    fontWeight: 600
    lineHeight: 1.08
    letterSpacing: "-.035em"
  mobile-title:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif"
    fontSize: "2rem"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "-.035em"
  section-title:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif"
    fontSize: "1.5rem"
    fontWeight: 600
    lineHeight: 1.15
    letterSpacing: "-.035em"
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: 1.6
    letterSpacing: "normal"
  preparation:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif"
    fontSize: "1.25rem"
    fontWeight: 400
    lineHeight: 1.75
    letterSpacing: "normal"
  label:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif"
    fontSize: ".9rem"
    fontWeight: 600
    lineHeight: 1.6
    letterSpacing: "normal"
rounded:
  control: ".7rem"
  field: ".75rem"
  panel: "1rem"
  pill: "3rem"
spacing:
  half: ".5rem"
  one: "1rem"
  panel: "1.5rem"
  section: "2rem"
  wide: "2.5rem"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.input-surface}"
    rounded: "{rounded.pill}"
    padding: ".7rem 1.2rem"
    height: "2.9rem"
  button-primary-hover:
    backgroundColor: "{colors.primary-hover}"
  button-secondary:
    backgroundColor: "{colors.input-surface}"
    textColor: "{colors.text}"
    rounded: "{rounded.pill}"
    padding: ".7rem 1.2rem"
    height: "2.9rem"
  field:
    backgroundColor: "{colors.input-surface}"
    textColor: "{colors.text}"
    rounded: "{rounded.field}"
  chip:
    backgroundColor: "{colors.chip}"
    textColor: "{colors.chip-text}"
    padding: ".3rem .85rem"
    height: "2.2rem"
    rounded: "{rounded.pill}"
  recipe-panel:
    backgroundColor: "{colors.panel}"
    textColor: "{colors.text}"
    rounded: "{rounded.panel}"
    padding: "{spacing.panel}"
---

# Design System: ShakeStir

## Overview

**Creative North Star: "Find a drink. Make it yours."**

ShakeStir retains its warm ivory and olive interface on the Semanticus foundation. System sans-serif typography, recognizable native controls and restrained panels support finding a drink and reading its preparation while mixing.

Photographs lead discovery; working surfaces stay quiet. Existing seed photography and cached assets originate from TheCocktailDB, with credits retained in cocktail and recipe records. This document describes the Rails implementation, including its adapted administration and static recovery pages.

**Key Characteristics:**
- Warm ivory ground and olive actions.
- Photo-led discovery and restrained reading panels.
- Visible native checkboxes and comfortably sized controls.

## Colors

Olive actions sit on warm ivory and near-white surfaces, with dark green text.

### Primary

- **Olive:** primary actions, checked controls, progress and useful links; the darker hover token communicates interaction.
- **Olive focus:** visible keyboard outlines.

### Neutral

- **Ivory ground:** page canvas and sticky header.
- **Near-white surfaces:** inputs, forms and recipe panels.
- **Dark green ink / muted ink:** primary reading and secondary explanation respectively.
- **Quiet border / input border:** section separation and recognizable editable fields.
- **Checked tint / chip tint:** persistent selection feedback.

The danger token identifies destructive actions and validation errors; it is not a second brand accent.

**The Working Surface Rule.** Use near-white panels and thin borders to separate tasks from the ivory ground.

## Typography

**Display and body font:** the platform system sans-serif stack in the tokens. No external font asset is required.

Detail headlines use the headline role; library and discovery headings use page-title, with mobile-title on narrow screens. Section titles use section-title. Labels are semibold and ordinary body copy follows the body role. Preparation uses the larger preparation role; ingredient prose is slightly smaller (1.125rem). Descriptions constrain reading width, commonly 48ch; disclosure prose reaches 70ch. Preserve multilingual content and wrap long names and submitted prose.

**The Reading Rule.** Preserve preparation prose, readable line height and visible native checkboxes.

## Layout

The shared content grid caps at 78rem with 1.5rem gutters, reduced to 1rem at 36rem. Detail and library pages cap at 72rem; the recipe editor at 58rem, collection editor at 42rem and authentication at 32rem. Discovery auto-fills cards from an 18rem minimum; libraries use 17rem. Spacing repeatedly uses half-rem steps, with larger section gaps.

Canonical cocktail details use a large, centered cover photograph with a dark title, description and public recipe count over a gradual ivory wash. The photograph spans the window width and fills the first viewport below the header, softens into ivory behind the copy and continues seamlessly into the page. A Back to cocktails button sits over its upper-left corner; history and sources follow on the ivory reading surface without repeating the description. Records without photographs use a pale olive cover with dark text. Recipe details use a compact title, author, method and time header with star and collection actions; ingredients and preparation immediately follow in a 2:3 grid. Recipe details share the full-width cocktail photo cover and ivory blend, with the recipe name and author attribution above the ingredient and preparation workbench. Save controls sit at the upper-right of the cover; the recipe title omits the author handle. Attribution links to the author and, when linked, the canonical cocktail; the cocktail opens in a right-hand dialog containing its details page, with a normal-page fallback. Canonical context is omitted from the recipe body. Source credits follow the mixing area, then Related recipes. Mobile recipe headers offer a preparation jump link. Recipe working sections are unboxed with no row dividers or ingredient thumbnails; accessible progress stays visually hidden, and reset actions appear only after checking an item. Single-step recipes omit the step number. At 55rem the detail mixing grid narrows to 1:1.4; at 45rem it stacks, as do the hero and editor sections. Navigation becomes two rows at 45rem. Phone availability pickers become fixed within 1rem side/bottom insets and an 8rem top inset at 36rem, with their option list scrolling internally. Administration stacks its navigation and fields at 50rem and keeps wide tables in a local horizontal scroller. Recovery pages cap their reading column at 42rem.

## Elevation & Depth

Borders and tonal surfaces provide most separation. Forms and recipe panels stay flat. The header uses a fine shadow divider. Floating account menus, availability pickers and the collection dialog use soft shadows; the dialog dims its backdrop. Collection artwork may lift on hover when motion is permitted. Exact shadows and breakpoints are recorded in the sidecar.

Image hover scales to 1.025 over .25s ease; collection artwork transitions over 180ms ease-out. Reduced-motion styles remove transitions, animations and interaction transforms. Higher-contrast styles strengthen borders and text.

## Shapes

Pill actions and search controls contrast with softly rounded rectangular panels. Standard controls use control radius; editor fields use field radius; panels and 4:3 photo frames use panel radius. Avatars and image save buttons are circles. Administrative actions retain their smaller rectangular corners (.75rem). Thin borders define fields and panels; empty library surfaces may use dashed borders.

## Components

- **Buttons:** olive primary and near-white bordered secondary library actions use semibold labels; their minimum height is 2.9rem. Primary hover darkens. The global keyboard outline is 3px with a 4px offset; active buttons scale to .98 unless reduced motion is requested. Inline reset/remove actions remain quiet text controls with useful hit areas.
- **Inputs:** near-white fields use the stronger input border, visible labels and olive caret. Editor fields retain native behavior and a 1rem font. Validation introduces danger borders and nearby explanatory errors.
- **Navigation:** the sticky header combines wordmark, central links and account/create actions. Current links gain olive underlines and semibold text. Detail jump navigation uses thin horizontal borders and 2.75rem link targets.
- **Chips and pickers:** removable availability chips use the pale olive chip tint. Picker options expose native checkboxes; selected options use olive fill and move first. Match buttons use pressed state, tinted fill and an inset olive edge. Loading results dim to .55 and expose busy state; feedback remains plain inline text.
- **Discovery and library cards:** 4:3 clipped photographs or existing artwork lead; copy and metadata sit below without heavy card chrome. Titles underline on hover. Preserve the existing placeholder treatment when no image exists.
- **Recipe panels:** near-white bordered panels contain ingredient or preparation checklists. Rows divide with thin borders, use visible native checkboxes and tint on completion; preparation prose strikes through when checked. Completion counts, progress and reset support the current mixing session. Print styles remove surrounding navigation and photography.
- **Collection dialog:** a centered, bounded near-white surface with a dim backdrop, close action and internally scrolling choices. Saved choices show pressed state and olive borders; status text reports changes.
- **Account and recovery:** authentication uses a compact bordered form, full-width submit and separated account links. Recovery pages retain the wordmark, plain explanation and olive route back to discovery. Administration keeps its familiar catalog controls within the same palette and type.

## Do's and Don'ts

### Do:

- Do retain the ivory ground, olive actions and system sans-serif stack.
- Do preserve recipe prose, translations and image source credits.
- Do show selected, loading, empty, error and disabled states near the control or content they affect.
- Do respect reduced motion and retain visible keyboard focus.

### Don't:

- Don't introduce decorative typography or a replacement visual identity.
- Don't make secondary background stories compete with preparation.
- Don't replace native checkbox and radio affordances with ambiguous decoration.
