# 🌑 QUA'DAR MUD: DEV LOG 🌑

`Státus: MVP_v1.0 // Protocol: CYBER_GRIMDARK`

## ᚠ FUNCTIONAL ARCHITECTURE
- **Stateless Core**: All game logic resides in pure functions within `autoload/game/core.vim`.
- **Side-Effect Isolation**: Buffer manipulation and Vim-specific events are isolated in `autoload/game/engine.vim`.
- **Immutable State**: Single Dictionary state management ensures predictable transitions and debuggability.

## ᚢ THE LOOM OF FATE (GAME MECHANICS)
- **d100 Oracle**: Implemented the "Loom of Fate" narrative engine.
- **Surge Count**: Procedural modifier system that tracks world tension and influences scavenging outcomes.
- **Scavenging Loop**: Players can scavenge for relics; results are determined by the Loom (Success/Yes/No/Unexpected).

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
- `scavenge`: Initiate the Loom of Fate protocol.
- `q`: Terminate the Neural Link.

---
*Watched by the Eye in the Code.* 👁️
