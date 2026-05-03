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
  let l:next_state = deepcopy(a:state)
  
  call remove(l:next_state.player.inv, l:idx)
  
  if l:matched_item ==# 'Pollen Vial' || l:matched_item ==# 'Abyssal Ash'
    let l:heal = game#tuning#get('player.consumables.pollen_vial_heal')
    let l:next_state.player.hp += l:heal
    if l:next_state.player.hp > l:next_state.player.max_hp
      let l:next_state.player.hp = l:next_state.player.max_hp
    endif
    return game#core#add_log(l:next_state, ["CONSUMED: " . l:matched_item, "EFFECT: Healed " . l:heal . " HP."])
  elseif l:matched_item ==# 'Field Rations'
    let l:heal = game#tuning#get('player.consumables.field_rations_heal')
    let l:next_state.player.hp = min([l:next_state.player.max_hp, l:next_state.player.hp + l:heal])
    return game#core#add_log(l:next_state, ["CONSUMED: " . l:matched_item, "EFFECT: Restored " . l:heal . " HP."])
  elseif l:matched_item ==# 'Ranger Field Kit'
    let l:field_kit = game#tuning#get('player.consumables.ranger_field_kit')
    let l:next_state.player.hp = min([l:next_state.player.max_hp, l:next_state.player.hp + l:field_kit.heal])
    let l:next_state.guard += l:field_kit.guard
    return game#core#add_log(l:next_state, ["DEPLOYED: " . l:matched_item, "EFFECT: Restored " . l:field_kit.heal . " HP and reinforced your guard by " . l:field_kit.guard . "."])
  else
    return game#core#add_log(l:next_state, ["USED: " . l:matched_item, "EFFECT: Nothing happens. The relic dissipates into the ether."])
  endif
endfunction

function! game#player#cmd_inventory(state) abort
  let l:next_state = copy(a:state)
  let l:next_state.hint = 'DIRECTIVE: Local inventory cache accessed.'
  let l:lines = ['--- SECURED RELICS ---', game#economy#status_label(a:state)]
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
        \ 'Trade: ' . get(a:state.player, 'trade', 0) . ' | Guard: ' . get(a:state, 'guard', 0),
        \ 'Mark: ' . (empty(get(a:state, 'mark', '')) ? 'none' : a:state.mark),
        \ 'Party Dynamics: +' . game#party#group_bonus(a:state),
        \ 'Spells:'
        \ ]
  for l:sp in a:state.player.spells
    call add(l:lines, ' - ' . l:sp)
  endfor
  if !empty(get(a:state.player, 'upgrades', []))
    call add(l:lines, 'Upgrades:')
    for l:upgrade in a:state.player.upgrades
      call add(l:lines, ' + ' . l:upgrade)
    endfor
  endif
  if !empty(get(a:state.player, 'companions', []))
    call add(l:lines, 'Companions (Party):')
    for l:c in a:state.player.companions
      let l:status = toupper(get(l:c, 'status', 'active'))
      let l:suffix = get(l:c, 'status', 'active') ==# 'elsewhere' && !empty(get(l:c, 'assignment', '')) ? ' | thread: ' . l:c.assignment : ''
      call add(l:lines, ' * ' . l:c.name . ' [' . l:status . '] [STR:' . get(l:c, 'str', 4) . ' AGI:' . get(l:c, 'agi', 4) . ' ARC:' . get(l:c, 'arc', 4) . ']' . l:suffix)
    endfor
  endif
  call add(l:lines, '----------------------')
  return game#core#add_log(l:next_state, l:lines)
endfunction

function! game#player#cmd_rest(state) abort
  let l:next_state = copy(a:state)
  let l:next_state.player = copy(a:state.player)
  let l:rest_tuning = game#tuning#get('player.rest')
  
  if l:next_state.player.hp >= l:next_state.player.max_hp
    return game#core#add_log(a:state, "SYSTEM_LOG: HP is already maximum. Resting aborted.")
  endif

  let l:heal = l:rest_tuning.heal
  let l:next_state.player.hp += l:heal
  if l:next_state.player.hp > l:next_state.player.max_hp
    let l:next_state.player.hp = l:next_state.player.max_hp
  endif
  
  let l:next_state.surge += l:rest_tuning.surge_gain
  let l:next_state.hint = 'WARNING: Resting increases the Surge Count!'
  let l:log_lines = ["You rest in the shadows...", "HEALED: +" . l:heal . " HP.", "TENSION RISING: Surge Count increased by " . l:rest_tuning.surge_gain . "."]

  let l:rng = game#rng#next(l:next_state)
  let l:next_state = l:rng.state
  let l:val = l:rng.value
  if (l:val % 100) > l:rest_tuning.spawn_threshold
    if !has_key(l:next_state, 'rooms')
      let l:next_state.rooms = copy(a:state.rooms)
    endif
    let l:room = l:next_state.rooms[a:state.loc]
    let l:next_state.rooms[a:state.loc] = copy(l:room)
    let l:next_state.rooms[a:state.loc].entities = copy(l:room.entities)

    let l:enemies = game#enemies#select(['Ashwalker', 'Aether Spirit', 'Voidwraith', 'Obsidian Warden'])
    let l:spawned = deepcopy(l:enemies[(l:val / 3) % len(l:enemies)])
    call add(l:next_state.rooms[a:state.loc].entities, l:spawned)
    call add(l:log_lines, "DYNAMIC SPAWN: The shadows shift! A " . l:spawned.name . " found you while resting!")
    let l:next_state.hint = 'WARNING: Hostile entity detected. Prepare for combat!'
  endif

  return game#core#add_log(l:next_state, l:log_lines)
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
    let l:next_state = game#core#normalize(json_decode(l:json))
    return game#core#add_log(l:next_state, "SYSTEM_LOG: State matrix restored from neural backup.")
  catch
    return game#core#add_log(a:state, "LOG_ERR_CRITICAL: Neural backup corrupted.")
  endtry
endfunction
