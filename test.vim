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

let s:state = game#core#process(s:state, 'inventory')
let s:state = game#core#process(s:state, 'profile')
let s:state = game#core#process(s:state, 'notes')

call writefile(game#core#render(s:state), 'test_output.txt', 'a')
