" autoload/game/explore/travel.vim - Movement and Traversal

function! game#explore#travel#cmd_go(state, dir) abort
  let l:room = a:state.rooms[a:state.loc]
  let l:dir_map = {'n': 'north', 's': 'south', 'e': 'east', 'w': 'west'}
  let l:target_dir = get(l:dir_map, a:dir, a:dir)
  let l:inv_dir_map = {'north': 'south', 'south': 'north', 'east': 'west', 'west': 'east'}
  let l:inv_dir = get(l:inv_dir_map, l:target_dir, 'unknown')

  if !has_key(l:room.exits, l:target_dir)
    return game#core#add_log(a:state, 'PHYSICS_LOGIC_ERR: Cannot penetrate ' . l:target_dir)
  endif

  let l:next_state = deepcopy(a:state)
  let l:is_new_room = 0

  if l:room.exits[l:target_dir] ==# 'unexplored'
    let l:rng = game#rng#next(l:next_state)
    let l:next_state = l:rng.state
    let l:val = l:rng.value
    let l:room_id = 'proc_room_' . l:val
    let l:next_state.rooms[a:state.loc].exits[l:target_dir] = l:room_id

    let l:new_room = game#explore#procgen#generate_room(l:val, l:inv_dir, a:state.loc, l:next_state)
    let l:next_state.rooms[l:room_id] = l:new_room
    let l:is_new_room = 1
    let l:next_state = game#core#add_log(l:next_state, 'PROCEDURAL_GENERATION: New zone synthesized.')
  endif

  let l:new_loc = l:next_state.rooms[a:state.loc].exits[l:target_dir]
  let l:next_state.loc = l:new_loc
  let l:next_state = game#story#enter_location(l:next_state, l:new_loc, l:is_new_room)
  let l:next_state.hint = 'DIRECTIVE: Area change detected. "look" to update sensor data.'
  let l:next_state = game#core#add_log(l:next_state, 'NEURAL_TRACKING: Shifting coordinates to ' . l:target_dir)
  
  let l:target_room = l:next_state.rooms[l:new_loc]
  if l:target_room.biome ==# 'toxic'
    let l:rng = game#rng#next(l:next_state)
    let l:next_state = l:rng.state
    let l:val = l:rng.value
    let l:dmg = (l:val % 10) + 5
    let l:next_state.player.hp -= l:dmg
    let l:next_state = game#core#add_log(l:next_state, 'ENVIRONMENTAL HAZARD: The perilous terrain inflicts ' . l:dmg . ' damage.')
    if l:next_state.player.hp <= 0
      let l:next_state.player.hp = 0
      let l:next_state = game#core#add_log(l:next_state, 'FATAL_ERROR: NEURAL LINK SEVERED. YOU HAVE DIED.')
      let l:next_state.hint = 'GAME OVER: Type "q" to quit.'
    endif
  elseif l:target_room.biome ==# 'marsh'
    let l:next_state.surge += 2
    let l:next_state = game#core#add_log(l:next_state, 'ENVIRONMENTAL HAZARD: The thick mire exhausts you. Surge Count increased by 2.')
  elseif l:target_room.biome ==# 'void'
    let l:next_state = game#core#add_log(l:next_state, 'ENVIRONMENTAL ANOMALY: Spatial fabric distorts. Navigational telemetry is unstable.')
  endif

  return game#explore#view#cmd_look(l:next_state)
endfunction
