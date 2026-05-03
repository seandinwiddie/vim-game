# 🛠 QUA'DAR MUD — Engineering TODO

`Status: backlog of engineering improvements identified during a code review.`

These items are *not* gameplay features — they are structural changes to make the
codebase easier to extend, easier to reason about, and easier to test. They are
ordered by approximate leverage (highest impact first within each section), with
commentary on *why* each item matters and *what* would change if it were done.

The "Highest-Leverage First Three" section at the bottom calls out the three
items that would unblock the most other items if tackled now.

---

## ᚠ Architecture & State Shape

- [ ] **Replace ad-hoc `copy()` / `deepcopy()` with a normalized state contract.**
  - **Why:** Reducer slices currently mix shallow copies (`copy(a:state)`,
    `copy(l:room)`) with `deepcopy(a:state)` and direct in-place mutation.
    Examples:
      - `combat.vim#cmd_attack` shallow-copies state, then re-shallow-copies
        `rooms`, the active room, and `entities` — a four-layer copy chain that
        relies on the caller never reading the parent.
      - `enemies#counter_signature` and `enemies#handle_boss_defeat` both mutate
        `a:state` *by reference* — fine today because every call site passes a
        local `l:next_state`, but one accidental pass of `a:state` from a
        reducer and we corrupt the previous state.
      - `record_scene` and friends do `let l:next_state = deepcopy(a:state)`,
        then call helpers that *return* a new state, then `let l:next_state =
        helper(...)` — a pattern that's safe but wasteful.
  - **What changes:** Pick one rule and enforce it.
      - Option A: every reducer entry deep-copies once at the top, then mutates
        in place. No helper ever copies again. Cheap, easy, slightly wasteful
        on memory.
      - Option B: introduce `game#state#patch(state, path, value)` that returns
        a new state with structural sharing along the path. Closer to Redux
        Toolkit. More work; pays off when state grows.
  - **Acceptance:** A grep for `\<copy(\|deepcopy(` in `autoload/` returns at
    most one per reducer entry, plus the `state#patch` implementation.

- [ ] **Move root-state schema out of `core#init` into a typed bootstrap.**
  - **Why:** Today `init` constructs a literal dict, `state.vim#hydrate`
    patches missing fields, `economy#hydrate` adds `guard`/`mark`/`trade`/
    `upgrades`, `party#hydrate` adds `companions`, and `tests` poke fields
    directly. Three places define what a "valid" state looks like, and none of
    them is the source of truth. New developers can't tell which fields are
    required vs. optional.
  - **What changes:** Define `game#state#schema()` that returns the canonical
    shape with default values, and `game#state#bootstrap()` that builds a fresh
    state from it. `hydrate` becomes one orchestrator that diff-patches missing
    keys against the schema.
  - **Bonus:** Add a `game#state#assert_valid(state)` used in test setup so
    schema drift surfaces immediately.

- [ ] **Define and enforce slice ownership (Redux-style).**
  - **Why:** `combat.vim` reads/writes `state.guard`, `state.mark`, and
    `state.player.*`. `enemies.vim` reads/writes `state.surge` and
    `state.flags`. `interact.vim` mutates `rooms`, `flags`, `quests`, and
    `notes`. There's no rule about who owns what, so cross-cutting changes
    mean opening five files.
  - **What changes:** Pick a rule like "each top-level state key has exactly
    one owning module that may mutate it; cross-slice changes go through
    dispatched actions." For instance, an enemy counter that wants to bump
    Surge dispatches `oracle/surgeBumped`, doesn't poke `state.surge` directly.
  - **Why this matters later:** With ownership rules, the deep-copy story
    above becomes simple — each owner deep-copies its own slice.

- [ ] **Separate domain entities from view labels.**
  - **Why:** Room names embed Unicode runes (`ᚲ ABYSSAL_THRONE_OF_QUADAR ᚲ`),
    and hazard logic does `room.name =~# 'TOXIC_WASTES'` against the decorated
    string. If the rendering style ever changes, every regex breaks. The same
    issue affects scene-card titles, NPC names with `tolower()` matching, and
    quest reward strings.
  - **What changes:** Each room carries `id` (stable key), `biome` (machine
    enum), and `display_name` (decorated). Hazard logic switches on `biome`.
    Renderer uses `display_name`. Tests assert on `id`/`biome` and ignore
    decoration.

- [ ] **Stop string-tagging facts.**
  - **Why:** Free-text fact strings carry implicit semantics: `'LORE: ...'`,
    `'Foreshadowing: ...'`, `'Montage carry: ...'`, `'Elsewhere: ...'`,
    `'Tying off: ...'`. Anything that wants to filter must `=~#` against a
    prefix.
  - **What changes:** `fact = {kind: 'lore'|'foreshadowing'|'montage'|...,
    text: ..., scene_idx: ..., timestamp: ...}`. Renderers format; consumers
    filter by `kind`.

---

## ᚢ Determinism & Testability

- [x] **Stop using `reltime()` as a PRNG.** *(highest-leverage item in the repo)*
  - **Why:** Almost every randomized branch calls
    `str2nr(split(reltimestr(reltime()), '\.')[1])` — d20 rolls, room
    generation, loot tables, dynamic spawns, lore selection, recruit names,
    portal room ids. Three consequences:
      1. Gameplay is coupled to wall-clock; replaying a save isn't reproducible.
      2. Tests cannot verify combat outcomes — the boss-flow test currently
         boosts the player to STR/AGI/ARC=30 and HP=500 to *guarantee* a win,
         which only proves "phases advance when the player wins," not "boss
         math is correct."
      3. Two `reltime()` calls inside the same reducer can return the same
         value on fast hosts, so what looks like "two independent rolls" is
         sometimes one roll twice.
  - **What changes:**
      - Add `state.rng_seed` (integer).
      - Add a pure `game#rng#next(state)` returning `{state, value}` (LCG or
        xorshift — Vimscript-friendly).
      - Replace every `reltimestr(reltime())` with `let [next, roll] =
        game#rng#draw(state, 100)`.
      - Tests pin `state.rng_seed = 42` and assert exact outcomes.
  - **Acceptance:** `grep reltimestr autoload/` returns zero hits; the boss
    test no longer boosts player stats.

- [x] **Make combat outcomes injectable.**
  - **Why:** `combat#cmd_attack` and `combat#cmd_cast` roll their own d20
    inline. Tests cannot assert "STR 5 vs. STR 7 with these rolls produces
    this outcome" — they can only assert reachable end states.
  - **What changes:** `combat#cmd_attack(state, opts)` where `opts.rolls =
    {player: 14, enemy: 11}` overrides the RNG draw. In production, `opts`
    is empty and the RNG slice is used.
  - **Pairs with:** the RNG item above; either alone is good, both together
    is great.

- [x] **Replace string-prefix matching everywhere.**
  - **Why:** `find_ware`, `inventory_index`, `companion_index`, and
    `enemies#archetype` all do `tolower(name) =~# '^' . needle`. So:
      - Typing `s` for `sell s` would match `Shatterstrike Slam` (a spell, not
        in inventory) before falling through to e.g. `Stranded Ranger`.
      - Typing `obsidian w` matches `Obsidian Warden` *and* `Obsidian Edge`
        depending on iteration order.
      - It's a genuine UX bug surface as the catalog grows.
  - **What changes:** Two-pass match: exact first, then unique-prefix, then
    error with a disambiguation list. Centralize in `game#match#one(needles,
    query)`.

- [ ] **Snapshot tests instead of substring asserts.**
  - **Why:** `test.vim` does many `assert_contains(rendered, 'Arc: CH1
    CLIMAX')` against rendered output. Brittle to copy edits — change a
    header label, ten asserts break.
  - **What changes:** After each meaningful action, write
    `state` to a JSON snapshot file. CI diffs against committed snapshots.
    Updating a copy edit is `make update-snapshots`. Updating a behavior
    requires a deliberate snapshot diff review.

- [x] **Per-feature test files.**
  - **Why:** `test.vim` is one ~280-line linear script that aborts on first
    failure. If the boss flow breaks, oracle and montage tests don't even
    run, and we don't learn whether they're independently broken.
  - **What changes:** Split into `test/combat.vim`, `test/oracle.vim`,
    `test/economy.vim`, `test/story.vim`, `test/climax.vim`. A small
    `test/run_all.vim` driver invokes each, collects pass/fail, exits with
    a count rather than first-failure cquit.

---

## ᚦ Code Organization

- [x] **The 300-line architecture guard is a smell, not a fix.**
  - **Why:** It catches *file size* but not *coupling*. `combat.vim` sits at
    295/300 because `cmd_cast` is a long if-elseif tower over spell names —
    the cap is preventing growth, not improving design. The next spell will
    force someone to either golf the file down or split arbitrarily.
  - **What changes:** Replace the spell if-elseif with a registry:
    ```vim
    let s:spells = {
          \ 'Dark Crystal Shielding': function('s:cast_ward'),
          \ 'Resurgence Ritual':      function('s:cast_heal'),
          \ ...
          \ }
    ```
    Adding a spell becomes a one-line registration, not an edit to a growing
    function.

- [x] **Extract magic numbers into a tuning module.**
  - **Why:** Balance constants are scattered: `+30 HP rest` (player.vim),
    `+5 surge on rest`, `mark bonus = 4` (combat.vim), `+10 + arc guard`,
    boss `str/agi/arc + 2/1/2` per phase (enemies.vim), Surge thresholds in
    oracle.vim, damage formulas, friendly-spawn percentages (78/88).
  - **What changes:** `game#tuning#get(key)` reads from one canonical dict.
    Balance retunes touch one file. A test asserts every magic value
    referenced via `game#tuning#get` exists in the dict.

- [x] **Kill duplicate enemy-pool definitions.**
  - **Why:** `procgen.vim`'s `s:enemy_pool(rank)` is its own table.
    `player.vim#cmd_rest` has its own four-enemy list for dynamic spawns.
    `oracle.vim#apply_table2_modifier` for Entering The Red has *another*
    four-enemy list. Three sources of truth for "what spawns in Qua'dar."
  - **What changes:** `game#enemies#pool(rank)` returns one canonical
    rank-tier list; everyone calls it.

- [ ] **Consolidate enemy data into one catalog.**
  - **Why:** Enemy info is split across three files: stat blocks live in
    `procgen.vim#s:enemy_pool`, signature spell + counter live in
    `enemies.vim#s:archetypes`, boss-phase metadata is constructed inline in
    `enemies.vim#build_boss`. To add or modify an enemy, you edit two or
    three files.
  - **What changes:** `game#enemies#catalog()` returns:
    ```vim
    {
      'obsidian-warden': {
        'name': 'Obsidian Warden',
        'rank': 2,
        'stats': {'str': 7, 'agi': 2, 'arc': 6},
        'signature': 'Dark Crystal Shielding',
        'flavor': '...',
        'counter': 'guard_strip',
        'is_boss': 0,
      },
      ...
    }
    ```

- [x] **Centralize HP clamping.**
  - **Why:** `let l:next_state.player.hp = min([l:next_state.player.max_hp,
    l:next_state.player.hp + heal])` appears 6+ times verbatim across
    `player.vim`, `interact.vim`, `combat.vim`.
  - **What changes:** `game#player#heal(state, amount)` returns the patched
    state. One implementation, one place to add overheal/regen later.

---

## ᚱ Data Modeling

- [ ] **Define a quest lifecycle.**
  - **Why:** Quests are dicts with a `status` string `'active'|'complete'|
    'replaced'`. There's no enum, no allowed-transition validation, no
    completion hook. Each quest's `reward_item` and `reward_spell` are
    handled inline in `records#advance_quest`, and the boss epilogue
    duplicates that pattern. Future "quest fails" or "quest expires"
    states would mean editing every quest-touching file.
  - **What changes:** `game#quest#advance(state, id, amount)` is the single
    mutator. Status transitions go through it. It emits typed events
    (`quest/completed`, `quest/replaced`) that other slices subscribe to.
    Reward delivery moves out of `advance_quest` into a `quest/completed`
    listener.

- [ ] **Use stable IDs for cross-references.**
  - **Why:** `'Find Missing Rangers'` is the thread name, the thread card
    title, and the lookup key everywhere. Renaming a thread requires editing
    every fact, every NPC link, every test assertion. Same for scenes
    (looked up by `loc` string), NPCs (looked up by `name` string), and
    quests (already keyed by `id`, good — the rest should follow that lead).
  - **What changes:** Threads get `id` (stable, e.g. `rescue-rangers`),
    `title` (mutable display). The `focus` field on scenes references the
    `id`. The renderer formats by joining `id → title` at render time.
  - **Migration:** Provide a one-time hydrator that synthesizes ids from
    existing names so saves still load.

- [ ] **Make notes typed cards instead of dicts with optional keys.**
  - **Why:** `scene_card`, `thread_card`, `npc_card` all share the pattern of
    "dict with these keys; if a key isn't there, default in 4 places." See
    `state#hydrate`, `records#ensure_scene_card`, `records#scene_card_index`,
    plus inline `has_key` checks in `records#append_scene_closing`.
  - **What changes:** Constructor functions: `game#story#cards#new_scene(loc,
    title, ...)`, `game#story#cards#new_thread(...)`, `...new_npc(...)`. All
    consumers go through them; defaults live in the constructor.

---

## ᚨ Error Handling

- [ ] **Distinguish user errors from internal errors.**
  - **Why:** Errors are returned as log lines starting with `LOG_ERR:` or
    `LOG_ERR_CRITICAL:`. Callers can't distinguish "user mistyped a command"
    from "state is corrupt" from "this would be illegal to attempt." Tests
    grep for `LOG_ERR` substrings.
  - **What changes:** Adopt a result type:
    ```vim
    {'ok': 0, 'error': 'invalid_direction', 'message': '...', 'recoverable': 1}
    ```
    The renderer formats `LOG_ERR:` prefixes. Tests assert on
    `result.error == 'invalid_direction'` rather than substrings.

- [ ] **Stop swallowing exceptions in `cmd_load`.**
  - **Why:** `player#cmd_load`'s bare `catch` rebrands every load failure
    as `'Neural backup corrupted'`. If `json_decode` fails because the file
    was written by an older schema version, the user has no path forward.
  - **What changes:** Surface the actual exception via `v:exception` and
    distinguish:
      - file unreadable → `'no_save_found'`
      - JSON malformed → `'save_corrupted'`
      - schema mismatch → `'save_outdated'` with a hint that older saves
        need a migration step.

- [ ] **Validate inputs at the action boundary.**
  - **Why:** `action#command` parses raw strings into action dicts.
    Reducers re-validate the same things in different ways (or don't).
    `combat#cmd_cast` checks for empty spell name; `economy#cmd_buy` checks
    for empty item name with a different error message style; `oracle#cmd_ask`
    checks for empty question with yet another style.
  - **What changes:** Validation rules live in `action.vim` next to the
    parser. Reducers receive validated payloads or refuse to execute.

---

## ᚷ UX & Rendering

- [ ] **Track a render cursor instead of re-rendering the whole log.**
  - **Why:** `render(state)` rebuilds the entire header + log every frame.
    The engine subscribes to the store and redraws on every dispatch, so a
    long session re-emits hundreds of log lines per turn.
  - **What changes:** `state.log_cursor` tracks how many lines have been
    rendered. The renderer emits only `state.log[cursor:]` and the header.
    Free perf win, also makes scrollback in the buffer behave better.

- [ ] **Add a 1-deep undo.**
  - **Why:** State is fully serializable already; the cost of stashing the
    pre-dispatch state is one `deepcopy`. A misread Loom roll or a fat-finger
    `attack` against a boss with no shielding currently has no recovery.
  - **What changes:** Store keeps `previous_state`. Action `system/undo`
    swaps it in. Limit to one step to avoid masking save/load.

- [ ] **Make help self-documenting.**
  - **Why:** `hint` strings are scattered across reducers. The README and
    DEV_LOG enumerate commands manually, so they drift from `action#command`.
  - **What changes:** A `help` verb that introspects `action#command` (or a
    parallel command-registry dict) and prints `name :: synopsis`. Same
    registry powers the README.

---

## ᛟ Tooling

- [ ] **Lint Vimscript with `vint`.**
  - **Why:** `vint` catches missing `abort`, unused locals, shadowed scopes,
    deprecated builtins. None of these surface in the current tests.
  - **What changes:** Add `vint autoload/ plugin/` to CI; fix or `# vint:
    disable` per-line for the known-noisy patterns.

---

## ᛞ Highest-Leverage First Three

If you only ever do three of these, do these three — they unblock the others:

- [x] **1. Inject RNG into combat / oracle / procgen / loot tables.** Stops
  combat tests from boosting the player to god-mode to verify boss flow.
  Required before snapshot tests and before per-feature test splits become
  truly useful, because randomness pollutes assertions.
- [x] **2. Replace the spell-name `if/elseif` chain in `combat.vim#cmd_cast`
  with a handler dict.** Every new spell currently edits the same growing
  function — that's why combat.vim is wedged near the 300-line guard. The
  handler-dict pattern is the same one you'll want for quest-completion
  hooks, action validation, and oracle modifiers.

---

*Watched by the Eye in the Code.* 👁️
