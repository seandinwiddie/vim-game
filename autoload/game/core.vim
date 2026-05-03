" autoload/game/core.vim - Quadar Micro-MUD Functional Core

" === PURE LOGIC: INITIAL STATE ===
function! game#core#init() abort
  let l:rooms = game#data#init_rooms()
  let l:story = game#story#bootstrap()

  let l:s = {
        \ 'view': 'game',
        \ 'player': {'name': 'Kamenal', 'class': 'Rogue/Ranger', 'level': 12, 'hp': 150, 'max_hp': 150, 'inv': ['Basic Dagger', 'Scout Gear'], 'spells': ['Ethereal Dagger Assault', 'Cloak of Shadows'], 'str': 5, 'agi': 8, 'arc': 4},
        \ 'loc': 'nexus',
        \ 'surge': 0,
        \ 'stage': 'knowledge',
        \ 'threads': ['Find Missing Rangers'],
        \ 'scene': l:story.scene,
        \ 'quests': l:story.quests,
        \ 'flags': l:story.flags,
        \ 'progress': l:story.progress,
        \ 'rooms': l:rooms,
        \ 'log': [],
        \ 'hint': 'SYSTEM_INIT: Type "look" to scan your surroundings.',
        \ }
  let l:s = game#core#normalize(l:s)
  return game#core#add_log(l:s, ['NEURAL_LINK_ESTABLISHED', 'SYSTEM_OVERRIDE: INITIATING RECONNAISSANCE PROTOCOL ᚠ', 'You materialize in the Merchandise Store Room.'])
endfunction

" === PURE LOGIC: COMMAND PROCESSING ===
function! game#core#process(state, input) abort
  let l:cmd = tolower(trim(a:input))
  let l:parts = split(l:cmd)
  if empty(l:parts) | return a:state | endif
  
  let l:action = l:parts[0]
  if l:action ==# 'look' || l:action ==# 'l'
    return game#explore#cmd_look(a:state)
  elseif l:action ==# 'go' || l:action ==# 'n' || l:action ==# 's' || l:action ==# 'e' || l:action ==# 'w'
    let l:dir = (len(l:parts) > 1) ? l:parts[1] : l:action
    return game#explore#cmd_go(a:state, l:dir)
  elseif l:action ==# 'ask'
    let l:question = join(l:parts[1:], ' ')
    return game#oracle#cmd_ask(a:state, l:question)
  elseif l:action ==# 'stage'
    let l:new_stage = (len(l:parts) > 1) ? tolower(l:parts[1]) : ''
    return game#oracle#cmd_stage(a:state, l:new_stage)
  elseif l:action ==# 'thread'
    if len(l:parts) < 2
      return game#core#add_log(a:state, "LOG_ERR: 'thread add <desc>' or 'thread rm <idx>'.")
    endif
    let l:subcmd = tolower(l:parts[1])
    let l:args = join(l:parts[2:], ' ')
    return game#oracle#cmd_thread(a:state, l:subcmd, l:args)
  elseif l:action ==# 'focus'
    let l:focus_arg = len(l:parts) > 1 ? l:parts[1] : ''
    return game#story#cmd_focus(a:state, l:focus_arg)
  elseif l:action ==# 'quests' || l:action ==# 'objectives' || l:action ==# 'o'
    return game#story#cmd_quests(a:state)
  elseif l:action ==# 'attack' || l:action ==# 'fight' || l:action ==# 'c'
    return game#combat#cmd_attack(a:state)
  elseif l:action ==# 'cast' || l:action ==# 'm'
    let l:spell = join(l:parts[1:], ' ')
    return game#combat#cmd_cast(a:state, l:spell)
  elseif l:action ==# 'interact'
    let l:obj = join(l:parts[1:], ' ')
    return game#explore#cmd_interact(a:state, l:obj)
  elseif l:action ==# 'use' || l:action ==# 'consume'
    let l:item = join(l:parts[1:], ' ')
    return game#player#cmd_use(a:state, l:item)
  elseif l:action ==# 'inventory' || l:action ==# 'i'
    return game#player#cmd_inventory(a:state)
  elseif l:action ==# 'profile' || l:action ==# 'p'
    return game#player#cmd_profile(a:state)
  elseif l:action ==# 'rest' || l:action ==# 'r'
    return game#player#cmd_rest(a:state)
  elseif l:action ==# 'save'
    return game#player#cmd_save(a:state)
  elseif l:action ==# 'load'
    return game#player#cmd_load(a:state)
  endif

  return game#core#add_log(a:state, "LOG_ERR_CRITICAL: Unknown input_vector '" . l:action . "'")
endfunction

" === INTERNAL PURE HELPERS ===

function! game#core#add_log(state, msg) abort
  let l:next_state = copy(a:state)
  if type(a:msg) == v:t_list
    let l:next_state.log += a:msg
  else
    let l:next_state.log += [a:msg]
  endif
  if len(l:next_state.log) > 100
    let l:next_state.log = l:next_state.log[-100:]
  endif
  return l:next_state
endfunction

function! game#core#render(state) abort
  let l:state = game#core#normalize(a:state)
  let l:header = [
        \ "ᚠ ᛫ ᛟ ᛫ ᚱ ᛫ ᛒ ᛫ ᛟ ᛫ ᚲ",
        \ "== QUA'DAR NEURAL LINK ==",
        \ "Stage: TO " . toupper(l:state.stage) . " | Surge Count: " . l:state.surge,
        \ "Scene #" . get(l:state.scene, 'index', 1) . ": " . game#story#scene_label(l:state),
        \ "Focus: " . game#story#focus_label(l:state),
        \ game#story#quest_summary(l:state),
        \ l:state.hint,
        \ "--- ACTIVE THREADS ---"
        \ ]
  let l:idx = 1
  for l:th in l:state.threads
    call add(l:header, l:idx . ". " . l:th)
    let l:idx += 1
  endfor
  call add(l:header, "")
  return l:header + l:state.log
endfunction

function! game#core#normalize(state) abort
  let l:next_state = deepcopy(a:state)
  if !has_key(l:next_state, 'threads') || empty(l:next_state.threads)
    let l:next_state.threads = ['Find Missing Rangers']
  endif
  if !has_key(l:next_state, 'hint')
    let l:next_state.hint = 'SYSTEM_INIT: Type "look" to scan your surroundings.'
  endif
  return game#story#hydrate(l:next_state)
endfunction
