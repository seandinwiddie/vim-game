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
3. **Engage**: Press `c` to initiate combat with any hostile entities detected in your current node.
4. **Inventory**: Press `i` to view the relics and artifacts you've scavenged and looted.
5. **Profile & Rest**: Press `p` to view your character stats, or `r` to rest and recover HP (warning: resting increases your Surge Count!).
6. **State Persistence**: In command mode, type `:call s:run('save')` to serialize your state to `~/.quadar_save.json`. Use `load` to restore.
7. **Ask the Oracle**: Press `a` to consult the Loom of Fate (e.g. "is the door locked?"). The system will roll a `d100`, apply your current Surge Count, and generate an outcome.
8. **Shift Stage**: Press `1` (To Knowledge), `2` (To Conflict), or `3` (To Endings) to alter the oracle's probability matrix based on the scene's tension.
9. **Manage Threads**: In command mode, type `:call s:run('thread add Rescue the MIA Marine')` to track narrative goals.
10. **Quit**: Press `q` at any time to terminate the Neural Link buffer.

## Architecture
This project follows functional programming principles:
- **Immutable State**: Game logic operates on a state dictionary.
- **Pure Views**: The UI is a pure function of the current state.
- **Side-Effect Isolation**: All buffer manipulations are sequestered in the engine layer.

## License
All rights reserved. © 2026 ForbocAI. See [LICENSE](./LICENSE) for full details.
