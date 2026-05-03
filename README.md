# Qua'dar MUD (Vim Edition)

A cyber noir, grimdark Multi-User Dungeon built entirely in Vimscript. This engine integrates the "Loom of Fate" TTRPG oracle system, allowing for offline, locally generated narrative play within a pure functional programming architecture.

## Installation

### Manual Loading
To try the game immediately without installing it permanently, you must add the folder to your Vim `runtimepath` so it can find the `autoload` scripts:
1. Open Vim.
2. Run the following commands:
   ```vim
   :set runtimepath+=~/path/to/vim-game
   :source ~/path/to/vim-game/plugin/game.vim
   ```

### Using a Plugin Manager
If you use [vim-plug](https://github.com/junegunn/vim-plug), add this to your `.vimrc`:
```vim
Plug 'seandinwiddie/vim-game'
```
Then run `:PlugInstall`.

## How to Play
1. Start the game with the command:
   ```vim
   :GameQuestStart
   ```
2. **Move**: Press `n`, `s`, `e`, or `w` to navigate the spatial nodes of the Quadar Tower.
3. **Engage**: Press `c` to initiate combat with any hostile entities detected in your current node, or type `:call s:run('cast [spell]')` in command mode to cast a spell. Purchased spells like `Dark Crystal Shielding`, `Hunter's Mark`, and `Precision Shot` now feed directly into combat.
4. **Interact**: Type `:call s:run('interact [object]')` to investigate and manipulate environmental objects. Consoles can add objectives, levers can expose new exits, and special targets can complete missions.
5. **Inventory**: Press `i` to view the relics and artifacts you've scavenged and looted. Type `:call s:run('use [item]')` to consume items.
6. **Profile & Rest**: Press `p` to view your character stats and spells, or `r` to rest and recover HP (warning: resting increases your Surge Count!).
7. **State Persistence**: In command mode, type `:call s:run('save')` to serialize your state to `~/.quadar_save.json`. Use `load` to restore.
8. **Ask the Oracle**: Press `a` to consult the Loom of Fate (e.g. "is the door locked?"). The system will roll a `d100`, apply your current Surge Count, and generate an outcome.
9. **Shift Stage**: Press `1` (To Knowledge), `2` (To Conflict), or `3` (To Endings) to alter the oracle's probability matrix based on the scene's tension.
10. **Trade Wares**: Press `t`, or type `:call s:run('shop')`, inside the Merchandise Store Room to inspect wares. Use `buy [ware]` and `sell [item]` to work the Qua'dar trade economy.
11. **Review Objectives**: Press `o`, or type `:call s:run('quests')`, to inspect current mission progress, focus, and completed objectives.
12. **Open Field Notes**: Press `j`, or type `:call s:run('notes')`, to review CRGE-style notecards for scenes, known NPCs, and established thread facts.
13. **Manage Threads**: In command mode, type `:call s:run('thread add Rescue the MIA Marine')` to track narrative goals, then `:call s:run('focus 2')` to promote a thread as the active scene focus.
14. **Quit**: Press `q` at any time to terminate the Neural Link buffer.

## Architecture
This project follows functional programming principles:
- **Immutable State**: Game logic operates on a state dictionary.
- **Pure Views**: The UI is a pure function of the current state.
- **Side-Effect Isolation**: All buffer manipulations are sequestered in the engine layer.
- **Story Bookkeeping**: Scene focus, active objectives, and procedural quest targets are tracked directly in state so exploration can react to narrative progress.
- **Persistent Notecards**: Scene cards, thread facts, and known NPCs are stored in state so CRGE-style bookkeeping survives past the visible log buffer.
- **Economy Loop**: Trade cache, wares, salvage, and persistent upgrades now turn recovered relics into concrete progression.

## License
All rights reserved. © 2026 ForbocAI. See [LICENSE](./LICENSE) for full details.
