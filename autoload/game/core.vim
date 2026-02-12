" autoload/game/core.vim - Quadar Micro-MUD Functional Core

" === PURE DATA: ROOMS (Cyber Grimdark Refactor) ===
let s:nexus = {
      \ 'name': 'ᚠ MERCHANDISE_STORE_ROOM ᚠ',
      \ 'desc': "A bunker-like emporium, a maggot pile within the starry settlement of Quadar Tower. Shadows dance with the echoes of ancient electronic goth logic. You preside over this emporium, brokering eldritch artifacts amid shadowed corridors.",
      \ 'exits': {'north': 'hallway'}
      \ }
let s:hallway = {
      \ 'name': 'ᚢ UMBRAL_REACH_CORRIDOR ᚢ',
      \ 'desc': "A narrow passage of obsidian stone, crystallized in extraterrestrial resonance. The air hums with chthonic frequencies pulsating from the core. Shadows meld slitheringly against the rain-slicked walls.",
      \ 'exits': {'south': 'nexus', 'north': 'spire_base'}
      \ }
let s:spire_base = {
      \ 'name': 'ᚦ BASTION_OF_THE_SPIRE ᚦ',
      \ 'desc': "The indomitable tower stands as a testament to long-ago awakening. Colossal structure vibrating with low magic of corrupt watchers. Neon blurs in the Abyssal Murk, a world scorched by armageddon's fiery breath.",
      \ 'exits': {'south': 'hallway'}
      \ }

let s:rooms = {'nexus': s:nexus, 'hallway': s:hallway, 'spire_base': s:spire_base}

" === PURE LOGIC: INITIAL STATE ===
function! game#core#init() abort
  let l:s = {
        \ 'view': 'game',
        \ 'player': {'name': 'Kamenal', 'class': 'Rogue/Ranger', 'level': 12, 'hp': 150, 'max_hp': 150, 'inv': ['Basic Dagger', 'Scout Gear']},
        \ 'loc': 'nexus',
        \ 'surge': 0,
        \ 'log': []
        \ }
  return s:add_log(l:s, ['NEURAL_LINK_ESTABLISHED', 'SYSTEM_OVERRIDE: INITIATING RECONNAISSANCE PROTOCOL ᚠ', 'You materialize in the Merchandise Store Room.'])
endfunction

" === PURE LOGIC: COMMAND PROCESSING ===
function! game#core#process(state, input) abort
  let l:cmd = tolower(trim(a:input))
  let l:parts = split(l:cmd)
  if empty(l:parts) | return a:state | endif
  
  let l:action = l:parts[0]
  if l:action ==# 'look' || l:action ==# 'l'
    return s:cmd_look(a:state)
  elseif l:action ==# 'go' || l:action ==# 'n' || l:action ==# 's' || l:action ==# 'e' || l:action ==# 'w'
    let l:dir = (len(l:parts) > 1) ? l:parts[1] : l:action
    return s:cmd_go(a:state, l:dir)
  elseif l:action ==# 'scavenge'
    return s:cmd_scavenge(a:state)
  endif

  return s:add_log(a:state, "LOG_ERR_CRITICAL: Unknown input_vector '" . l:action . "'")
endfunction

" === INTERNAL PURE HELPERS ===

function! s:cmd_look(state) abort
  let l:room = s:rooms[a:state.loc]
  let l:lines = [
        \ '---',
        \ l:room.name,
        \ l:room.desc,
        \ 'ᚱ ENTRANCES: ' . join(keys(l:room.exits), ', '),
        \ '[HP: ' . a:state.player.hp . '/' . a:state.player.max_hp . ']',
        \ '--'
        \ ]
  return s:add_log(a:state, l:lines)
endfunction

function! s:cmd_go(state, dir) abort
  let l:room = s:rooms[a:state.loc]
  let l:dir_map = {'n': 'north', 's': 'south', 'e': 'east', 'w': 'west'}
  let l:target_dir = get(l:dir_map, a:dir, a:dir)
  
  if has_key(l:room.exits, l:target_dir)
    let l:new_loc = l:room.exits[l:target_dir]
    let l:next_state = copy(a:state)
    let l:next_state.loc = l:new_loc
    let l:next_state = s:add_log(l:next_state, "NEURAL_TRACKING: Shifting coordinates to " . l:target_dir)
    return s:cmd_look(l:next_state)
  endif
  return s:add_log(a:state, "PHYSICS_LOGIC_ERR: Cannot penetrate " . l:target_dir)
endfunction

function! s:cmd_scavenge(state) abort
  let l:val = str2nr(split(reltimestr(reltime()), '\.')[1])
  let l:roll = (l:val % 100) + 1
  let l:surge = a:state.surge
  let l:modified_roll = (l:roll > 50) ? (l:roll + l:surge) : (l:roll - l:surge)
  
  let l:res = ""
  let l:new_surge = l:surge
  if l:modified_roll >= 96
    let l:res = "SYSTEM_UPDATE: Yes, and unexpectedly... A GIBSONIAN RELIC SHARD FOUND ᚠ."
    let l:new_surge = 0
  elseif l:modified_roll >= 51
    let l:res = "LOG_RECO: YES. Scrap iron secured for the Order."
    let l:new_surge += 2
  elseif l:modified_roll >= 21
    let l:res = "LOG_RECO: NO. The void yields nothing but static."
    let l:new_surge += 2
  else
    let l:res = "LOG_ERR_CRITICAL: UNEXPECTED VOIDWRAITH MANIFESTATION."
    let l:new_surge = 0
  endif

  let l:next_state = copy(a:state)
  let l:next_state.surge = l:new_surge
  return s:add_log(l:next_state, "[Loom of Fate: " . l:modified_roll . "] " . l:res)
endfunction

function! s:add_log(state, msg) abort
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
  let l:header = [
        \ "ᚠ ᛫ ᛟ ᛫ ᚱ ᛫ ᛒ ᛫ ᛟ ᛫ ᚲ",
        \ "== QUA'DAR NEURAL LINK ==",
        \ "Surge Count: " . a:state.surge,
        \ ""
        \ ]
  return l:header + a:state.log
endfunction
