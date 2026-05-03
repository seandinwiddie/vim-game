" autoload/game/player.vim - Player Mechanics

function! game#player#heal(state, amount) abort
  let a:state.player.hp = min([a:state.player.max_hp, a:state.player.hp + a:amount])
  return a:state
endfunction

function! game#player#cmd_use(state, item) abort
  let l:match = game#match#one(a:state.player.inv, a:item)
  if get(l:match, 'ambiguous', 0)
    return game#core#add_log(a:state, "ITEM_ERR: '" . a:item . "' matches multiple items: " . join(l:match.matches, ', ') . '.')
  endif
  if !get(l:match, 'found', 0)
    return game#core#add_log(a:state, "ITEM_ERR: You do not possess '" . a:item . "'.")
  endif
  
  let l:idx = l:match.index
  let l:matched_item = a:state.player.inv[l:idx]
  let l:next_state = a:state
  
  call remove(l:next_state.player.inv, l:idx)
  
  if l:matched_item ==# 'Pollen Vial' || l:matched_item ==# 'Abyssal Ash'
    let l:heal = game#tuning#get('player.consumables.pollen_vial_heal')
    let l:next_state = game#player#heal(l:next_state, l:heal)
    return game#core#add_log(l:next_state, ["CONSUMED: " . l:matched_item, "EFFECT: Healed " . l:heal . " HP."])
  elseif l:matched_item ==# 'Field Rations'
    let l:heal = game#tuning#get('player.consumables.field_rations_heal')
    let l:next_state = game#player#heal(l:next_state, l:heal)
    return game#core#add_log(l:next_state, ["CONSUMED: " . l:matched_item, "EFFECT: Restored " . l:heal . " HP."])
  elseif l:matched_item ==# 'Ranger Field Kit'
    let l:field_kit = game#tuning#get('player.consumables.ranger_field_kit')
    let l:next_state = game#player#heal(l:next_state, l:field_kit.heal)
    let l:next_state.guard += l:field_kit.guard
    return game#core#add_log(l:next_state, ["DEPLOYED: " . l:matched_item, "EFFECT: Restored " . l:field_kit.heal . " HP and reinforced your guard by " . l:field_kit.guard . "."])
  else
    return game#core#add_log(l:next_state, ["USED: " . l:matched_item, "EFFECT: Nothing happens. The relic dissipates into the ether."])
  endif
endfunction

function! game#player#cmd_inventory(state) abort
  let l:next_state = a:state
  let l:next_state.hint = 'DIRECTIVE: Local inventory cache accessed.'
  let l:lines = ['--- SECURED RELICS ---', game#economy#status_label(a:state)]
  for l:item in a:state.player.inv
    call add(l:lines, ' [ᛟ] ' . l:item)
  endfor
  call add(l:lines, '----------------------')
  return game#core#add_log(l:next_state, l:lines)
endfunction

function! game#player#cmd_profile(state) abort
  let l:next_state = a:state
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
  let l:next_state = a:state
  let l:rest_tuning = game#tuning#get('player.rest')
  
  if l:next_state.player.hp >= l:next_state.player.max_hp
    return game#core#add_log(a:state, "SYSTEM_LOG: HP is already maximum. Resting aborted.")
  endif

  let l:heal = l:rest_tuning.heal
  let l:next_state = game#player#heal(l:next_state, l:heal)
  
  let l:next_state.surge += l:rest_tuning.surge_gain
  let l:next_state.hint = 'WARNING: Resting increases the Surge Count!'
  let l:log_lines = ["You rest in the shadows...", "HEALED: +" . l:heal . " HP.", "TENSION RISING: Surge Count increased by " . l:rest_tuning.surge_gain . "."]

  let l:rng = game#rng#next(l:next_state)
  let l:next_state = l:rng.state
  let l:val = l:rng.value
  if (l:val % 100) > l:rest_tuning.spawn_threshold
    if !has_key(l:next_state, 'rooms')
      let l:next_state.rooms = {}
    endif
    let l:room = l:next_state.rooms[a:state.loc]

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
  let l:save_path = s:save_path()
  call writefile([l:json], l:save_path)
  return game#core#add_log(a:state, "SYSTEM_LOG: State matrix serialized and saved to " . l:save_path)
endfunction

function! game#player#cmd_load(state) abort
  let l:save_path = s:save_path()
  if !filereadable(l:save_path)
    return s:load_error(a:state, 'no_save_found', 'No neural backup detected at ' . l:save_path)
  endif

  try
    let l:contents = readfile(l:save_path)
  catch
    return s:load_error(a:state, 'no_save_found', 'Unable to read neural backup at ' . l:save_path, s:format_exception(v:exception))
  endtry

  if empty(l:contents)
    return s:load_error(a:state, 'save_corrupted', 'Neural backup is empty.', 'DETAIL: Save file contained no JSON payload.')
  endif

  try
    let l:decoded = json_decode(join(l:contents, "\n"))
  catch
    return s:load_error(a:state, 'save_corrupted', 'Neural backup JSON malformed.', 'DETAIL: ' . s:format_exception(v:exception))
  endtry

  let l:schema_issues = s:load_schema_issues(l:decoded)
  if !empty(l:schema_issues)
    return s:load_error(a:state, 'save_outdated', 'Neural backup schema mismatch. Older saves need a migration step before loading.', 'DETAIL: Missing or invalid fields: ' . join(l:schema_issues, ', '))
  endif

  try
    let l:next_state = game#core#normalize(l:decoded)
  catch
    return s:load_error(a:state, 'save_outdated', 'Neural backup schema mismatch. Older saves need a migration step before loading.', 'DETAIL: ' . s:format_exception(v:exception))
  endtry

  return game#core#add_log(l:next_state, "SYSTEM_LOG: State matrix restored from neural backup.")
endfunction

function! s:save_path() abort
  return expand('~/.quadar_save.json')
endfunction

function! s:load_error(state, code, message, ...) abort
  let l:lines = ['LOG_ERR_CRITICAL: ' . a:code . ' :: ' . a:message]
  if a:0 > 0 && !empty(a:1)
    call add(l:lines, a:1)
  endif
  return game#core#add_log(a:state, l:lines)
endfunction

function! s:format_exception(exception) abort
  return substitute(a:exception, '^Vim([^)]*):', '', '')
endfunction

function! s:load_schema_issues(decoded) abort
  let l:issues = []
  if type(a:decoded) != v:t_dict
    return ['root(dict)']
  endif

  for l:key in ['player', 'loc', 'rooms']
    if !has_key(a:decoded, l:key)
      call add(l:issues, l:key)
    endif
  endfor

  if has_key(a:decoded, 'player')
    if type(a:decoded.player) != v:t_dict
      call add(l:issues, 'player(dict)')
    else
      for l:key in ['name', 'class', 'level', 'hp', 'max_hp', 'inv', 'spells']
        if !has_key(a:decoded.player, l:key)
          call add(l:issues, 'player.' . l:key)
        endif
      endfor
    endif
  endif

  if has_key(a:decoded, 'loc') && type(a:decoded.loc) != v:t_string
    call add(l:issues, 'loc(string)')
  endif
  if has_key(a:decoded, 'rooms')
    if type(a:decoded.rooms) != v:t_dict
      call add(l:issues, 'rooms(dict)')
    else
      for [l:room_key, l:room_val] in items(a:decoded.rooms)
        if type(l:room_val) != v:t_dict
          call add(l:issues, 'rooms.' . l:room_key . '(dict)')
        else
          for l:req in ['id', 'biome', 'display_name']
            if !has_key(l:room_val, l:req)
              call add(l:issues, 'rooms.' . l:room_key . '.' . l:req)
            endif
          endfor
        endif
      endfor
      if has_key(a:decoded, 'loc') && type(a:decoded.loc) == v:t_string && !has_key(get(a:decoded, 'rooms', {}), a:decoded.loc)
        call add(l:issues, 'rooms.' . a:decoded.loc)
      endif
    endif
  endif

  return l:issues
endfunction

