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
   Use `:call s:run('help')` (or `commands`) at any point to print the current in-game command reference generated from the action registry. Use `:call s:run('undo')` to rewind the last dispatched turn.
2. **Move**: Press `n`, `s`, `e`, or `w` to navigate the spatial nodes of the Quadar Tower.
3. **Engage**: Press `c` to initiate combat with any hostile entities detected in your current node, or type `:call s:run('cast [spell]')` in command mode to cast a spell. Purchased spells like `Dark Crystal Shielding`, `Explosive Barrage`, and `Shatterstrike Slam` now feed directly into combat. The `attack` command now rolls a `d20` utilizing the *Shadows of Fate* mechanics and calculates against the entire group of hostiles (*Group Dynamics*).
4. **Interact**: Type `:call s:run('interact [object]')` to investigate and manipulate environmental objects. Consoles can add objectives, levers can expose new exits, portal gates can open surreal side-realms, and special targets can complete missions.
5. **Inventory**: Press `i` to view the relics and artifacts you've scavenged and looted. Type `:call s:run('use [item]')` to consume items.
6. **Profile & Rest**: Press `p` to view your character stats and spells, or `r` to rest and recover HP (warning: resting increases your Surge Count and triggers *Dynamic Spawning*, potentially drawing new enemies to your location).
7. **Undo**: Press `u`, or type `:call s:run('undo')`, to restore exactly one earlier dispatched turn. Undo is intentionally one-deep, so using it twice in a row will report that no earlier turn is available.
8. **State Persistence**: In command mode, type `:call s:run('save')` to serialize your state to `~/.quadar_save.json`. Use `load` to restore.
9. **Ask the Oracle**: Press `a` to consult the Loom of Fate (e.g. "is the door locked?"). The system will roll a `d100`, apply your current Surge Count, and generate an outcome.
10. **Shift Stage**: Press `1` (To Knowledge), `2` (To Conflict), or `3` (To Endings) to alter the oracle's probability matrix based on the scene's tension.
11. **Trade Wares**: Press `t`, or type `:call s:run('shop')`, inside the Merchandise Store Room to inspect wares. Use `buy [ware]` and `sell [item]` to work the Qua'dar trade economy.
12. **Review Objectives**: Press `o`, or type `:call s:run('quests')`, to inspect current mission progress, focus, and completed objectives.
13. **Open Field Notes**: Press `j`, or type `:call s:run('notes')`, to review CRGE-style notecards for scenes, known NPCs, and established thread facts, including which NPCs are tied to each thread.
14. **Frame Scenes**: Use `:call s:run('frame [thread#] [stage]')` to explicitly set the current scene's main thread and stage before play.
15. **Guide the Vignette**: Use `:call s:run('framework')` to inspect the current CRGE vignette card, `framework theme [subject]` to set the chapter question, `framework hook [aspiration]` to store the obscured hook, and `framework next` / `framework phase [name]` to move between Exposition, Rising Action, Climax, and Epilogue.
16. **Set the Accord**: Use `:call s:run('minds')` to inspect the current Meeting of Minds, `minds focus [theme]` to record preferred material, `minds ban [theme]` to set a hard boundary, `minds note [assumption]` to store a social-contract assumption, and `minds rm [focus|ban|note] [idx]` to trim the list.
17. **Direct the Party**: Use `:call s:run('party')` to inspect your companion roster, `party fade [name]` to pull someone out of the main scene, `party send [name] [thread#]` to put them on an elsewhere/sidebar assignment, and `party rally [name]` to bring them back into the action.
18. **Review and Close Scenes**: Use `:call s:run('scene')` to inspect the active scene card, and `:call s:run('fade [summary]')` to record its outcome before pivoting.
19. **Scene NPCs**: Use `:call s:run('npc add [name]')`, `npc rm [name]`, or `npc` to manage who is instantly present in the current scene.
20. **Elsewhere Facts**: Use `:call s:run('aside [thread#] [fact]')` to record sidebar facts against another thread without stealing focus from the active scene.
21. **Manage Threads**: Use `:call s:run('thread')` to inspect the fallout ledger, `thread add [goal]` to open a thread, `thread mod [thread#] [new wording]` to revise it, `thread split [thread#] [new thread]` to branch it, and `thread replace [thread#] [new thread]` when a scene closes out one direction and points to a new one.
22. **Quit**: Press `q` at any time to terminate the Neural Link buffer.
23. **The Abyssal Throne**: Once you've completed all three core objectives (rescue rangers, recover lost tomes, purify altars), examine the Arcane Terminal again. A new `Abyssal Sigil` will bloom in the Merchandise Store Room. `interact Abyssal Sigil` to descend onto the Abyssal Throne and confront the Voidmaw Abyssalgeist in a two-phase duel. Both phases must be defeated; then `interact Throne Sigil` to seal the breach for the epilogue.
24. **Montage**: Use `:call s:run('montage [summary]')` to montage past intervening action -- the command resets the Surge Count, advances the scene index, and stamps a `Montage carry: ...` fact on every active thread.
25. **Unexpected Modifiers**: When `ask` rolls "and unexpectedly", the Table 2 result now actually mutates the world: Limelit zeroes Surge, Entering the Red spawns a hostile, Enter Stage Left adds a roving NPC, the To-X stage modifiers recalibrate the Loom, Foreshadowing/Tying Off rewrite the focus thread's trajectory, Set Change opens a hidden exit, Montage advances the scene index, and Upstaged spikes Surge.

## Architecture
This project follows functional programming principles:
- **RTK-Style Dataflow**: User input is parsed into event-style actions, routed through a root reducer, and applied through a small store/subscription layer in the engine.
- **Immutable State**: Game logic operates on a state dictionary.
- **Pure Views**: The UI is a pure function of the current state.
- **Side-Effect Isolation**: All buffer manipulations are sequestered in the engine layer.
- **Story Bookkeeping**: Scene focus, active objectives, and procedural quest targets (like recovering lost tomes or purifying eldritch altars) are tracked directly in state so exploration can react to narrative progress.
- **Persistent Notecards**: Scene cards, thread facts, known NPCs, and thread-to-NPC links are stored in state so CRGE-style bookkeeping survives past the visible log buffer.
- **Vignette Framework**: Story state now tracks a CRGE chapter theme, obscured hook, and current dramatic phase so scene framing can move through Exposition, Rising Action, Climax, and Epilogue instead of drifting.
- **Meeting of Minds**: Story state now tracks preferred themes, banned themes, and table assumptions so the run can keep a visible social contract instead of relying on memory.
- **Hidden Lore**: Discovering Holographic Terminals or Eldritch Frescoes will dynamically dispense procedural worldbuilding secrets directly into the active thread's fact ledger.
- **Portal Realms**: Veiled gates inside Mysterious Portals, Dimensional Nexus chambers, and Outerworldly Realms can branch the run into alien pocket-zones and back again.
- **Environmental Hazards**: Movement logic parses the procedural biome of the destination (e.g. Toxic Wastes, Mud Slides, Dimensional Nexus) to apply dynamic damage, tension spikes, or navigational warnings.
- **Companions & Group Dynamics**: Rescuing NPCs from the tower allows them to join your party, and only companions still active in the main scene contribute their aggregated `Group Dynamics` bonus to combat rolls.
- **Tapestry Overlay**: Party members can now fade from the scene or be sent elsewhere on another thread, giving the solo MUD a lightweight version of the Familiar's scene-holder / sidebar rhythm.
- **Economy Loop**: Trade cache, wares, salvage, and persistent upgrades now turn recovered relics into concrete progression.
- **Climax Boss**: An Abyssal Throne is procedurally bound to the Merchandise Store Room once the three core quests resolve, anchoring the Voidmaw Abyssalgeist as a multi-phase climactic encounter that ends the vignette.
- **Enemy Archetype Lore**: Combat output now narrates each archetype's signature spell from the Qua'dar appendix (e.g., Storm Titans flash `Thunderous Slam`, Voidwraiths haunt with `Spectral Grasp`).
- **Roving Allies**: Procedural rooms occasionally surface a `Stranded Ranger` (interact to recruit) or a `Nomadic Merchant` (whose presence opens the shop in the wild) so the Familiar's fresh-recruit and traveling-trader rhythms appear during exploration.

## Testing Tenet
- **Strict rule**: Do **not** add seeded determinism, mocks, stubs, fakes, injected outcomes, or snapshot/golden-file workflows as a testing strategy for this project.
- Tests should exercise live play behavior and tolerate naturally dynamic output instead of pinning the game to exact seeded transcripts or mocked rolls.
- When output is volatile, prefer asserting durable gameplay invariants, state transitions, or structural guarantees over forcing the engine into deterministic replay.
- This is a project tenet, not a suggestion.

## License
All rights reserved. © 2026 ForbocAI. See [LICENSE](./LICENSE) for full details.
