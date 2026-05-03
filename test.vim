set nocompatible
execute 'set runtimepath^=' . fnameescape(getcwd())

let s:state = game#core#init()

function! s:assert_subdomain_limits() abort
  let l:violations = []
  for l:file in sort(globpath('autoload/game', '**/*.vim', 0, 1))
    let l:line_count = len(readfile(l:file))
    if l:line_count > 300
      call add(l:violations, l:file . ' :: ' . l:line_count . ' lines')
    endif
  endfor

  if !empty(l:violations)
    call writefile(['ARCHITECTURE_GUARD_FAILURE: Split oversized modules into subdomains.'] + map(copy(l:violations), '" - " . v:val'), 'test_output.txt', 'a')
    cquit 1
  endif
endfunction

call writefile(['--- START TESTS ---'], 'test_output.txt')
call s:assert_subdomain_limits()

let s:state.player.trade = 100
let s:state = game#core#process(s:state, 'shop')
let s:state = game#core#process(s:state, 'buy Dark Crystal Shielding')
let s:state = game#core#process(s:state, "buy Hunter's Mark")
let s:state = game#core#process(s:state, 'buy Zinc Weave Cloak')
let s:state = game#core#process(s:state, 'buy Explosive Barrage')
let s:state = game#core#process(s:state, 'buy Shatterstrike Slam')
call add(s:state.player.inv, 'Gibsonian Shard')
let s:state = game#core#process(s:state, 'sell Gibsonian Shard')
let s:state = game#core#process(s:state, 'frame 1 conflict')
let s:state = game#core#process(s:state, 'framework theme learn why the tower is hollowing out recruits')
let s:state = game#core#process(s:state, 'framework hook meet the architect behind the disappearances')
let s:state = game#core#process(s:state, 'framework next')
let s:state = game#core#process(s:state, 'framework')
let s:state = game#core#process(s:state, 'minds focus survivor rescue and uncanny revelation')
let s:state = game#core#process(s:state, 'minds ban gratuitous cruelty toward rescued rangers')
let s:state = game#core#process(s:state, 'minds note defeats should become costly consequences instead of abrupt death')
let s:state = game#core#process(s:state, 'minds')
let s:state = game#core#process(s:state, 'npc add Iron Broker')
let s:state = game#core#process(s:state, 'npc')
let s:state = game#core#process(s:state, 'quests')
let s:state = game#core#process(s:state, 'notes')
let s:state = game#core#process(s:state, 'scene')
let s:state = game#core#process(s:state, 'look')
let s:state = game#core#process(s:state, 'interact Arcane Terminal')
let s:state = game#core#process(s:state, 'frame 2 knowledge')
let s:state = game#core#process(s:state, 'aside 1 Another recon team was seen near the tower shell')
let s:state.rooms[s:state.loc].objects = [
      \ {'name': 'Bound Ranger', 'desc': 'A shackled recruit calls for extraction.', 'effect': 'rescue_ranger', 'quest_id': 'rescue-rangers'},
      \ {'name': 'Sealed Reliquary', 'desc': 'An archive reliquary full of return codices.', 'effect': 'recover_tome', 'quest_id': 'recover-lost-tomes'}
      \ ]
let s:state = game#core#process(s:state, 'interact Bound Ranger')
let s:state = game#core#process(s:state, 'party')
let s:state = game#core#process(s:state, 'party fade ranger operative')
let s:state = game#core#process(s:state, 'party send ranger operative 1')
let s:state = game#core#process(s:state, 'party rally ranger operative')
let s:state = game#core#process(s:state, 'interact Sealed Reliquary')
let s:state = game#core#process(s:state, 'quests')
let s:state = game#core#process(s:state, 'cast Dark Crystal Shielding')
let s:state = game#core#process(s:state, 'go north')
let s:state = game#core#process(s:state, "cast Hunter's Mark")
let s:state = game#core#process(s:state, 'cast Explosive Barrage')
let s:state = game#core#process(s:state, 'cast Shatterstrike Slam')
let s:state = game#core#process(s:state, 'framework phase climax')
let s:state = game#core#process(s:state, 'fade Ashwalker resistance confirms the spire approach is still contested')
let s:state = game#core#process(s:state, 'thread split 1 Track the tower shell recon cell')
let s:state = game#core#process(s:state, 'thread replace 2 Decode the return codex relay')
let s:state = game#core#process(s:state, 'thread mod 3 Secure the tower shell extraction route')
let s:state = game#core#process(s:state, 'thread')

let s:state.rooms['test_wastes'] = {'name': 'ᚲ TOXIC_WASTES ᚲ', 'desc': 'A ghastly mire of desolation.', 'exits': {'west': s:state.loc}, 'entities': [], 'objects': []}
let s:state.rooms[s:state.loc].exits['east'] = 'test_wastes'
let s:state = game#core#process(s:state, 'go east')

let s:state.rooms['test_chapel'] = {
      \ 'name': 'ᚲ HAUNTED_CHAPEL ᚲ', 
      \ 'desc': 'An accursed chapel.',
      \ 'exits': {'north': s:state.loc}, 
      \ 'entities': [], 
      \ 'objects': [{'name': 'Corrupted Altar', 'desc': 'A desecrated monolith.', 'effect': 'purify_altar', 'quest_id': 'purify-altars'}]
      \ }
let s:state.rooms[s:state.loc].exits['south'] = 'test_chapel'
let s:state = game#core#process(s:state, 'go south')
let s:state = game#core#process(s:state, 'interact Corrupted Altar')

let s:state.rooms['test_mil'] = {
      \ 'name': 'ᚲ MILITARY_FACILITY ᚲ', 
      \ 'desc': 'Ancient military bastion.',
      \ 'exits': {'north': s:state.loc}, 
      \ 'entities': [], 
      \ 'objects': [{'name': 'Holographic Terminal', 'desc': 'A distorted projection.', 'effect': 'hidden_lore'}]
      \ }
let s:state.rooms[s:state.loc].exits['west'] = 'test_mil'
let s:state = game#core#process(s:state, 'go west')
let s:state = game#core#process(s:state, 'interact Holographic Terminal')

let s:state.rooms['test_portal'] = {
      \ 'name': 'ᚲ MYSTERIOUS_PORTAL ᚲ',
      \ 'desc': 'A thin alien threshold trembles here.',
      \ 'exits': {'east': s:state.loc},
      \ 'entities': [],
      \ 'objects': [{'name': 'Veiled Gate', 'desc': 'A veiled gate shivering with impossible geometry.', 'effect': 'portal_jump'}]
      \ }
let s:state.rooms[s:state.loc].exits['south'] = 'test_portal'
let s:state = game#core#process(s:state, 'go south')
let s:state = game#core#process(s:state, 'interact Veiled Gate')

let s:state = game#core#process(s:state, 'inventory')
let s:state = game#core#process(s:state, 'profile')
let s:state = game#core#process(s:state, 'notes')

function! s:assert_true(condition, message) abort
  if !a:condition
    call writefile(['ASSERTION FAILURE: ' . a:message], 'test_output.txt', 'a')
    cquit 1
  endif
endfunction

function! s:assert_contains(lines, needle) abort
  call s:assert_true(stridx(join(a:lines, "\n"), a:needle) >= 0, 'Missing expected text: ' . a:needle)
endfunction

function! s:assert_file_contains(path, needle, message) abort
  call s:assert_true(filereadable(a:path), 'Missing required file: ' . a:path)
  call s:assert_true(stridx(join(readfile(a:path), "\n"), a:needle) >= 0, a:message)
endfunction

function! s:assert_file_not_contains(path, needle, message) abort
  call s:assert_true(filereadable(a:path), 'Missing required file: ' . a:path)
  call s:assert_true(stridx(join(readfile(a:path), "\n"), a:needle) == -1, a:message)
endfunction

function! s:assert_tuning_key_exists(key) abort
  try
    call game#tuning#get(a:key)
  catch
    call s:assert_true(0, 'Missing tuning key: ' . a:key)
  endtry
endfunction

function! s:count_state_change(_state) abort
  let s:store_notifications += 1
endfunction

let s:action_file = expand('autoload/game/action.vim')
let s:combat_file = expand('autoload/game/combat.vim')
let s:combat_spells_file = expand('autoload/game/combat/spells.vim')
let s:enemies_file = expand('autoload/game/enemies.vim')
let s:procgen_file = expand('autoload/game/explore/procgen.vim')
let s:oracle_file = expand('autoload/game/oracle.vim')
let s:match_file = expand('autoload/game/match.vim')
let s:store_file = expand('autoload/game/store.vim')
let s:reducer_file = expand('autoload/game/reducer.vim')
let s:engine_file = expand('autoload/game/engine.vim')
let s:core_file = expand('autoload/game/core.vim')
let s:rng_file = expand('autoload/game/rng.vim')
let s:tuning_file = expand('autoload/game/tuning.vim')
let s:framework_file = expand('autoload/game/story/framework.vim')
let s:meeting_file = expand('autoload/game/story/meeting.vim')
let s:party_file = expand('autoload/game/party.vim')
let s:player_file = expand('autoload/game/player.vim')
let s:economy_file = expand('autoload/game/economy.vim')
let s:interact_file = expand('autoload/game/explore/interact.vim')

call s:assert_file_contains(s:action_file, 'function! game#action#make', 'action.vim must define the action factory.')
call s:assert_file_contains(s:action_file, 'function! game#action#command', 'action.vim must define the command-to-action mapper.')
call s:assert_file_contains(s:action_file, 'explore/travelRequested', 'action.vim must centralize event-style action types.')
call s:assert_file_contains(s:action_file, 'story/frameworkRequested', 'action.vim must route framework commands through typed story actions.')
call s:assert_file_contains(s:action_file, 'story/meetingRequested', 'action.vim must route Meeting of Minds commands through typed story actions.')
call s:assert_file_contains(s:action_file, 'party/commandRequested', 'action.vim must route party commands through typed actions.')
call s:assert_file_not_contains(s:action_file, '/set', 'action.vim should use event-style action names instead of setter-style names.')

call s:assert_file_contains(s:store_file, 'function! game#store#create', 'store.vim must define create().')
call s:assert_file_contains(s:store_file, 'function! game#store#dispatch(', 'store.vim must define dispatch().')
call s:assert_file_contains(s:store_file, 'function! game#store#dispatch_batch', 'store.vim must define dispatch_batch().')
call s:assert_file_contains(s:store_file, 'function! game#store#subscribe', 'store.vim must define subscribe().')
call s:assert_file_contains(s:store_file, 'game#reducer#reduce', 'store.vim dispatch must route through the reducer.')

call s:assert_file_contains(s:match_file, 'function! game#match#one', 'match.vim must expose the shared exact/unique-prefix matcher.')
call s:assert_file_contains(s:combat_file, 'function! game#combat#cmd_attack(state, ...) abort', 'combat.vim should expose optional attack roll injection for tests.')
call s:assert_file_contains(s:combat_file, 'function! game#combat#cmd_cast(state, spell_name, ...) abort', 'combat.vim should expose optional cast roll injection for tests.')
call s:assert_file_contains(s:combat_file, "get(a:opts, 'rolls', {})", 'combat.vim should honor injected combat rolls when provided.')
call s:assert_file_contains(s:combat_file, 'game#combat#spells#match(', 'combat.vim should route spell-name lookup through the shared matcher flow.')
call s:assert_file_contains(s:combat_file, 'game#combat#spells#cast', 'combat.vim should delegate spell execution through the spell registry.')
call s:assert_file_not_contains(s:combat_file, "elseif l:matched_spell ==#", 'combat.vim should not keep inline spell-name handler chains.')
call s:assert_file_contains(s:combat_spells_file, 'function! game#combat#spells#match(', 'combat/spells.vim must expose structured spell matching via the shared matcher.')
call s:assert_file_contains(s:combat_spells_file, 'function! game#combat#spells#get', 'combat/spells.vim must expose the spell registry lookup.')
call s:assert_file_contains(s:combat_spells_file, 'function! game#combat#spells#cast', 'combat/spells.vim must expose the spell dispatcher.')
call s:assert_file_contains(s:combat_spells_file, "get(a:ctx, 'opts', {})", 'combat/spells.vim should honor injected spell rolls when provided.')
call s:assert_file_contains(s:enemies_file, 'function! game#enemies#pool', 'enemies.vim must expose the canonical enemy pool helper.')
call s:assert_file_contains(s:enemies_file, 'function! game#enemies#select', 'enemies.vim must expose a canonical enemy selection helper.')
call s:assert_file_contains(s:enemies_file, 'game#match#one(', 'enemies.vim should route archetype lookup through the shared matcher.')
call s:assert_file_contains(s:procgen_file, 'game#enemies#pool(', 'procgen.vim should source encounter pools from enemies.vim.')
call s:assert_file_not_contains(s:procgen_file, 'function! s:enemy_pool', 'procgen.vim should not keep a duplicate enemy-pool definition.')
call s:assert_file_contains(s:player_file, 'game#enemies#select(', 'player.vim should source dynamic rest spawns from the canonical enemy catalog.')
call s:assert_file_contains(s:oracle_file, 'game#enemies#select(', 'oracle.vim should source Entering the Red spawns from the canonical enemy catalog.')
call s:assert_file_contains(s:player_file, 'game#match#one(', 'player.vim should route item-name lookup through the shared matcher.')
call s:assert_file_contains(s:economy_file, 'game#match#one(', 'economy.vim should route ware and inventory lookup through the shared matcher.')
call s:assert_file_contains(s:party_file, 'game#match#one(', 'party.vim should route companion lookup through the shared matcher.')
call s:assert_file_contains(s:interact_file, 'game#match#one(', 'interact.vim should route object lookup through the shared matcher.')
call s:assert_file_contains(s:tuning_file, 'function! game#tuning#get', 'tuning.vim must expose the canonical tuning lookup.')
call s:assert_file_contains(s:combat_file, 'game#tuning#get(', 'combat.vim should source combat balance numbers from tuning.vim.')
call s:assert_file_contains(s:combat_spells_file, 'game#tuning#get(', 'combat/spells.vim should source spell balance numbers from tuning.vim.')
call s:assert_file_contains(s:player_file, 'game#tuning#get(', 'player.vim should source consumable and rest balance numbers from tuning.vim.')
call s:assert_file_contains(s:oracle_file, 'game#tuning#get(', 'oracle.vim should source oracle balance numbers from tuning.vim.')
call s:assert_file_contains(s:enemies_file, 'game#tuning#get(', 'enemies.vim should source boss balance numbers from tuning.vim.')
call s:assert_file_contains(s:procgen_file, 'game#tuning#get(', 'procgen.vim should source friendly spawn thresholds from tuning.vim.')
call s:assert_file_contains(s:player_file, 'function! game#player#heal', 'player.vim must expose a shared HP clamp helper.')
call s:assert_file_contains(s:combat_spells_file, 'game#player#heal(', 'combat/spells.vim should route healing spells through the shared HP helper.')
call s:assert_file_contains(s:economy_file, 'game#player#heal(', 'economy.vim should route HP-restoring upgrades through the shared HP helper.')
call s:assert_file_contains(s:interact_file, 'game#player#heal(', 'interact.vim should route healing interactions through the shared HP helper.')
call s:assert_file_not_contains(s:combat_spells_file, 'player.hp = min([', 'combat/spells.vim should not inline HP clamp math.')
call s:assert_file_not_contains(s:economy_file, 'player.hp = min([', 'economy.vim should not inline HP clamp math.')
call s:assert_file_not_contains(s:interact_file, 'player.hp = min([', 'interact.vim should not inline HP clamp math.')
call s:assert_file_not_contains(s:combat_spells_file, "=~# '^' .", 'combat/spells.vim should not keep ad hoc prefix-matching logic.')
call s:assert_file_not_contains(s:economy_file, "=~# '^' .", 'economy.vim should not keep ad hoc prefix-matching logic.')
call s:assert_file_not_contains(s:party_file, "=~# '^' .", 'party.vim should not keep ad hoc prefix-matching logic.')
call s:assert_file_not_contains(s:player_file, "=~# '^' .", 'player.vim should not keep ad hoc prefix-matching logic.')
call s:assert_file_not_contains(s:interact_file, "=~# '^' .", 'interact.vim should not keep ad hoc prefix-matching logic.')

call s:assert_file_contains(s:reducer_file, 'function! game#reducer#reduce', 'reducer.vim must define the root reducer.')
call s:assert_file_contains(s:reducer_file, "l:type ==# 'explore/lookRequested'", 'reducer.vim must route event actions by type.')
call s:assert_file_contains(s:reducer_file, "l:type ==# 'story/frameworkRequested'", 'reducer.vim must route framework story actions.')
call s:assert_file_contains(s:reducer_file, "l:type ==# 'story/meetingRequested'", 'reducer.vim must route Meeting of Minds story actions.')
call s:assert_file_contains(s:reducer_file, "l:type ==# 'party/commandRequested'", 'reducer.vim must route party actions.')
call s:assert_file_contains(s:reducer_file, "Unknown action_vector", 'reducer.vim must surface unknown actions explicitly.')
call s:assert_file_contains(s:framework_file, 'function! game#story#framework#cmd_framework', 'framework.vim must define the vignette framework command handler.')
call s:assert_file_contains(s:framework_file, 'framework theme', 'framework.vim must expose theme-setting guidance.')
call s:assert_file_contains(s:meeting_file, 'function! game#story#meeting#cmd_meeting', 'meeting.vim must define the Meeting of Minds command handler.')
call s:assert_file_contains(s:meeting_file, 'function! game#story#meeting#summary', 'meeting.vim must define the Meeting of Minds summary helper.')
call s:assert_file_contains(s:party_file, 'function! game#party#cmd_party', 'party.vim must define the party command handler.')
call s:assert_file_contains(s:party_file, 'function! game#party#group_bonus', 'party.vim must centralize active companion bonuses.')

call s:assert_file_contains(s:core_file, "return game#reducer#reduce(a:state, game#action#command(a:input))", 'core.vim must delegate command processing through the action/reducer pipeline.')
call s:assert_file_not_contains(s:core_file, "elseif l:action ==#", 'core.vim should not keep the legacy command router.')
call s:assert_file_contains(s:core_file, "'rng_seed': game#rng#default_seed()", 'core.vim should seed new runs through the shared RNG helper.')
call s:assert_file_contains(s:rng_file, 'function! game#rng#next', 'rng.vim must define the shared RNG step helper.')
call s:assert_file_contains(s:rng_file, 'function! game#rng#draw', 'rng.vim must define bounded draws for command handlers.')

call s:assert_file_contains(s:engine_file, 'game#store#create(game#core#init())', 'engine.vim must bootstrap the store from initial state.')
call s:assert_file_contains(s:engine_file, 'game#store#subscribe', 'engine.vim must subscribe redraws to store changes.')
call s:assert_file_contains(s:engine_file, 'game#store#dispatch_input', 'engine.vim must dispatch user input through the store.')
call s:assert_file_not_contains(s:engine_file, 'let s:state = game#core#process', 'engine.vim should not mutate local state directly anymore.')
for s:file in sort(globpath('autoload/game', '**/*.vim', 0, 1))
  call s:assert_true(stridx(join(readfile(s:file), "\n"), 'reltime') == -1, s:file . ' should not depend on reltime()-based randomness.')
endfor

let s:find_thread = game#story#threads#get_thread_card(s:state.notes.thread_cards, 'Find Missing Rangers')
let s:decode_thread = game#story#threads#get_thread_card(s:state.notes.thread_cards, 'decode the return codex relay')
let s:ranger_companion = get(get(s:state, 'player', {}), 'companions', [])[0]
call s:assert_true(index(get(get(s:state, 'meeting', {}), 'focuses', []), 'survivor rescue and uncanny revelation') != -1, 'Meeting of Minds should retain focus themes in state.')
call s:assert_true(index(get(get(s:state, 'meeting', {}), 'banned', []), 'gratuitous cruelty toward rescued rangers') != -1, 'Meeting of Minds should retain banned themes in state.')
call s:assert_true(index(get(get(s:state, 'meeting', {}), 'assumptions', []), 'defeats should become costly consequences instead of abrupt death') != -1, 'Meeting of Minds should retain assumptions in state.')
call s:assert_true(index(get(s:find_thread, 'npcs', []), 'iron broker') != -1, 'Iron Broker should be linked to the main thread card.')
call s:assert_true(index(get(s:find_thread, 'npcs', []), 'Bound Ranger') != -1, 'Bound Ranger should be linked to the rescue thread card.')
call s:assert_true(index(get(s:find_thread, 'npcs', []), 'Ranger Operative') != -1, 'Active companions should be linked into thread bookkeeping.')
call s:assert_true(index(get(s:decode_thread, 'npcs', []), 'Bound Ranger') != -1, 'Replacement threads should inherit linked NPCs.')
call s:assert_true(get(s:ranger_companion, 'status', '') ==# 'active', 'Rallied companions should end in active scene state.')
call s:assert_true(game#party#group_bonus(s:state) == 3, 'Only active companions should contribute to Group Dynamics.')
call s:assert_true(get(get(s:state, 'framework', {}), 'phase', '') ==# 'climax', 'Framework phase should be explicitly movable through the vignette arc.')
call s:assert_true(get(get(s:state, 'framework', {}), 'theme', '') ==# 'learn why the tower is hollowing out recruits', 'Framework theme should persist in story state.')
call s:assert_true(get(get(s:state, 'framework', {}), 'hook', '') ==# 'meet the architect behind the disappearances', 'Framework hook should persist in story state.')
call s:assert_true(get(game#story#records#get_scene_card(s:state.notes.scene_cards, 'nexus'), 'framework_phase', '') ==# 'rising', 'Scene cards should preserve the framework phase active when they were reviewed.')
call s:assert_true(!empty(get(get(s:state.rooms, 'test_portal', {}).objects[0], 'target_room', '')), 'Portal gates should bind to a generated destination.')
call s:assert_true(s:state.loc ==# s:state.rooms['test_portal'].objects[0].target_room, 'Portal traversal should move the player into the bound destination room.')
call s:assert_true(get(get(s:state.rooms[s:state.loc], 'objects', [])[0], 'target_room', '') ==# 'test_portal', 'Generated portal rooms should preserve a return gate back to the source room.')
call s:assert_true(game#combat#spells#match_known(get(s:state.player, 'spells', []), 'dark crystal') ==# 'Dark Crystal Shielding', 'Spell matching should continue supporting unique prefixes.')
call s:assert_true(!empty(game#combat#spells#get('Precision Shot')), 'Spell registry should expose Precision Shot through the shared registry.')
call s:assert_true(len(game#enemies#pool(2)) == 5, 'Enemy rank pools should stay centrally defined by difficulty tier.')
let s:oracle_pool = game#enemies#select(['Ashwalker', 'Voidwraith', 'Doomguard', 'Twilight Weaver'])
call s:assert_true(len(s:oracle_pool) == 4 && get(s:oracle_pool[3], 'name', '') ==# 'Twilight Weaver', 'Canonical enemy selection should preserve requested spawn subsets in order.')
for s:key in [
      \ 'player.consumables.pollen_vial_heal',
      \ 'player.consumables.field_rations_heal',
      \ 'player.consumables.ranger_field_kit',
      \ 'player.rest',
      \ 'combat.mark_bonus',
      \ 'combat.attack',
      \ 'combat.spells.dark_crystal',
      \ 'combat.spells.dimensional_weave',
      \ 'combat.spells.resurgence_ritual',
      \ 'combat.spells.precision_shot',
      \ 'combat.spells.offensive',
      \ 'oracle',
      \ 'enemies.boss.abyssal_overfiend',
      \ 'procgen.friendly_spawn'
      \ ]
  call s:assert_tuning_key_exists(s:key)
endfor

let s:travel_action = game#action#command('go north')
call s:assert_true(get(s:travel_action, 'type', '') ==# 'explore/travelRequested', 'go north should produce a travel action.')
call s:assert_true(get(get(s:travel_action, 'payload', {}), 'dir', '') ==# 'north', 'travel action should capture the normalized direction.')

let s:meeting_action = game#action#command('minds ban gratuitous cruelty toward rescued rangers')
call s:assert_true(get(s:meeting_action, 'type', '') ==# 'story/meetingRequested', 'Meeting of Minds commands should produce story meeting actions.')
call s:assert_true(get(get(s:meeting_action, 'payload', {}), 'subcmd', '') ==# 'ban', 'Meeting of Minds actions should capture the requested subcommand.')

let s:trimmed_meeting = game#core#process(s:state, 'minds rm note 1')
call s:assert_true(empty(get(get(s:trimmed_meeting, 'meeting', {}), 'assumptions', [])), 'Meeting of Minds should support removing stored assumptions.')

let s:heal_state = game#core#init()
let s:heal_state.player.hp = s:heal_state.player.max_hp - 5
let s:heal_state = game#player#heal(s:heal_state, 20)
call s:assert_true(s:heal_state.player.hp == s:heal_state.player.max_hp, 'game#player#heal should clamp restored HP to max HP.')

let s:match_exact = game#match#one(['Shadowstep Mastery', 'Shatterstrike Slam'], 'Shadowstep Mastery')
call s:assert_true(s:match_exact.found && s:match_exact.value ==# 'Shadowstep Mastery', 'Shared matcher should prefer exact matches.')
let s:match_prefix = game#match#one(['Shadowstep Mastery', 'Shatterstrike Slam'], 'shatt')
call s:assert_true(s:match_prefix.found && s:match_prefix.value ==# 'Shatterstrike Slam', 'Shared matcher should allow unique prefixes.')
let s:match_ambiguous = game#match#one(['Shadowstep Mastery', 'Shatterstrike Slam'], 'sh')
call s:assert_true(!s:match_ambiguous.found && s:match_ambiguous.ambiguous && len(s:match_ambiguous.matches) == 2, 'Shared matcher should surface ambiguous prefixes explicitly.')
call s:assert_true(get(game#enemies#archetype('Sentinel of Terror'), 'signature', '') ==# 'Dark Crystal Shielding', 'Enemy archetype lookup should still support alias names through the shared matcher.')

let s:buy_match_state = game#core#init()
let s:buy_match_state.player.trade = 100
let s:buy_match_state = game#core#process(s:buy_match_state, 'buy sh')
call s:assert_contains(s:buy_match_state.log, "TRADE_ERR: 'sh' matches multiple wares: Shatterstrike Slam, Shadowstep Mastery.")

let s:use_match_state = game#core#init()
let s:use_match_state.player.inv += ['Pollen Vial', 'Pollen Satchel']
let s:use_match_state = game#player#cmd_use(s:use_match_state, 'pollen')
call s:assert_contains(s:use_match_state.log, "ITEM_ERR: 'pollen' matches multiple items: Pollen Vial, Pollen Satchel.")

let s:cast_match_state = game#core#init()
let s:cast_match_state.player.spells += ['Shatterstrike Slam', 'Shadowstep Mastery']
let s:cast_match_state.rooms[s:cast_match_state.loc].entities = [{'name': 'Spell Dummy', 'str': 5, 'agi': 5, 'arc': 5}]
let s:cast_match_state = game#combat#cmd_cast(s:cast_match_state, 'sh')
call s:assert_contains(s:cast_match_state.log, "SPELL_ERR: 'sh' matches multiple known spells: Shatterstrike Slam, Shadowstep Mastery.")

let s:party_match_state = game#core#init()
let s:party_match_state = game#party#add_companion(s:party_match_state, game#party#create('Ranger Halver', 5, 5, 3))
let s:party_match_state = game#party#add_companion(s:party_match_state, game#party#create('Ranger Harlan', 5, 5, 3))
let s:party_match_state = game#core#process(s:party_match_state, 'party fade ranger h')
call s:assert_contains(s:party_match_state.log, 'LOG_ERR: Companion reference "ranger h" matches multiple companions: Ranger Halver, Ranger Harlan.')

let s:interact_match_state = game#core#init()
let s:interact_match_state.rooms[s:interact_match_state.loc].objects = [
      \ {'name': 'Veiled Gate', 'desc': 'A gate.', 'effect': 'portal_jump'},
      \ {'name': 'Veiled Gate Console', 'desc': 'A console.', 'effect': 'unlock_exit'}
      \ ]
let s:interact_match_state = game#core#process(s:interact_match_state, 'interact veiled g')
call s:assert_contains(s:interact_match_state.log, "LOG_ERR: 'veiled g' matches multiple objects here: Veiled Gate, Veiled Gate Console.")

let s:attack_win_state = game#core#init()
let s:attack_win_state.rooms[s:attack_win_state.loc] = {
      \ 'name': 'ᚲ COMBAT_TEST ᚲ',
      \ 'desc': 'A deterministic combat proving ground.',
      \ 'exits': {},
      \ 'entities': [{'name': 'Test Sentinel', 'str': 7, 'agi': 7, 'arc': 7}],
      \ 'objects': [],
      \ 'services': []
      \ }
let s:attack_seed = s:attack_win_state.rng_seed
let s:attack_win_state = game#combat#cmd_attack(s:attack_win_state, {'rolls': {'player': 20, 'enemy': 1}, 'seed': 11})
call s:assert_true(empty(s:attack_win_state.rooms[s:attack_win_state.loc].entities), 'Injected attack rolls should allow direct tests to force a combat win.')
call s:assert_true(s:attack_win_state.rng_seed == s:attack_seed, 'Injected attack rolls should bypass RNG advancement.')
call s:assert_contains(s:attack_win_state.log, 'PLAYER: Roll[d20]=20')
call s:assert_contains(s:attack_win_state.log, 'ENEMY : Roll[d20]=1')

let s:attack_loss_state = game#core#init()
let s:attack_loss_state.rooms[s:attack_loss_state.loc] = {
      \ 'name': 'ᚲ COMBAT_TEST ᚲ',
      \ 'desc': 'A deterministic combat proving ground.',
      \ 'exits': {},
      \ 'entities': [{'name': 'Test Juggernaut', 'str': 9, 'agi': 9, 'arc': 9}],
      \ 'objects': [],
      \ 'services': []
      \ }
let s:attack_loss_state = game#combat#cmd_attack(s:attack_loss_state, {'rolls': {'player': 1, 'enemy': 20}, 'seed': 17})
call s:assert_true(len(s:attack_loss_state.rooms[s:attack_loss_state.loc].entities) == 1, 'Injected attack rolls should allow direct tests to force a combat loss.')
call s:assert_contains(s:attack_loss_state.log, 'CRITICAL FAILURE: The Test Juggernaut retaliates with lethal force!')

let s:cast_hit_state = game#core#init()
let s:cast_hit_state.player.spells += ['Explosive Barrage']
let s:cast_hit_state.rooms[s:cast_hit_state.loc] = {
      \ 'name': 'ᚲ SPELL_TEST ᚲ',
      \ 'desc': 'A deterministic spell proving ground.',
      \ 'exits': {},
      \ 'entities': [{'name': 'Spell Dummy', 'str': 5, 'agi': 5, 'arc': 5}],
      \ 'objects': [],
      \ 'services': []
      \ }
let s:cast_seed = s:cast_hit_state.rng_seed
let s:cast_hit_state = game#combat#cmd_cast(s:cast_hit_state, 'Explosive Barrage', {'rolls': {'player': 20}, 'seed': 13})
call s:assert_true(empty(s:cast_hit_state.rooms[s:cast_hit_state.loc].entities), 'Injected cast rolls should allow direct tests to force a spell hit.')
call s:assert_true(s:cast_hit_state.rng_seed == s:cast_seed, 'Injected cast rolls should bypass RNG advancement.')
call s:assert_contains(s:cast_hit_state.log, 'RANGED_ROLL: 28')

let s:cast_fail_state = game#core#init()
let s:cast_fail_state.player.spells += ['Explosive Barrage']
let s:cast_fail_state.rooms[s:cast_fail_state.loc] = {
      \ 'name': 'ᚲ SPELL_TEST ᚲ',
      \ 'desc': 'A deterministic spell proving ground.',
      \ 'exits': {},
      \ 'entities': [{'name': 'Spell Dummy', 'str': 5, 'agi': 5, 'arc': 5}],
      \ 'objects': [],
      \ 'services': []
      \ }
let s:cast_fail_state = game#combat#cmd_cast(s:cast_fail_state, 'Explosive Barrage', {'rolls': {'player': 1}, 'seed': 19})
call s:assert_true(len(s:cast_fail_state.rooms[s:cast_fail_state.loc].entities) == 1, 'Injected cast rolls should allow direct tests to force a spell miss.')
call s:assert_contains(s:cast_fail_state.log, 'RESISTED: The Spell Dummy deflects the magic and counterattacks!')

let s:party_action = game#action#command('party send ranger operative 1')
call s:assert_true(get(s:party_action, 'type', '') ==# 'party/commandRequested', 'party commands should produce party actions.')
call s:assert_true(get(get(s:party_action, 'payload', {}), 'subcmd', '') ==# 'send', 'party action should capture the requested party subcommand.')

let s:faded_state = game#core#process(s:state, 'party fade ranger operative')
call s:assert_true(game#party#group_bonus(s:faded_state) == 0, 'Faded companions should stop contributing to Group Dynamics.')

let s:store = game#store#create(game#core#init())
let s:store_notifications = 0
let s:sub_id = game#store#subscribe(s:store, function(expand('<SID>') . 'count_state_change'))
call game#store#dispatch_batch(s:store, [game#action#command('look'), game#action#command('profile')])
call s:assert_true(s:store_notifications == 1, 'dispatch_batch should notify subscribers once.')
call s:assert_contains(game#core#render(game#store#get_state(s:store)), '--- PLAYER PROFILE ---')
call game#store#unsubscribe(s:store, s:sub_id)

let s:rendered = game#core#render(s:state)
let s:framework_view = game#core#render(game#core#process(s:state, 'framework'))
let s:meeting_view = game#core#render(game#core#process(s:state, 'minds'))
let s:party_view = game#core#render(game#core#process(s:state, 'party'))
call s:assert_contains(s:rendered, 'Arc: CH1 CLIMAX')
call s:assert_contains(s:rendered, 'Accord: 1 focus / 1 banned / 1 assumptions')
call s:assert_contains(s:rendered, 'Party: 1 active / 0 faded / 0 elsewhere | Group: +3')
call s:assert_contains(s:framework_view, '--- VIGNETTE FRAMEWORK ---')
call s:assert_contains(s:framework_view, 'Hook: meet the architect behind the disappearances')
call s:assert_contains(s:meeting_view, '--- MEETING OF MINDS ---')
call s:assert_contains(s:meeting_view, 'Focus Themes: survivor rescue and uncanny revelation')
call s:assert_contains(s:party_view, '--- PARTY TACTICS ---')
call s:assert_contains(s:party_view, 'Ranger Operative [ACTIVE]')
call s:assert_contains(s:rendered, '| NPCs: iron broker')
call s:assert_contains(s:rendered, '| arc: CH1')
call s:assert_contains(s:rendered, 'Banned Themes: gratuitous cruelty toward rescued rangers')
call s:assert_contains(s:rendered, '  NPCs: Bound Ranger')
call writefile(s:meeting_view + [''] + s:party_view + [''] + s:framework_view + [''] + s:rendered, 'test_output.txt', 'a')

" --- Climax: Abyssal Throne flow ---
" Force-complete the three core climax quests, then verify the Abyssal Throne flow.
for s:climax_id in ['rescue-rangers', 'recover-lost-tomes', 'purify-altars']
  for s:i in range(len(s:state.quests))
    if get(s:state.quests[s:i], 'id', '') ==# s:climax_id
      let s:state.quests[s:i].status = 'complete'
      let s:state.quests[s:i].progress = s:state.quests[s:i].goal
    endif
  endfor
endfor
let s:state.loc = 'nexus'
let s:state.rooms.nexus.objects = [{'name': 'Arcane Terminal', 'desc': 'A flickering terminal.', 'effect': 'briefing'}]
let s:state.flags.terminal_briefed = 1
let s:state = game#core#process(s:state, 'interact Arcane Terminal')
call s:assert_true(get(s:state.flags, 'climax_unveiled', 0) == 1, 'Re-examining the terminal with all three quests done should unveil the climax.')
let s:nexus_objects = s:state.rooms.nexus.objects
let s:has_sigil = 0
for s:obj in s:nexus_objects
  if get(s:obj, 'effect', '') ==# 'descend_throne'
    let s:has_sigil = 1
  endif
endfor
call s:assert_true(s:has_sigil, 'Climax unveil should spawn an Abyssal Sigil interactable in the Merchandise Store Room.')
let s:state = game#core#process(s:state, 'interact Abyssal Sigil')
call s:assert_true(s:state.loc ==# 'abyssal_throne', 'Abyssal Sigil should descend the player onto the Abyssal Throne.')
let s:state.rng_seed = 2578
let s:state = game#core#process(s:state, 'attack')
let s:boss_room = s:state.rooms[s:state.loc]
call s:assert_true(!empty(s:boss_room.entities), 'After phase 1, the Abyssal Overfiend should still occupy the throne room.')
call s:assert_true(get(s:boss_room.entities[0], 'phases_done', 0) == 1, 'Phase 1 defeat should advance phases_done to 1.')
let s:state = game#core#process(s:state, 'attack')
call s:assert_true(empty(s:state.rooms['abyssal_throne'].entities), 'Phase 2 defeat should remove the Overfiend from the throne room.')
let s:state = game#core#process(s:state, 'interact Throne Sigil')
call s:assert_true(s:state.surge == 0, 'Defiling the Throne Sigil should reset the Surge Count.')
call s:assert_true(s:state.player.hp == s:state.player.max_hp, 'Defiling the Throne Sigil should fully restore HP through the shared heal helper.')
let s:climax_quest = {}
for s:q in s:state.quests
  if get(s:q, 'id', '') ==# 'confront-overfiend'
    let s:climax_quest = s:q
    break
  endif
endfor
call s:assert_true(get(s:climax_quest, 'status', '') ==# 'complete', 'Boss defeat should complete the confront-overfiend quest.')
call s:assert_true(index(s:state.player.inv, 'Voidmaw Sigil') != -1, 'Climax quest should award the Voidmaw Sigil reward.')
call s:assert_true(index(s:state.player.spells, 'Stellar Burst Barrage') != -1, 'Climax quest should award the Stellar Burst Barrage reward spell.')

" Enemy archetype flavor lines should be available for combat narration.
let s:flavor = game#enemies#flavor_lines('Obsidian Warden')
call s:assert_true(!empty(s:flavor), 'Combat flavor lookup should return signature data for Obsidian Warden.')

" Table 2 oracle modifiers should mutate state deterministically via the public apply_modifier helper.
let s:mod_state = deepcopy(s:state)
let s:mod_state.surge = 7
let s:mod_state.stage = 'knowledge'
let s:mod_result = game#oracle#apply_modifier(s:mod_state, 'limelit')
call s:assert_true(s:mod_result.state.surge == 0, 'Limelit modifier should zero the Surge Count.')
let s:mod_result = game#oracle#apply_modifier(s:mod_state, 'to endings')
call s:assert_true(s:mod_result.state.stage ==# 'endings', 'To Endings modifier should shift stage to endings.')
let s:upstage_state = deepcopy(s:state)
let s:upstage_state.surge = 1
let s:mod_result = game#oracle#apply_modifier(s:upstage_state, 'upstaged')
call s:assert_true(s:mod_result.state.surge == 5, 'Upstaged modifier should bump Surge Count by 4.')
let s:oracle_state = game#core#init()
let s:oracle_state.surge = 7
let s:oracle_state.rng_seed = 245
let s:oracle_state = game#core#process(s:oracle_state, 'ask does the tower yield?')
call s:assert_true(s:oracle_state.surge == 0, 'Deterministic oracle asks should apply the seeded modifier result.')
call s:assert_contains(s:oracle_state.log, '[Loom of Fate: 103] YES, AND UNEXPECTEDLY')
call s:assert_contains(s:oracle_state.log, 'UNEXPECTED MODIFIER: LIMELIT')

" Montage should advance the scene index, reset Surge, and append a montage carry-fact to every active thread.
let s:montage_state = deepcopy(s:state)
let s:montage_state.surge = 6
let s:before_scene_idx = get(s:montage_state.scene, 'index', 1)
let s:montage_state = game#core#process(s:montage_state, 'montage close out the rangers'' extraction across multiple corridors')
call s:assert_true(s:montage_state.surge == 0, 'Montage should reset the Surge Count.')
call s:assert_true(get(s:montage_state.scene, 'index', 1) == s:before_scene_idx + 1, 'Montage should advance the scene index by 1.')
let s:found_montage_fact = 0
for s:card in s:montage_state.notes.thread_cards
  for s:fact in get(s:card, 'facts', [])
    if s:fact =~# '^Montage carry'
      let s:found_montage_fact = 1
    endif
  endfor
endfor
call s:assert_true(s:found_montage_fact == 1, 'Montage should append a Montage carry fact to thread cards.')

" Counter-signature should strip an active mark when an Ashwalker wins the duel.
let s:counter_state = deepcopy(s:state)
let s:counter_state.player.str = 1
let s:counter_state.player.agi = 1
let s:counter_state.player.arc = 1
let s:counter_state.player.hp = 200
let s:counter_state.mark = 'Ashwalker'
let s:counter_state.rooms[s:counter_state.loc] = {
      \ 'name': 'ᚲ MARSH_TEST ᚲ',
      \ 'desc': 'Test marsh.',
      \ 'exits': {},
      \ 'entities': [{'name': 'Ashwalker', 'str': 99, 'agi': 99, 'arc': 99}],
      \ 'objects': [],
      \ 'services': []
      \ }
let s:counter_state = game#core#process(s:counter_state, 'attack')
call s:assert_true(empty(get(s:counter_state, 'mark', '')), 'Ashwalker counter-signature should strip Hunter''s Mark on a duel loss.')

" Roving recruitment flow.
let s:state.rooms['test_recruit'] = {
      \ 'name': 'ᚲ ETHEREAL_MARSHLANDS ᚲ',
      \ 'desc': 'Murky marshes filled with strangers.',
      \ 'exits': {'north': s:state.loc},
      \ 'entities': [],
      \ 'services': [],
      \ 'objects': [{'name': 'Stranded Ranger', 'desc': 'A fellow recon operative.', 'effect': 'recruit_ranger'}]
      \ }
let s:state.rooms[s:state.loc].exits['south'] = 'test_recruit'
let s:before_companions = len(get(s:state.player, 'companions', []))
let s:state = game#core#process(s:state, 'go south')
let s:state = game#core#process(s:state, 'interact Stranded Ranger')
let s:after_companions = len(get(s:state.player, 'companions', []))
call s:assert_true(s:after_companions == s:before_companions + 1, 'Recruiting a Stranded Ranger should add a new companion to the party.')
call writefile(['--- CLIMAX OK ---'] + s:flavor, 'test_output.txt', 'a')
qa!
