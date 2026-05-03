" autoload/game/state.vim - Canonical Root State Schema

function! game#state#schema() abort
  return {
        \ 'view': 'game',
        \ 'player': {
        \   'name': 'Kamenal',
        \   'class': 'Rogue/Ranger',
        \   'level': 1,
        \   'hp': 150,
        \   'max_hp': 150,
        \   'inv': [],
        \   'spells': [],
        \   'str': 5,
        \   'agi': 5,
        \   'arc': 5,
        \   'trade': 0,
        \   'upgrades': [],
        \   'companions': []
        \ },
        \ 'loc': 'nexus',
        \ 'rng_seed': 0,
        \ 'surge': 0,
        \ 'stage': 'knowledge',
        \ 'threads': [],
        \ 'scene': {},
        \ 'quests': [],
        \ 'flags': {},
        \ 'progress': {},
        \ 'rooms': {},
        \ 'log': [],
        \ 'log_cursor': 0,
        \ 'hint': '',
        \ 'guard': 0,
        \ 'mark': ''
        \ }
endfunction

function! game#state#bootstrap() abort
  let l:state = deepcopy(game#state#schema())
  let l:rooms = game#data#init_rooms()
  let l:story = game#story#state#bootstrap()
  
  let l:state.player.level = 12
  let l:state.player.inv = ['Basic Dagger', 'Scout Gear']
  let l:state.player.spells = ['Ethereal Dagger Assault', 'Cloak of Shadows']
  let l:state.player.str = 5
  let l:state.player.agi = 8
  let l:state.player.arc = 4
  let l:state.rng_seed = game#rng#default_seed()
  let l:state.threads = ['Find Missing Rangers']
  let l:state.scene = l:story.scene
  let l:state.quests = l:story.quests
  let l:state.flags = l:story.flags
  let l:state.progress = l:story.progress
  let l:state.rooms = l:rooms
  let l:state.hint = 'SYSTEM_INIT: Type "look" to scan your surroundings or "help" to review commands.'
  
  return game#state#hydrate(l:state)
endfunction

function! game#state#hydrate(state) abort
  let l:next_state = a:state
  let l:schema = game#state#schema()
  let l:next_state = s:diff_patch(l:next_state, l:schema)

  let l:next_state = game#rng#hydrate(l:next_state)
  if empty(l:next_state.threads)
    let l:next_state.threads = ['Find Missing Rangers']
  endif
  if empty(l:next_state.hint)
    let l:next_state.hint = 'SYSTEM_INIT: Type "look" to scan your surroundings or "help" to review commands.'
  endif

  let l:next_state = game#party#hydrate(l:next_state)
  let l:next_state = game#story#hydrate(l:next_state)
  let l:next_state = game#economy#hydrate(l:next_state)
  return l:next_state
endfunction

function! game#state#assert_valid(state) abort
  " Checks if the schema is strictly obeyed
  for [l:k, l:v] in items(game#state#schema())
    if !has_key(a:state, l:k)
      throw 'SCHEMA_ERROR: Missing key ' . l:k
    endif
  endfor
endfunction

function! s:diff_patch(state, schema) abort
  let l:patched = a:state
  for [l:k, l:v] in items(a:schema)
    if !has_key(l:patched, l:k)
      let l:patched[l:k] = deepcopy(l:v)
    elseif type(l:v) == v:t_dict && type(l:patched[l:k]) == v:t_dict
      let l:patched[l:k] = s:diff_patch(l:patched[l:k], l:v)
    endif
  endfor
  return l:patched
endfunction
