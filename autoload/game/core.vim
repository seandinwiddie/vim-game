" autoload/game/core.vim - Quadar Micro-MUD Functional Core

" === PURE DATA: ROOMS ===
let s:nexus = {'name': 'Merchandise Store Room', 'desc': 'A bunker-like emporium in Quadar Tower. Shadows dance with archaic electronic goth echoes.', 'exits': {'north': 'hallway'}}
let s:hallway = {'name': 'Dark Corridor', 'desc': 'A narrow passage of obsidian stone. The air hums with chthonic frequencies.', 'exits': {'south': 'nexus', 'north': 'spire_base'}}
let s:spire_base = {'name': 'Base of Quadar Tower', 'desc': 'A colossal structure vibrating with low magic. Neon lights flicker in the Abyssal Murk.', 'exits': {'south': 'hallway'}}

let s:rooms = {'nexus': s:nexus, 'hallway': s:hallway, 'spire_base': s:spire_base}

" === PURE LOGIC: INITIAL STATE ===
function! game#core#init() abort
  return {'view': 'game', 'player': {'name': 'Kamenal', 'class': 'Rogue/Ranger', 'level': 12, 'hp': 150, 'max_hp': 150, 'inv': ['Basic Dagger', 'Scout Gear']}, 'loc': 'nexus', 'surge': 0, 'log': ['*** WELCOME TO QUA''DAR ***', 'You materialize in the Merchandise Store Room.']}
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

  return s:add_log(a:state, "Unknown command: " . l:action)
endfunction

" === INTERNAL PURE HELPERS ===

function! s:cmd_look(state) abort
  let l:room = s:rooms[a:state.loc]
  let l:msg = [l:room.name, l:room.desc, "Exits: " . join(keys(l:room.exits), ', ')]
  return s:add_log(a:state, l:msg)
endfunction

function! s:cmd_go(state, dir) abort
  let l:room = s:rooms[a:state.loc]
  let l:dir_map = {'n': 'north', 's': 'south', 'e': 'east', 'w': 'west'}
  let l:target_dir = get(l:dir_map, a:dir, a:dir)
  
  if has_key(l:room.exits, l:target_dir)
    let l:new_loc = l:room.exits[l:target_dir]
    let l:next_state = copy(a:state)
    let l:next_state.loc = l:new_loc
    let l:next_state = s:add_log(l:next_state, "You travel " . l:target_dir . " to " . s:rooms[l:new_loc].name)
    return s:cmd_look(l:next_state)
  endif
  return s:add_log(a:state, "You cannot go " . l:target_dir)
endfunction

function! s:cmd_scavenge(state) abort
  " Simple pseudo-random using frame counter if available, or just reltime
  let l:val = str2nr(split(reltimestr(reltime()), '\.')[1])
  let l:roll = (l:val % 100) + 1
  let l:surge = a:state.surge
  let l:modified_roll = (l:roll > 50) ? (l:roll + l:surge) : (l:roll - l:surge)
  
  let l:res = ""
  let l:new_surge = l:surge
  if l:modified_roll >= 81
    let l:res = "Success! You found a Relic Shard."
    let l:new_surge = 0
  elseif l:modified_roll >= 51
    let l:res = "Yes, you find some zinc scrap."
    let l:new_surge += 2
  elseif l:modified_roll >= 21
    let l:res = "No, the area is picked clean."
    let l:new_surge += 2
  else
    let l:res = "Unexpectedly! A Voidwraith emerges from the murk!"
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
  " Keep last 50 lines
  if len(l:next_state.log) > 50
    let l:next_state.log = l:next_state.log[-50:]
  endif
  return l:next_state
endfunction

function! game#core#render(state) abort
  return a:state.log
endfunction
