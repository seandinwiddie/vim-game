" autoload/game/explore.vim - Exploration Facade

function! game#explore#cmd_look(state) abort
  return game#explore#view#cmd_look(a:state)
endfunction

function! game#explore#cmd_interact(state, object_name) abort
  return game#explore#interact#cmd_interact(a:state, a:object_name)
endfunction

function! game#explore#cmd_go(state, dir) abort
  return game#explore#travel#cmd_go(a:state, a:dir)
endfunction

function! game#explore#generate_room(seed, entrance_dir, entrance_id, state) abort
  return game#explore#procgen#generate_room(a:seed, a:entrance_dir, a:entrance_id, a:state)
endfunction
