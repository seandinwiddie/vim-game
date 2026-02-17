# VIM QUEST

A minimal, functional-style game built entirely in Vimscript.

## Installation

### Manual Loading
To try the game immediately without installing it permanently, you must add the folder to your Vim `runtimepath` so it can find the `autoload` scripts:
1. Open Vim.
2. Run the following commands:
   ```vim
   :set runtimepath+=~/GitHub/vim-game
   :source ~/GitHub/vim-game/plugin/game.vim
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
2. Press **`<Space>`** to start from the title screen.
3. Press **`q`** at any time to quit the game buffer.

## Architecture
This project follows functional programming principles:
- **Immutable State**: Game logic operates on a state dictionary.
- **Pure Views**: The UI is a pure function of the current state.
- **Side-Effect Isolation**: All buffer manipulations are sequestered in the engine layer.

## License
All rights reserved. © 2026 ForbocAI. See [LICENSE](./LICENSE) for full details.
