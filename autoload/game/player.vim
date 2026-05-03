" autoload/game/player.vim - Player Mechanics

function! game#player#cmd_use(state, item) abort
  if empty(a:item)
    return game#core#add_log(a:state, "LOG_ERR: Specify an item to use (e.g. 'use Pollen Vial').")
  endif
  
  let l:idx = -1
  for i in range(len(a:state.player.inv))
    if tolower(a:state.player.inv[i]) ==# tolower(a:item) || tolower(a:state.player.inv[i]) =~# '^' . tolower(a:item)
      let l:idx = i
      break
    endif
  endfor
  
  if l:idx == -1
    return game#core#add_log(a:state, "ITEM_ERR: You do not possess '" . a:item . "'.")
  endif
  
  let l:matched_item = a:state.player.inv[l:idx]
  let l:next_state = copy(a:state)
  let l:next_state.player = copy(a:state.player)
  let l:next_state.player.inv = copy(a:state.player.inv)
  
  call remove(l:next_state.player.inv, l:idx)
  
  if l:matched_item ==# 'Pollen Vial' || l:matched_item ==# 'Abyssal Ash'
    let l:heal = 50
    let l:next_state.player.hp += l:heal
    if l:next_state.player.hp > l:next_state.player.max_hp
      let l:next_state.player.hp = l:next_state.player.max_hp
    endif
    return game#core#add_log(l:next_state, ["CONSUMED: " . l:matched_item, "EFFECT: Healed " . l:heal . " HP."])
  else
    return game#core#add_log(l:next_state, ["USED: " . l:matched_item, "EFFECT: Nothing happens. The relic dissipates into the ether."])
  endif
endfunction

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
        \ 'STR: ' . a:state.player.str . ' | AGI: ' . a:state.player.agi . ' | ARC: ' . a:state.player.arc,
        \ 'Spells:'
        \ ]
  for l:sp in a:state.player.spells
    call add(l:lines, ' - ' . l:sp)
  endfor
  call add(l:lines, '----------------------')
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

function! game#player#cmd_save(state) abort
  let l:json = json_encode(a:state)
  let l:save_path = expand('~/.quadar_save.json')
  call writefile([l:json], l:save_path)
  return game#core#add_log(a:state, "SYSTEM_LOG: State matrix serialized and saved to " . l:save_path)
endfunction

function! game#player#cmd_load(state) abort
  let l:save_path = expand('~/.quadar_save.json')
  if !filereadable(l:save_path)
    return game#core#add_log(a:state, "LOG_ERR_CRITICAL: No neural backup detected at " . l:save_path)
  endif
  
  try
    let l:json = readfile(l:save_path)[0]
    let l:next_state = json_decode(l:json)
    return game#core#add_log(l:next_state, "SYSTEM_LOG: State matrix restored from neural backup.")
  catch
    return game#core#add_log(a:state, "LOG_ERR_CRITICAL: Neural backup corrupted.")
  endtry
endfunction
