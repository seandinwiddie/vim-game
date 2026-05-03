" autoload/game/explore/interact.vim - Interactive Objects

function! game#explore#interact#cmd_interact(state, object_name) abort
  if empty(a:object_name)
    return game#core#add_log(a:state, "LOG_ERR: Specify an object to interact with (e.g. 'interact Arcane Terminal').")
  endif

  let l:room = a:state.rooms[a:state.loc]
  if !has_key(l:room, 'objects') || empty(l:room.objects)
    return game#core#add_log(a:state, 'LOG_ERR: There is nothing to interact with here.')
  endif

  let l:match = s:match_object(l:room.objects, a:object_name)
  if !l:match.found
    return game#core#add_log(a:state, "LOG_ERR: You don't see a '" . a:object_name . "' here.")
  endif

  let l:matched_obj = l:match.object
  let l:desc = type(l:matched_obj) == v:t_dict ? get(l:matched_obj, 'desc', 'It does nothing.') : 'It does nothing.'
  let l:name = type(l:matched_obj) == v:t_dict ? get(l:matched_obj, 'name', 'Unknown Object') : l:matched_obj

  let l:next_state = deepcopy(a:state)
  let l:effect = type(l:matched_obj) == v:t_dict ? get(l:matched_obj, 'effect', '') : ''
  let l:consume_object = 0
  let l:log_lines = ['INTERACT: You examine the ' . l:name . '.', l:desc]

  if l:effect ==# 'briefing'
    call s:apply_briefing(l:next_state, l:log_lines)
  elseif l:effect ==# 'unlock_exit'
    let l:new_dir = s:first_hidden_exit(l:next_state.rooms[a:state.loc].exits)
    if empty(l:new_dir)
      call add(l:log_lines, 'MECHANISM STALL: No additional passage responds to the sigils.')
    else
      let l:next_state.rooms[a:state.loc].exits[l:new_dir] = 'unexplored'
      let l:consume_object = 1
      call add(l:log_lines, 'MAP SHIFT: Stone plates grind aside, revealing a hidden route to the ' . l:new_dir . '.')
    endif
  elseif l:effect ==# 'rescue_ranger'
    let l:consume_object = 1
    let l:next_state = game#story#records#assign_scene_npc(l:next_state, l:next_state.loc, 'Bound Ranger')
    let l:next_state = game#story#threads#record_npc_for_thread(l:next_state, 'Find Missing Rangers', 'Bound Ranger')
    call add(l:log_lines, 'EXTRACTION: You cut a stranded ranger free and fold them back into the recon circuit.')
    if index(l:next_state.player.inv, 'Ranger Signal Token') == -1
      call add(l:next_state.player.inv, 'Ranger Signal Token')
      call add(l:log_lines, 'RECOVERED: Ranger Signal Token')
    endif
    let l:next_state = game#party#add_companion(l:next_state, game#party#create('Ranger Operative', 5, 5, 3))
    let l:next_state = game#party#sync_scene(l:next_state)
    let l:next_state = game#story#threads#record_npc_for_thread(l:next_state, 'Find Missing Rangers', 'Ranger Operative')
    call add(l:log_lines, 'PARTY UPDATE: Ranger Operative joins your unit, providing Group Dynamics bonuses in combat.')
    let l:quest_progress = game#story#advance_quest(l:next_state, 'rescue-rangers', 1)
    let l:next_state = l:quest_progress.state
    let l:next_state = game#story#record_fact_for_thread(l:next_state, 'Find Missing Rangers', 'A bound ranger was extracted alive from ' . l:next_state.rooms[a:state.loc].name . '.')
    let l:log_lines += l:quest_progress.log
  elseif l:effect ==# 'recover_tome'
    let l:consume_object = 1
    if index(l:next_state.player.inv, 'Lost Tomes') == -1
      call add(l:next_state.player.inv, 'Lost Tomes')
    endif
    call add(l:log_lines, 'ARCHIVE RECOVERED: The reliquary yields a stack of codices and return sigils.')
    let l:quest_progress = game#story#advance_quest(l:next_state, 'recover-lost-tomes', 1)
    let l:next_state = l:quest_progress.state
    let l:next_state = game#story#record_fact_for_thread(l:next_state, 'Recover the Lost Tomes', 'A sealed reliquary yielded codices and return sigils in ' . l:next_state.rooms[a:state.loc].name . '.')
    let l:log_lines += l:quest_progress.log
  elseif l:effect ==# 'purify_altar'
    let l:consume_object = 1
    call add(l:log_lines, 'SANCTIFICATION: You channel pure energy into the altar, cleansing the eldritch taint.')
    let l:heal = 15
    let l:next_state.player.hp = min([l:next_state.player.max_hp, l:next_state.player.hp + l:heal])
    call add(l:log_lines, 'RECOVERED: The holy resonance restores ' . l:heal . ' HP.')
    let l:quest_progress = game#story#advance_quest(l:next_state, 'purify-altars', 1)
    let l:next_state = l:quest_progress.state
    let l:next_state = game#story#record_fact_for_thread(l:next_state, 'Purify the Eldritch Altars', 'A corrupted altar was purified in ' . l:next_state.rooms[a:state.loc].name . '.')
    let l:log_lines += l:quest_progress.log
  elseif l:effect ==# 'field_cache'
    let l:consume_object = 1
    let l:next_state.player.hp = min([l:next_state.player.max_hp, l:next_state.player.hp + 20])
    call add(l:next_state.player.inv, 'Field Rations')
    call add(l:log_lines, 'CACHE BREACH: You recover field rations and patch your wounds for +20 HP.')
  elseif l:effect ==# 'hidden_lore'
    let l:consume_object = 1
    let l:lore_list = [
          \ "The Spire Bastion was built not to keep enemies out, but to keep the Eldritch Overfiends in.",
          \ "The Corrupted Altars are siphoning life force from the Ethereal Marshes.",
          \ "Migdal Kudar predates the Rangers by eons, built by Chthonic deities.",
          \ "The missing rangers were not captured; they surrendered willingly to the whispers.",
          \ "The Loom of Fate weaves with strands of pure dark matter from the Dimensional Nexus."
          \ ]
    let l:val = str2nr(split(reltimestr(reltime()), '\.')[1])
    let l:lore = l:lore_list[l:val % len(l:lore_list)]
    call add(l:log_lines, 'HIDDEN LORE DISCOVERED: ' . l:lore)
    let l:focus_name = game#story#focus_label(l:next_state)
    let l:next_state = game#story#record_fact_for_thread(l:next_state, l:focus_name, 'LORE: ' . l:lore)
    call add(l:log_lines, 'THREAD UPDATED: Forbidden truth appended to the active focus thread.')
  elseif l:effect ==# 'surge_rift'
    let l:consume_object = 1
    let l:next_state.surge += 3
    call add(l:log_lines, 'RIFT BACKLASH: The void surges through the link and spikes the Surge Count by 3.')
  elseif l:effect ==# 'portal_jump'
    let l:portal_result = s:traverse_portal(l:next_state, a:state.loc, l:match.index)
    let l:next_state = l:portal_result.state
    let l:log_lines += l:portal_result.log
    return game#explore#view#cmd_look(game#core#add_log(l:next_state, l:log_lines))
  else
    let l:val = str2nr(split(reltimestr(reltime()), '\.')[1])
    if (l:val % 100) > 70
      call add(l:log_lines, 'EVENT TRIGGERED: A hidden compartment opens!')
      call add(l:next_state.player.inv, 'Lost Tomes')
      call add(l:log_lines, 'LOOT RECOVERED: Lost Tomes')
    endif
  endif

  if l:consume_object && l:match.index >= 0
    call remove(l:next_state.rooms[a:state.loc].objects, l:match.index)
  endif

  return game#core#add_log(l:next_state, l:log_lines)
endfunction

function! s:match_object(objects, object_name) abort
  let l:idx = 0
  for l:obj in a:objects
    let l:name = type(l:obj) == v:t_dict ? get(l:obj, 'name', '') : l:obj
    if tolower(l:name) ==# tolower(a:object_name) || tolower(l:name) =~# '^' . tolower(a:object_name)
      return {'found': 1, 'object': l:obj, 'index': l:idx}
    endif
    let l:idx += 1
  endfor
  return {'found': 0, 'object': {}, 'index': -1}
endfunction

function! s:apply_briefing(state, log_lines) abort
  if get(a:state.flags, 'terminal_briefed', 0)
    call add(a:log_lines, 'BRIEFING CACHE: The terminal still points toward the missing rangers, scattered codices, and unholy altars.')
    return
  endif

  let a:state.flags.terminal_briefed = 1
  let l:quest_result = game#story#ensure_quest(a:state, {
        \ 'id': 'recover-lost-tomes',
        \ 'title': 'Recover the Lost Tomes',
        \ 'thread': 'Recover the Lost Tomes',
        \ 'objective': 'Find an intact reliquary and recover the codices used to send captives home.',
        \ 'target_hint': 'Search consoles, reliquaries, and archive caches in newly generated sectors.',
        \ 'status': 'active',
        \ 'progress': 0,
        \ 'goal': 1,
        \ 'reward_item': 'Signal Codex',
        \ 'reward_spell': 'Dark Crystal Shielding'
        \ })
  call extend(a:state, l:quest_result.state, 'force')
  
  let l:altar_quest = game#story#ensure_quest(a:state, {
        \ 'id': 'purify-altars',
        \ 'title': 'Purify the Eldritch Altars',
        \ 'thread': 'Purify the Eldritch Altars',
        \ 'objective': 'Sanctify corrupted altars found in accursed chapels and temples to weaken the abyss.',
        \ 'target_hint': 'Search for Corrupted Altars in Haunted Chapels or Rune Temples.',
        \ 'status': 'active',
        \ 'progress': 0,
        \ 'goal': 2,
        \ 'reward_item': 'Eldritch Medallion',
        \ 'reward_spell': 'Resurgence Ritual'
        \ })
  call extend(a:state, l:altar_quest.state, 'force')

  let l:updated_state = game#story#record_fact_for_thread(a:state, 'Find Missing Rangers', 'Terminal telemetry confirms the missing rangers are still alive beyond the tower shell.')
  call extend(a:state, l:updated_state, 'force')
  let l:updated_state = game#story#record_fact_for_thread(a:state, 'Recover the Lost Tomes', 'Archive traces point to codices capable of sending captives home.')
  call extend(a:state, l:updated_state, 'force')
  let l:updated_state = game#story#record_fact_for_thread(a:state, 'Purify the Eldritch Altars', 'Demonic taint in the chapels is fueling the tower; the altars must be cleansed.')
  call extend(a:state, l:updated_state, 'force')

  call add(a:log_lines, 'MISSION UPDATE: Recon protocol refreshed. Missing rangers are still alive somewhere beyond the tower shell.')
  call add(a:log_lines, 'MISSION UPDATE: Archive traces reveal codices capable of sending captives home.')
  call add(a:log_lines, 'MISSION UPDATE: Demonic taint detected. Purify the altars in chapels and temples.')
  if l:quest_result.added
    call add(a:log_lines, 'OBJECTIVE ADDED: Recover the Lost Tomes')
  endif
  if l:altar_quest.added
    call add(a:log_lines, 'OBJECTIVE ADDED: Purify the Eldritch Altars')
  endif
endfunction

function! s:first_hidden_exit(exits) abort
  for l:dir in ['north', 'south', 'east', 'west']
    if !has_key(a:exits, l:dir)
      return l:dir
    endif
  endfor
  return ''
endfunction

function! s:traverse_portal(state, source_loc, object_index) abort
  let l:next_state = deepcopy(a:state)
  let l:source_room = l:next_state.rooms[a:source_loc]
  let l:source_name = get(l:source_room, 'name', toupper(a:source_loc))
  let l:portal = l:source_room.objects[a:object_index]
  let l:target_room = get(l:portal, 'target_room', '')
  let l:is_new_room = 0
  let l:log_lines = []

  if empty(l:target_room)
    let l:val = str2nr(split(reltimestr(reltime()), '\.')[1])
    let l:target_room = 'portal_room_' . l:val
    let l:next_state.rooms[l:target_room] = game#explore#procgen#generate_portal_room(l:val, a:source_loc, l:next_state)
    let l:next_state.rooms[a:source_loc].objects[a:object_index].target_room = l:target_room
    let l:is_new_room = 1
    call add(l:log_lines, 'VEILED_GATE: The threshold parts and reveals a path into the alien dark.')
  else
    call add(l:log_lines, 'VEILED_GATE: The portal remembers your previous crossing and opens again.')
  endif

  let l:next_state.loc = l:target_room
  let l:next_state = game#story#enter_location(l:next_state, l:target_room, l:is_new_room)
  let l:next_state.surge += 2
  let l:target_name = get(l:next_state.rooms[l:target_room], 'name', toupper(l:target_room))
  let l:next_state.hint = 'DIRECTIVE: Portal transit complete. Scan the impossible geometry before moving.'
  let l:next_state = game#story#record_fact(l:next_state, 'Portal transit carried the scene from ' . l:source_name . ' into ' . l:target_name . '.')
  call add(l:log_lines, 'PORTAL TRANSIT: ' . l:source_name . ' -> ' . l:target_name)
  call add(l:log_lines, 'SPATIAL ANOMALY: The crossing distorts the Surge Count by +2.')
  return {'state': l:next_state, 'log': l:log_lines}
endfunction
