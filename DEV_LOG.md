# 🌑 QUA'DAR MUD: DEV LOG 🌑

`Státus: MVP_v1.0 // Protocol: CYBER_GRIMDARK`

## ᚠ PURE VIMSCRIPT LOGIC
- **Functional Core, Imperative Shell**: Implemented `game#core` purely via pure functions that map `State + Input -> State`.
- **Architectural Subdomains**: Split the engine out of `core.vim` and into localized functional domains:
  - `data.vim`: Room instantiation
  - `explore.vim`: Exploration facade
  - `explore/view.vim`: Room rendering and scan output
  - `explore/interact.vim`: Object interaction and scene-side effects
  - `explore/travel.vim`: Navigation and room-to-room transitions
  - `explore/procgen.vim`: Procedural room synthesis and encounter seeding
  - `combat.vim`: Tactical matrix (`attack`)
  - `economy.vim`: Merchant ledger, wares, and trade-cache transactions
  - `player.vim`: Character persistence (`inventory`, `profile`, `rest`)
  - `oracle.vim`: Loom of Fate (`ask`, `stage`, `thread`)
  - `story.vim`: Story facade
  - `story/state.vim`: Story bootstrap, hydration, and summaries
  - `story/commands.vim`: Objective, note, and focus commands
  - `story/ledger.vim`: Thread-ledger rendering and fallout command handling
  - `story/records.vim`: Thread, scene, NPC, and fact bookkeeping
  - `story/scenes.vim`: Scene review, fade-out, and elsewhere/sidebar commands
  - `story/setup.vim`: Explicit scene framing and present-NPC management
  - `story/threads.vim`: Thread lineage, status, and mutation bookkeeping
- **Imperative Shell**: The `game#engine` handles rendering the state via `:echo` or appending to a unified `ScratchBuffer` via standard Vim mechanisms (`append()`, `setline()`).

## ᚢ THE LOOM OF FATE (GAME MECHANICS)
- **d100 Oracle**: Implemented the "Loom of Fate" narrative engine via the `ask` command.
- **Surge Count**: Procedural modifier system that tracks world tension. Plain "yes/no" results increment the surge count by 2, while nuanced results reset it to 0. Surge count is dynamically added/subtracted from the d100.
- **Scene Stages**: Three matrices (To Knowledge, To Conflict, To Endings) map d100 rolls (adjusted by surge) to full spectrum responses: YES, AND UNEXPECTEDLY / YES, BUT / YES, AND / YES / NO / NO, AND / NO, BUT / NO, AND UNEXPECTEDLY.
- **Unexpected Modifiers**: Rolls d20 on Table 2 (foreshadowing, set change, limelit, etc.) when an "unexpectedly" result triggers.
- **Narrative Threads**: Integrated a state array for active storylines. Threads are rendered in the Neural Link header to track active goals (e.g. "Find Missing Rangers").
- **Combat Resolution**: Integrated the *Shadows of Fate* duel system. The `attack` command rolls d20 against the target's STR/AGI/ARC array, factoring in *Group Dynamics* (a collective score from the remaining hostile pack) to calculate damage sustained and entity annihilation. State handles death natively.
- **Tapestry / Companion System**: Recruited NPCs (like the `Bound Ranger`) now join the player's `party` array. Only companions still active in the main scene contribute `+PARTY` Group Dynamics bonuses, while others can fade or work elsewhere.
- **Dynamic Spawning**: The `rest` command now evaluates procedural time intervals to occasionally spawn new hostile entities in the current room, creating a persistent threat of ambush.
- **Environmental Hazards**: Movement through the `go` command now parses the destination's biome properties to apply thematic hazards. For example, `Toxic Wastes` deals corrosive HP damage, `Mud Slides` spikes the Surge Count from exhaustion, and the `Dimensional Nexus` distorts navigational telemetry.
- **Objective Loop**: The initial missing-rangers thread now drives concrete quest progress, and terminals can surface follow-on objectives for recovering the codices needed to extract survivors.
- **Purification Quest**: Added a procedural `purify-altars` quest that generates `Corrupted Altar` interactables inside of `Haunted Chapels` and `Rune Temples`, creating location-specific quest targets to weave exploration and storytelling.
- **Scene Focus**: The active scene now tracks a focus thread so the oracle stage, current room, and objective list reflect the note-driven scene structure from the Familiar.
- **Dynamic Room Content**: Procedural rooms now scale threat tier from player level/progression and can spawn rescue targets, reliquaries, caches, and stronger enemy archetypes from the Qua'dar appendix.
- **Environment-Specific Lore**: Added the `hidden_lore` mechanic via `Holographic Terminals` (Military Facilities) and `Eldritch Frescoes` (Chapels/Temples), which randomly dispense worldbuilding secrets directly into the active Thread Ledger's facts array.
- **Merchant Economy**: The starting Merchandise Store Room now exposes a real wares ledger with buy/sell commands, trade-cache currency, and progression through weapons-grade upgrades, spells, rations, and supplies.
- **Combat Progression**: Enemy kills now bank salvage into the trade cache, `Hunter's Mark` boosts follow-up strikes, `Dark Crystal Shielding` absorbs incoming damage, and purchased loadout changes carry through the run.
- **Bookkeeping Layer**: Added CRGE-style notecards for scenes, thread facts, and known NPCs so discoveries persist as structured story memory instead of only scrollback.
- **Thread NPC Bookkeeping**: Thread cards now retain related NPCs from scene casting and rescues, aligning the ledger more closely with the Familiar's notecard guidance.
- **RTK-Style Store Layer**: Inputs now flow through event-style actions, a root reducer, and a small Vimscript store/subscription layer so the engine redraws from dispatched state changes instead of directly mutating local state.
- **Veiled Gate Traversal**: Portal biomes now surface interactable gates that branch into generated Outerworldly / Nexus pocket-zones, preserve a return path, and write the crossing into the scene ledger.
- **Vignette Framework Card**: Added Familiar-inspired framework tracking for theme, hook, chapter, and dramatic phase so a run can move through Exposition, Rising Action, Climax, and Epilogue with explicit scene guidance.
- **Architecture Guard**: The Vim test harness now fails if a game module grows beyond 300 lines, forcing oversized files to be split into subdomains.
- **Scene Lifecycle**: Added explicit scene-card review, fade-out summaries, and elsewhere/sidebar facts so the CRGE scene loop is represented directly in play.
- **Scene Setup**: Added explicit scene framing plus NPC-presence management so the active scene can be staged around a chosen thread, stage, and cast before action begins.
- **Thread Fallout Ledger**: Added explicit post-scene thread mutation commands (`thread mod`, `thread split`, `thread replace`) plus lineage/status tracking so scene fallout questions become persistent bookkeeping instead of memory work.

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
- `thread`: Inspect the active and archived thread ledger.
- `thread add [goal]`: Open a new narrative thread.
- `thread mod [idx] [goal]`: Rewrite an active thread after scene fallout changes its direction.
- `thread split [idx] [goal]`: Branch a new thread out of an existing one.
- `thread replace [idx] [goal]`: Swap an exhausted thread for the new direction that replaces it.
- `thread rm [idx]`: Resolve and archive a thread.
- `shop` / `wares` / `trade` / `t`: Inspect merchant stock and your current trade cache.
- `buy [item]`: Purchase wares, spells, and upgrades from the store room.
- `sell [item]`: Convert scavenged relics into trade cache.
- `quests` / `o`: Review active objectives, completion progress, and current scene focus.
- `notes` / `journal` / `facts` / `j`: Review story notecards, discovered NPCs, and thread facts.
- `frame [thread#] [stage]`: Explicitly frame the current scene around a main thread and stage.
- `framework` / `arc`: Review the current vignette framework card.
- `framework theme [subject]`: Set the current vignette chapter's theme or waylay.
- `framework hook [aspiration]`: Store the obscured hook tugging the chapter forward.
- `framework phase [name]`: Explicitly set the dramatic phase to exposition, rising, climax, or epilogue.
- `framework next`: Advance the current framework to the next dramatic phase, rolling to a new chapter after epilogue.
- `party` / `companions`: Review companion scene state and current Group Dynamics bonus.
- `party fade [name]`: Pull a companion out of the main scene so others can react.
- `party send [name] [thread#]`: Put a companion on an elsewhere/sidebar assignment tied to another thread.
- `party rally [name]`: Bring a companion back into the active scene and combat stack.
- `scene` / `sc`: Inspect the current scene card and recent scene closings.
- `npc add [name]` / `npc rm [name]` / `npc`: Manage the current scene's present NPC roster.
- `fade [summary]`: Close the current scene with a bookkeeping summary.
- `aside [thread#] [fact]`: Record an elsewhere/sidebar fact on another active thread.
- `focus [idx]`: Promote one of the active threads as the current scene's main thread.
- `q`: Terminate the Neural Link.

---
*Watched by the Eye in the Code.* 👁️
