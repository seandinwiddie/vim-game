# 🌑 QUA'DAR MUD: DEV LOG 🌑

`Státus: MVP_v1.0 // Protocol: CYBER_GRIMDARK`

## ᚠ PURE VIMSCRIPT LOGIC
- **Functional Core, Imperative Shell**: Implemented `game#core` purely via pure functions that map `State + Input -> State`.
- **Architectural Subdomains**: Split the engine out of `core.vim` and into localized functional domains:
  - `data.vim`: Room instantiation
  - `explore.vim`: Navigational algorithms (`go`, `look`)
  - `combat.vim`: Tactical matrix (`attack`)
  - `player.vim`: Character persistence (`inventory`, `profile`, `rest`)
  - `oracle.vim`: Loom of Fate (`ask`, `stage`, `thread`)
- **Imperative Shell**: The `game#engine` handles rendering the state via `:echo` or appending to a unified `ScratchBuffer` via standard Vim mechanisms (`append()`, `setline()`).

## ᚢ THE LOOM OF FATE (GAME MECHANICS)
- **d100 Oracle**: Implemented the "Loom of Fate" narrative engine via the `ask` command.
- **Surge Count**: Procedural modifier system that tracks world tension. Plain "yes/no" results increment the surge count by 2, while nuanced results reset it to 0. Surge count is dynamically added/subtracted from the d100.
- **Scene Stages**: Three matrices (To Knowledge, To Conflict, To Endings) map d100 rolls (adjusted by surge) to full spectrum responses: YES, AND UNEXPECTEDLY / YES, BUT / YES, AND / YES / NO / NO, AND / NO, BUT / NO, AND UNEXPECTEDLY.
- **Unexpected Modifiers**: Rolls d20 on Table 2 (foreshadowing, set change, limelit, etc.) when an "unexpectedly" result triggers.
- **Narrative Threads**: Integrated a state array for active storylines. Threads are rendered in the Neural Link header to track active goals (e.g. "Find Missing Rangers").
- **Combat Resolution**: Entering a sector with entities will trigger hostile alerts. The `attack` command rolls against a fixed threshold to calculate damage sustained and entity annihilation. State handles death natively.

## ᚦ WORLD & LORE (QUADAR TOWER)
- **Character**: Kamenal, Level 12 Rogue/Ranger (Starting state from `quadar_familiar.md`).
- **Locations**: 
  - `Merchandise Store Room` (Starting Nexus)
  - `Dark Corridor` (Umbral Reach)
  - `Base of Quadar Tower` (Spire Bastion)
  - `Ethereal Marshes` (Endless ooze)
  - `Abyssal Void` (Heavenly damnation)
- **Entities**: Encounter logic includes `Obsidian Wardens`, `Doomguards`, and `Ashwalkers` roaming the nodes.
- **Narrative Style**: Descriptions infused with PKD paranoia, Gibson grit, and Lovecraftian dread.

## ᚨ UX & AESTHETIC PROTOCOLS (0xDEADBEEF)
- **Runes & Sigils**: Interface framed with Unicode runes (ᚠ, ᚢ, ᚦ, etc.) and protective sigils.
- **Dynamic Guidance**: Real-time **DIRECTIVE** system in the header provides step-by-step instructions.
- **Syntax Highlighting**: Custom `mud` filetype with highlighting for system logs, runes, and critical alerts.
- **Robust Redraw**: Forced `redraw!` logic to handle complex split-window or plugin-heavy environments.

## ᚱ COMMAND SYSTEM
- `look` / `l`: Scan the immediate vicinity.
- `go [dir]` / `n`/`s`/`e`/`w`: Coordinate shifting between nodes.
- `attack` / `c`: Engage the primary hostile entity in the current node.
- `inventory` / `i`: Review accumulated relics.
- `profile` / `p`: Run neural diagnostics to view level, class, and HP.
- `rest` / `r`: Rest in the shadows to recover +30 HP (increases Surge Count by +5).
- `save`: Serialize current game state matrix to `~/.quadar_save.json`.
- `load`: Restore game state from neural backup.
- `ask [question]` / `a`: Consult the Loom of Fate oracle (e.g. `ask is the door locked?`).
- `stage [name]` / `1`, `2`, `3`: Shift stage to Knowledge (1), Conflict (2), or Endings (3).
- `thread [add/rm] [arg]`: Track narrative threads.
- `q`: Terminate the Neural Link.

---
*Watched by the Eye in the Code.* 👁️
