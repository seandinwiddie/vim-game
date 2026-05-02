" autoload/game/player.vim - Player Mechanics

function! game#player#cmd_inventory(state) abort
  let l:next_state = copy(a:state)
  let l:next_state.hint = 'DIRECTIVE: Local inventory cache accessed.'
  let l:lines = ['--- SECURED RELICS ---']
  for l:item in a:state.player.inv
    call add(l:lines, ' [ᛟ] ' . l:item)
  endfor
  call add(l:lines, '----------------------')
  return game#core#add_log(l:next_state, l:lines)
endfunction

function! game#player#cmd_profile(state) abort
  let l:next_state = copy(a:state)
  let l:next_state.hint = 'DIRECTIVE: Neural diagnostic complete.'
  let l:lines = [
        \ '--- PLAYER PROFILE ---',
        \ 'Name:  ' . a:state.player.name,
        \ 'Class: ' . a:state.player.class,
        \ 'Level: ' . a:state.player.level,
        \ 'HP:    ' . a:state.player.hp . ' / ' . a:state.player.max_hp,
        \ '----------------------'
        \ ]
  return game#core#add_log(l:next_state, l:lines)
endfunction

function! game#player#cmd_rest(state) abort
  let l:next_state = copy(a:state)
  let l:next_state.player = copy(a:state.player)
  
  if l:next_state.player.hp >= l:next_state.player.max_hp
    return game#core#add_log(a:state, "SYSTEM_LOG: HP is already maximum. Resting aborted.")
  endif

  let l:heal = 30
  let l:next_state.player.hp += l:heal
  if l:next_state.player.hp > l:next_state.player.max_hp
    let l:next_state.player.hp = l:next_state.player.max_hp
  endif
  
  let l:next_state.surge += 5
  let l:next_state.hint = 'WARNING: Resting increases the Surge Count!'
  return game#core#add_log(l:next_state, ["You rest in the shadows...", "HEALED: +" . l:heal . " HP.", "TENSION RISING: Surge Count increased by 5."])
endfunction
