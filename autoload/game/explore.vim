" autoload/game/explore.vim - Exploration Mechanics

function! game#explore#cmd_look(state) abort
  let l:room = a:state.rooms[a:state.loc]
  let l:next_state = copy(a:state)
  let l:next_state.hint = 'DIRECTIVE: Use "go [dir]" to explore, or "ask" the oracle.'
  let l:lines = [
        \ '---',
        \ l:room.name,
        \ l:room.desc
        \ ]
        
  if !empty(l:room.entities)
    call add(l:lines, 'DETECTED ENTITIES:')
    for l:ent in l:room.entities
      call add(l:lines, '  > [!!] ' . l:ent)
    endfor
    let l:next_state.hint = 'DIRECTIVE: Hostiles detected! Type "attack" to engage!'
  endif
  
  call add(l:lines, 'ᚱ ENTRANCES: ' . join(keys(l:room.exits), ', '))
  call add(l:lines, '[HP: ' . a:state.player.hp . '/' . a:state.player.max_hp . ']')
  call add(l:lines, '--')
  return game#core#add_log(l:next_state, l:lines)
endfunction

function! game#explore#cmd_go(state, dir) abort
  let l:room = a:state.rooms[a:state.loc]
  let l:dir_map = {'n': 'north', 's': 'south', 'e': 'east', 'w': 'west'}
  let l:target_dir = get(l:dir_map, a:dir, a:dir)
  
  if has_key(l:room.exits, l:target_dir)
    let l:new_loc = l:room.exits[l:target_dir]
    let l:next_state = copy(a:state)
    let l:next_state.loc = l:new_loc
    let l:next_state.hint = 'DIRECTIVE: Area change detected. "look" to update sensor data.'
    let l:next_state = game#core#add_log(l:next_state, "NEURAL_TRACKING: Shifting coordinates to " . l:target_dir)
    return game#explore#cmd_look(l:next_state)
  endif
  return game#core#add_log(a:state, "PHYSICS_LOGIC_ERR: Cannot penetrate " . l:target_dir)
endfunction
