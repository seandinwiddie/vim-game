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

function! s:count_state_change(_state) abort
  let s:store_notifications += 1
endfunction

let s:action_file = expand('autoload/game/action.vim')
let s:store_file = expand('autoload/game/store.vim')
let s:reducer_file = expand('autoload/game/reducer.vim')
let s:engine_file = expand('autoload/game/engine.vim')
let s:core_file = expand('autoload/game/core.vim')
let s:framework_file = expand('autoload/game/story/framework.vim')

call s:assert_file_contains(s:action_file, 'function! game#action#make', 'action.vim must define the action factory.')
call s:assert_file_contains(s:action_file, 'function! game#action#command', 'action.vim must define the command-to-action mapper.')
call s:assert_file_contains(s:action_file, 'explore/travelRequested', 'action.vim must centralize event-style action types.')
call s:assert_file_contains(s:action_file, 'story/frameworkRequested', 'action.vim must route framework commands through typed story actions.')
call s:assert_file_not_contains(s:action_file, '/set', 'action.vim should use event-style action names instead of setter-style names.')

call s:assert_file_contains(s:store_file, 'function! game#store#create', 'store.vim must define create().')
call s:assert_file_contains(s:store_file, 'function! game#store#dispatch(', 'store.vim must define dispatch().')
call s:assert_file_contains(s:store_file, 'function! game#store#dispatch_batch', 'store.vim must define dispatch_batch().')
call s:assert_file_contains(s:store_file, 'function! game#store#subscribe', 'store.vim must define subscribe().')
call s:assert_file_contains(s:store_file, 'game#reducer#reduce', 'store.vim dispatch must route through the reducer.')

call s:assert_file_contains(s:reducer_file, 'function! game#reducer#reduce', 'reducer.vim must define the root reducer.')
call s:assert_file_contains(s:reducer_file, "l:type ==# 'explore/lookRequested'", 'reducer.vim must route event actions by type.')
call s:assert_file_contains(s:reducer_file, "l:type ==# 'story/frameworkRequested'", 'reducer.vim must route framework story actions.')
call s:assert_file_contains(s:reducer_file, "Unknown action_vector", 'reducer.vim must surface unknown actions explicitly.')
call s:assert_file_contains(s:framework_file, 'function! game#story#framework#cmd_framework', 'framework.vim must define the vignette framework command handler.')
call s:assert_file_contains(s:framework_file, 'framework theme', 'framework.vim must expose theme-setting guidance.')

call s:assert_file_contains(s:core_file, "return game#reducer#reduce(a:state, game#action#command(a:input))", 'core.vim must delegate command processing through the action/reducer pipeline.')
call s:assert_file_not_contains(s:core_file, "elseif l:action ==#", 'core.vim should not keep the legacy command router.')

call s:assert_file_contains(s:engine_file, 'game#store#create(game#core#init())', 'engine.vim must bootstrap the store from initial state.')
call s:assert_file_contains(s:engine_file, 'game#store#subscribe', 'engine.vim must subscribe redraws to store changes.')
call s:assert_file_contains(s:engine_file, 'game#store#dispatch_input', 'engine.vim must dispatch user input through the store.')
call s:assert_file_not_contains(s:engine_file, 'let s:state = game#core#process', 'engine.vim should not mutate local state directly anymore.')

let s:find_thread = game#story#threads#get_thread_card(s:state.notes.thread_cards, 'Find Missing Rangers')
let s:decode_thread = game#story#threads#get_thread_card(s:state.notes.thread_cards, 'decode the return codex relay')
call s:assert_true(index(get(s:find_thread, 'npcs', []), 'iron broker') != -1, 'Iron Broker should be linked to the main thread card.')
call s:assert_true(index(get(s:find_thread, 'npcs', []), 'Bound Ranger') != -1, 'Bound Ranger should be linked to the rescue thread card.')
call s:assert_true(index(get(s:decode_thread, 'npcs', []), 'Bound Ranger') != -1, 'Replacement threads should inherit linked NPCs.')
call s:assert_true(get(get(s:state, 'framework', {}), 'phase', '') ==# 'climax', 'Framework phase should be explicitly movable through the vignette arc.')
call s:assert_true(get(get(s:state, 'framework', {}), 'theme', '') ==# 'learn why the tower is hollowing out recruits', 'Framework theme should persist in story state.')
call s:assert_true(get(get(s:state, 'framework', {}), 'hook', '') ==# 'meet the architect behind the disappearances', 'Framework hook should persist in story state.')
call s:assert_true(get(game#story#records#get_scene_card(s:state.notes.scene_cards, 'nexus'), 'framework_phase', '') ==# 'rising', 'Scene cards should preserve the framework phase active when they were reviewed.')
call s:assert_true(!empty(get(get(s:state.rooms, 'test_portal', {}).objects[0], 'target_room', '')), 'Portal gates should bind to a generated destination.')
call s:assert_true(s:state.loc ==# s:state.rooms['test_portal'].objects[0].target_room, 'Portal traversal should move the player into the bound destination room.')
call s:assert_true(get(get(s:state.rooms[s:state.loc], 'objects', [])[0], 'target_room', '') ==# 'test_portal', 'Generated portal rooms should preserve a return gate back to the source room.')

let s:travel_action = game#action#command('go north')
call s:assert_true(get(s:travel_action, 'type', '') ==# 'explore/travelRequested', 'go north should produce a travel action.')
call s:assert_true(get(get(s:travel_action, 'payload', {}), 'dir', '') ==# 'north', 'travel action should capture the normalized direction.')

let s:store = game#store#create(game#core#init())
let s:store_notifications = 0
let s:sub_id = game#store#subscribe(s:store, function(expand('<SID>') . 'count_state_change'))
call game#store#dispatch_batch(s:store, [game#action#command('look'), game#action#command('profile')])
call s:assert_true(s:store_notifications == 1, 'dispatch_batch should notify subscribers once.')
call s:assert_contains(game#core#render(game#store#get_state(s:store)), '--- PLAYER PROFILE ---')
call game#store#unsubscribe(s:store, s:sub_id)

let s:rendered = game#core#render(s:state)
let s:framework_view = game#core#render(game#core#process(s:state, 'framework'))
call s:assert_contains(s:rendered, 'Arc: CH1 CLIMAX')
call s:assert_contains(s:framework_view, '--- VIGNETTE FRAMEWORK ---')
call s:assert_contains(s:framework_view, 'Hook: meet the architect behind the disappearances')
call s:assert_contains(s:rendered, '| NPCs: iron broker')
call s:assert_contains(s:rendered, '| arc: CH1')
call s:assert_contains(s:rendered, '  NPCs: Bound Ranger')
call writefile(s:framework_view + [''] + s:rendered, 'test_output.txt', 'a')
qa!
