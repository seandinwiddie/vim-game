function! QuadarTest_Register(name, fn) abort
  if !exists('g:quadar_test_cases')
    let g:quadar_test_cases = []
  endif
  call add(g:quadar_test_cases, {'name': a:name, 'fn': a:fn})
endfunction

function! QuadarTest_ResetOutput() abort
  call writefile(['--- START TESTS ---'], 'test_output.txt')
endfunction

function! QuadarTest_Append(lines) abort
  let l:lines = type(a:lines) == v:t_list ? a:lines : [a:lines]
  call writefile(l:lines, 'test_output.txt', 'a')
endfunction

function! QuadarTest_AssertTrue(condition, message) abort
  if !a:condition
    throw 'ASSERTION FAILURE: ' . a:message
  endif
endfunction

function! QuadarTest_AssertContains(lines, needle) abort
  call QuadarTest_AssertTrue(stridx(join(a:lines, "\n"), a:needle) >= 0, 'Missing expected text: ' . a:needle)
endfunction

function! QuadarTest_AssertFileContains(path, needle, message) abort
  call QuadarTest_AssertTrue(filereadable(a:path), 'Missing required file: ' . a:path)
  call QuadarTest_AssertTrue(stridx(join(readfile(a:path), "\n"), a:needle) >= 0, a:message)
endfunction

function! QuadarTest_AssertFileNotContains(path, needle, message) abort
  call QuadarTest_AssertTrue(filereadable(a:path), 'Missing required file: ' . a:path)
  call QuadarTest_AssertTrue(stridx(join(readfile(a:path), "\n"), a:needle) == -1, a:message)
endfunction

function! QuadarTest_AssertTuningKeyExists(key) abort
  try
    call game#tuning#get(a:key)
  catch
    call QuadarTest_AssertTrue(0, 'Missing tuning key: ' . a:key)
  endtry
endfunction

function! QuadarTest_CountStateChange(_state) abort
  let g:quadar_test_store_notifications = get(g:, 'quadar_test_store_notifications', 0) + 1
endfunction

function! QuadarTest_ResetStoreNotifications() abort
  let g:quadar_test_store_notifications = 0
endfunction

function! QuadarTest_StoreNotifications() abort
  return get(g:, 'quadar_test_store_notifications', 0)
endfunction

function! QuadarTest_Path(key) abort
  let l:paths = {
        \ 'action': expand('autoload/game/action.vim'),
        \ 'combat': expand('autoload/game/combat.vim'),
        \ 'combat_spells': expand('autoload/game/combat/spells.vim'),
        \ 'core': expand('autoload/game/core.vim'),
        \ 'economy': expand('autoload/game/economy.vim'),
        \ 'enemies': expand('autoload/game/enemies.vim'),
        \ 'engine': expand('autoload/game/engine.vim'),
        \ 'framework': expand('autoload/game/story/framework.vim'),
        \ 'story_state': expand('autoload/game/story/state.vim'),
        \ 'story_records': expand('autoload/game/story/records.vim'),
        \ 'story_threads': expand('autoload/game/story/threads.vim'),
        \ 'story_cards': expand('autoload/game/story/cards.vim'),
        \ 'interact': expand('autoload/game/explore/interact.vim'),
        \ 'match': expand('autoload/game/match.vim'),
        \ 'meeting': expand('autoload/game/story/meeting.vim'),
        \ 'oracle': expand('autoload/game/oracle.vim'),
        \ 'party': expand('autoload/game/party.vim'),
        \ 'player': expand('autoload/game/player.vim'),
        \ 'procgen': expand('autoload/game/explore/procgen.vim'),
        \ 'quest': expand('autoload/game/quest.vim'),
        \ 'reducer': expand('autoload/game/reducer.vim'),
        \ 'rng': expand('autoload/game/rng.vim'),
        \ 'run_all': expand('test/run_all.vim'),
        \ 'store': expand('autoload/game/store.vim'),
        \ 'test_entry': expand('test.vim'),
        \ 'tuning': expand('autoload/game/tuning.vim')
        \ }
  return get(l:paths, a:key, '')
endfunction

function! QuadarTest_AssertSubdomainLimits() abort
  let l:violations = []
  for l:file in sort(globpath('autoload/game', '**/*.vim', 0, 1))
    let l:line_count = len(readfile(l:file))
    if l:line_count > 300
      call add(l:violations, l:file . ' :: ' . l:line_count . ' lines')
    endif
  endfor
  call QuadarTest_AssertTrue(empty(l:violations), 'ARCHITECTURE_GUARD_FAILURE: Split oversized modules into subdomains. ' . join(l:violations, '; '))
endfunction

function! QuadarTest_FormatException(exception) abort
  return substitute(a:exception, '^Vim([^)]*):', '', '')
endfunction

function! QuadarTest_CampaignState() abort
  let l:state = game#core#init()
  let l:state.player.trade = 100
  let l:state = game#core#process(l:state, 'shop')
  let l:state = game#core#process(l:state, 'buy Dark Crystal Shielding')
  let l:state = game#core#process(l:state, "buy Hunter's Mark")
  let l:state = game#core#process(l:state, 'buy Zinc Weave Cloak')
  let l:state = game#core#process(l:state, 'buy Explosive Barrage')
  let l:state = game#core#process(l:state, 'buy Shatterstrike Slam')
  call add(l:state.player.inv, 'Gibsonian Shard')
  let l:state = game#core#process(l:state, 'sell Gibsonian Shard')
  let l:state = game#core#process(l:state, 'frame 1 conflict')
  let l:state = game#core#process(l:state, 'framework theme learn why the tower is hollowing out recruits')
  let l:state = game#core#process(l:state, 'framework hook meet the architect behind the disappearances')
  let l:state = game#core#process(l:state, 'framework next')
  let l:state = game#core#process(l:state, 'framework')
  let l:state = game#core#process(l:state, 'minds focus survivor rescue and uncanny revelation')
  let l:state = game#core#process(l:state, 'minds ban gratuitous cruelty toward rescued rangers')
  let l:state = game#core#process(l:state, 'minds note defeats should become costly consequences instead of abrupt death')
  let l:state = game#core#process(l:state, 'minds')
  let l:state = game#core#process(l:state, 'npc add Iron Broker')
  let l:state = game#core#process(l:state, 'npc')
  let l:state = game#core#process(l:state, 'quests')
  let l:state = game#core#process(l:state, 'notes')
  let l:state = game#core#process(l:state, 'scene')
  let l:state = game#core#process(l:state, 'look')
  let l:state = game#core#process(l:state, 'interact Arcane Terminal')
  let l:state = game#core#process(l:state, 'frame 2 knowledge')
  let l:state = game#core#process(l:state, 'aside 1 Another recon team was seen near the tower shell')
  let l:state.rooms[l:state.loc].objects = [
        \ {'name': 'Bound Ranger', 'desc': 'A shackled recruit calls for extraction.', 'effect': 'rescue_ranger', 'quest_id': 'rescue-rangers'},
        \ {'name': 'Sealed Reliquary', 'desc': 'An archive reliquary full of return codices.', 'effect': 'recover_tome', 'quest_id': 'recover-lost-tomes'}
        \ ]
  let l:state = game#core#process(l:state, 'interact Bound Ranger')
  let l:state = game#core#process(l:state, 'party')
  let l:state = game#core#process(l:state, 'party fade ranger operative')
  let l:state = game#core#process(l:state, 'party send ranger operative 1')
  let l:state = game#core#process(l:state, 'party rally ranger operative')
  let l:state = game#core#process(l:state, 'interact Sealed Reliquary')
  let l:state = game#core#process(l:state, 'quests')
  let l:state = game#core#process(l:state, 'cast Dark Crystal Shielding')
  let l:state = game#core#process(l:state, 'go north')
  let l:state = game#core#process(l:state, "cast Hunter's Mark")
  let l:state = game#core#process(l:state, 'cast Explosive Barrage')
  let l:state = game#core#process(l:state, 'cast Shatterstrike Slam')
  let l:state = game#core#process(l:state, 'framework phase climax')
  let l:state = game#core#process(l:state, 'fade Ashwalker resistance confirms the spire approach is still contested')
  let l:state = game#core#process(l:state, 'thread split 1 Track the tower shell recon cell')
  let l:state = game#core#process(l:state, 'thread replace 2 Decode the return codex relay')
  let l:state = game#core#process(l:state, 'thread mod 3 Secure the tower shell extraction route')
  let l:state = game#core#process(l:state, 'thread')

  let l:state.rooms['test_wastes'] = game#data#new_room('test_wastes', 'toxic', 'ᚲ TOXIC_WASTES ᚲ', 'A ghastly mire of desolation.', {'exits': {'west': l:state.loc}})
  let l:state.rooms[l:state.loc].exits['east'] = 'test_wastes'
  let l:state = game#core#process(l:state, 'go east')

  let l:state.rooms['test_chapel'] = game#data#new_room('test_chapel', 'temple', 'ᚲ HAUNTED_CHAPEL ᚲ', 'An accursed chapel.', {
        \ 'exits': {'north': l:state.loc},
        \ 'objects': [{'name': 'Corrupted Altar', 'desc': 'A desecrated monolith.', 'effect': 'purify_altar', 'quest_id': 'purify-altars'}]
        \ })
  let l:state.rooms[l:state.loc].exits['south'] = 'test_chapel'
  let l:state = game#core#process(l:state, 'go south')
  let l:state = game#core#process(l:state, 'interact Corrupted Altar')

  let l:state.rooms['test_mil'] = game#data#new_room('test_mil', 'facility', 'ᚲ MILITARY_FACILITY ᚲ', 'Ancient military bastion.', {
        \ 'exits': {'north': l:state.loc},
        \ 'objects': [{'name': 'Holographic Terminal', 'desc': 'A distorted projection.', 'effect': 'hidden_lore'}]
        \ })
  let l:state.rooms[l:state.loc].exits['west'] = 'test_mil'
  let l:state = game#core#process(l:state, 'go west')
  let l:state = game#core#process(l:state, 'interact Holographic Terminal')

  let l:state.rooms['test_portal'] = game#data#new_room('test_portal', 'void', 'ᚲ MYSTERIOUS_PORTAL ᚲ', 'A thin alien threshold trembles here.', {
        \ 'exits': {'east': l:state.loc},
        \ 'objects': [{'name': 'Veiled Gate', 'desc': 'A veiled gate shivering with impossible geometry.', 'effect': 'portal_jump'}]
        \ })
  let l:state.rooms[l:state.loc].exits['south'] = 'test_portal'
  let l:state = game#core#process(l:state, 'go south')
  let l:state = game#core#process(l:state, 'interact Veiled Gate')

  let l:state = game#core#process(l:state, 'inventory')
  let l:state = game#core#process(l:state, 'profile')
  let l:state = game#core#process(l:state, 'notes')
  return l:state
endfunction
