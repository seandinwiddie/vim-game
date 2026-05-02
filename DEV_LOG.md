# 🌑 QUA'DAR MUD: DEV LOG 🌑

`Státus: MVP_v1.0 // Protocol: CYBER_GRIMDARK`

## ᚠ FUNCTIONAL ARCHITECTURE
- **Stateless Core**: All game logic resides in pure functions within `autoload/game/core.vim`.
- **Side-Effect Isolation**: Buffer manipulation and Vim-specific events are isolated in `autoload/game/engine.vim`.
- **Immutable State**: Single Dictionary state management ensures predictable transitions and debuggability.

## ᚢ THE LOOM OF FATE (GAME MECHANICS)
- **d100 Oracle**: Implemented the "Loom of Fate" narrative engine via the `ask` command.
- **Surge Count**: Procedural modifier system that tracks world tension. Plain "yes/no" results increment the surge count by 2, while nuanced results reset it to 0. Surge count is dynamically added/subtracted from the d100.
- **Scene Stages**: Three matrices (To Knowledge, To Conflict, To Endings) map d100 rolls (adjusted by surge) to full spectrum responses: YES, AND UNEXPECTEDLY / YES, BUT / YES, AND / YES / NO / NO, AND / NO, BUT / NO, AND UNEXPECTEDLY.
- **Unexpected Modifiers**: Rolls d20 on Table 2 (foreshadowing, set change, limelit, etc.) when an "unexpectedly" result triggers.
- **Narrative Threads**: Integrated a state array for active storylines. Threads are rendered in the Neural Link header to track active goals (e.g. "Find Missing Rangers").

## ᚦ WORLD & LORE (QUADAR TOWER)
- **Character**: Kamenal, Level 12 Rogue/Ranger (Starting state from `quadar_familiar.md`).
- **Locations**: 
  - `Merchandise Store Room` (Starting Nexus)
  - `Dark Corridor` (Umbral Reach)
  - `Base of Quadar Tower` (Spire Bastion)
- **Narrative Style**: Descriptions infused with PKD paranoia, Gibson grit, and Lovecraftian dread.

## ᚨ UX & AESTHETIC PROTOCOLS (0xDEADBEEF)
- **Runes & Sigils**: Interface framed with Unicode runes (ᚠ, ᚢ, ᚦ, etc.) and protective sigils.
- **Dynamic Guidance**: Real-time **DIRECTIVE** system in the header provides step-by-step instructions.
- **Syntax Highlighting**: Custom `mud` filetype with highlighting for system logs, runes, and critical alerts.
- **Robust Redraw**: Forced `redraw!` logic to handle complex split-window or plugin-heavy environments.

## ᚱ COMMAND SYSTEM
- `look` / `l`: Scan the immediate vicinity.
- `go [dir]` / `n`/`s`/`e`/`w`: Coordinate shifting between nodes.
- `ask [question]` / `a`: Consult the Loom of Fate oracle (e.g. `ask is the door locked?`).
- `stage [name]` / `1`, `2`, `3`: Shift stage to Knowledge (1), Conflict (2), or Endings (3).
- `thread [add/rm] [arg]`: Track narrative threads.
- `q`: Terminate the Neural Link.

---
*Watched by the Eye in the Code.* 👁️
