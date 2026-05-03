" autoload/game/explore.vim - Exploration Mechanics

function! game#explore#cmd_look(state) abort
  let l:room = a:state.rooms[a:state.loc]
  let l:next_state = copy(a:state)
  let l:next_state.hint = 'DIRECTIVE: Use "go [dir]" to explore, "interact [object]" to manipulate the scene, or "ask" the oracle.'
  let l:lines = [
        \ '---',
        \ l:room.name,
        \ l:room.desc
        \ ]
        
  if has_key(l:room, 'objects') && !empty(l:room.objects)
    call add(l:lines, 'INTERACTIVE OBJECTS:')
    for l:obj in l:room.objects
      let l:obj_name = type(l:obj) == v:t_dict ? get(l:obj, 'name', 'Unknown Object') : l:obj
      let l:marker = '[?]'
      if type(l:obj) == v:t_dict && has_key(l:obj, 'quest_id') && game#story#has_active_quest(a:state, l:obj.quest_id)
        let l:marker = '[*]'
      elseif type(l:obj) == v:t_dict && get(l:obj, 'effect', '') ==# 'briefing'
        let l:marker = '[!]'
      endif
      call add(l:lines, '  > ' . l:marker . ' ' . l:obj_name)
    endfor
  endif
        
  if !empty(l:room.entities)
    call add(l:lines, 'DETECTED ENTITIES:')
    for l:ent in l:room.entities
      let l:ent_name = type(l:ent) == v:t_dict ? get(l:ent, 'name', 'Unknown Entity') : l:ent
      call add(l:lines, '  > [!!] ' . l:ent_name)
    endfor
    let l:next_state.hint = 'DIRECTIVE: Hostiles detected! Type "attack" to engage!'
  endif
  
  call add(l:lines, 'ᚱ ENTRANCES: ' . join(keys(l:room.exits), ', '))
  call add(l:lines, '[Threat Tier: ' . get(l:room, 'difficulty', 1) . ' | HP: ' . a:state.player.hp . '/' . a:state.player.max_hp . ']')
  call add(l:lines, '--')
  return game#core#add_log(l:next_state, l:lines)
endfunction

function! game#explore#cmd_interact(state, object_name) abort
  if empty(a:object_name)
    return game#core#add_log(a:state, "LOG_ERR: Specify an object to interact with (e.g. 'interact Arcane Terminal').")
  endif
  
  let l:room = a:state.rooms[a:state.loc]
  if !has_key(l:room, 'objects') || empty(l:room.objects)
    return game#core#add_log(a:state, "LOG_ERR: There is nothing to interact with here.")
  endif

  let l:found = 0
  let l:matched_obj = {}
  let l:matched_idx = -1
  let l:obj_idx = 0
  for l:obj in l:room.objects
    let l:name = type(l:obj) == v:t_dict ? get(l:obj, 'name', '') : l:obj
    if tolower(l:name) ==# tolower(a:object_name) || tolower(l:name) =~# '^' . tolower(a:object_name)
      let l:found = 1
      let l:matched_obj = l:obj
      let l:matched_idx = l:obj_idx
      break
    endif
    let l:obj_idx += 1
  endfor

  if !l:found
    return game#core#add_log(a:state, "LOG_ERR: You don't see a '" . a:object_name . "' here.")
  endif

  let l:desc = type(l:matched_obj) == v:t_dict ? get(l:matched_obj, 'desc', 'It does nothing.') : 'It does nothing.'
  let l:name = type(l:matched_obj) == v:t_dict ? get(l:matched_obj, 'name', 'Unknown Object') : l:matched_obj
  
  let l:next_state = deepcopy(a:state)
  let l:effect = type(l:matched_obj) == v:t_dict ? get(l:matched_obj, 'effect', '') : ''
  let l:consume_object = 0
  let l:log_lines = ["INTERACT: You examine the " . l:name . ".", l:desc]

  if l:effect ==# 'briefing'
    if get(l:next_state.flags, 'terminal_briefed', 0)
      call add(l:log_lines, 'BRIEFING CACHE: The terminal still points toward the missing rangers and scattered codices.')
    else
      let l:next_state.flags.terminal_briefed = 1
      let l:quest_result = game#story#ensure_quest(l:next_state, {
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
      let l:next_state = l:quest_result.state
      call add(l:log_lines, 'MISSION UPDATE: Recon protocol refreshed. Missing rangers are still alive somewhere beyond the tower shell.')
      call add(l:log_lines, 'MISSION UPDATE: Archive traces reveal codices capable of sending captives home.')
      if l:quest_result.added
        call add(l:log_lines, 'OBJECTIVE ADDED: Recover the Lost Tomes')
      endif
    endif
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
    call add(l:log_lines, 'EXTRACTION: You cut a stranded ranger free and fold them back into the recon circuit.')
    if index(l:next_state.player.inv, 'Ranger Signal Token') == -1
      call add(l:next_state.player.inv, 'Ranger Signal Token')
      call add(l:log_lines, 'RECOVERED: Ranger Signal Token')
    endif
    let l:quest_progress = game#story#advance_quest(l:next_state, 'rescue-rangers', 1)
    let l:next_state = l:quest_progress.state
    let l:log_lines += l:quest_progress.log
  elseif l:effect ==# 'recover_tome'
    let l:consume_object = 1
    if index(l:next_state.player.inv, 'Lost Tomes') == -1
      call add(l:next_state.player.inv, 'Lost Tomes')
    endif
    call add(l:log_lines, 'ARCHIVE RECOVERED: The reliquary yields a stack of codices and return sigils.')
    let l:quest_progress = game#story#advance_quest(l:next_state, 'recover-lost-tomes', 1)
    let l:next_state = l:quest_progress.state
    let l:log_lines += l:quest_progress.log
  elseif l:effect ==# 'field_cache'
    let l:consume_object = 1
    let l:next_state.player.hp = min([l:next_state.player.max_hp, l:next_state.player.hp + 20])
    call add(l:next_state.player.inv, 'Field Rations')
    call add(l:log_lines, 'CACHE BREACH: You recover field rations and patch your wounds for +20 HP.')
  elseif l:effect ==# 'surge_rift'
    let l:consume_object = 1
    let l:next_state.surge += 3
    call add(l:log_lines, 'RIFT BACKLASH: The void surges through the link and spikes the Surge Count by 3.')
  else
    let l:val = str2nr(split(reltimestr(reltime()), '\.')[1])
    if (l:val % 100) > 70
      call add(l:log_lines, 'EVENT TRIGGERED: A hidden compartment opens!')
      call add(l:next_state.player.inv, 'Lost Tomes')
      call add(l:log_lines, 'LOOT RECOVERED: Lost Tomes')
    endif
  endif

  if l:consume_object && l:matched_idx >= 0
    call remove(l:next_state.rooms[a:state.loc].objects, l:matched_idx)
  endif

  return game#core#add_log(l:next_state, l:log_lines)
endfunction

function! game#explore#cmd_go(state, dir) abort
  let l:room = a:state.rooms[a:state.loc]
  let l:dir_map = {'n': 'north', 's': 'south', 'e': 'east', 'w': 'west'}
  let l:target_dir = get(l:dir_map, a:dir, a:dir)
  let l:inv_dir_map = {'north': 'south', 'south': 'north', 'east': 'west', 'west': 'east'}
  let l:inv_dir = get(l:inv_dir_map, l:target_dir, 'unknown')
  
  if !has_key(l:room.exits, l:target_dir)
    return game#core#add_log(a:state, "PHYSICS_LOGIC_ERR: Cannot penetrate " . l:target_dir)
  endif
  
  let l:next_state = deepcopy(a:state)
  let l:is_new_room = 0
  
  if l:room.exits[l:target_dir] ==# 'unexplored'
    " Procedural generation triggered!
    let l:val = str2nr(split(reltimestr(reltime()), '\.')[1])
    let l:room_id = 'proc_room_' . l:val
    let l:next_state.rooms[a:state.loc].exits[l:target_dir] = l:room_id
    
    let l:new_room = game#explore#generate_room(l:val, l:inv_dir, a:state.loc, l:next_state)
    let l:next_state.rooms[l:room_id] = l:new_room
    let l:is_new_room = 1
    let l:next_state = game#core#add_log(l:next_state, "PROCEDURAL_GENERATION: New zone synthesized.")
  endif

  let l:new_loc = l:next_state.rooms[a:state.loc].exits[l:target_dir]
  let l:next_state.loc = l:new_loc
  let l:next_state = game#story#enter_location(l:next_state, l:new_loc, l:is_new_room)
  let l:next_state.hint = 'DIRECTIVE: Area change detected. "look" to update sensor data.'
  let l:next_state = game#core#add_log(l:next_state, "NEURAL_TRACKING: Shifting coordinates to " . l:target_dir)
  return game#explore#cmd_look(l:next_state)
endfunction

function! game#explore#generate_room(seed, entrance_dir, entrance_id, state) abort
  let l:roll = (a:seed % 20) + 1
  let l:room = {'exits': {a:entrance_dir : a:entrance_id}, 'entities': [], 'objects': []}
  
  let l:envs = [
        \ {'name': 'Ethereal Marshlands', 'desc': 'Swampy, desolate marshlands stretched like a soul-devouring abyss.'},
        \ {'name': 'Toxic Wastes', 'desc': 'A ghastly mire of desolation, oozing with ichorous sludge.'},
        \ {'name': 'Haunted Chapel', 'desc': 'Accursed chapel ensnared in despair, veiled in perpetual gloom.'},
        \ {'name': 'Military Facility', 'desc': 'Ancient military bastion woven with forgotten warfare machinations.'},
        \ {'name': 'The Tower', 'desc': 'A twisted and foreboding chamber within the Migdal Kudar.'},
        \ {'name': 'Eldritch Fortress', 'desc': 'A majestic but sinister labyrinthine terror.'},
        \ {'name': 'Labyrinthine Dungeon', 'desc': 'Convoluted maze twisted and knotted like the tendrils of horrors.'},
        \ {'name': 'Rune Temple', 'desc': 'Adorned with cryptic symbols dripping with ichor.'},
        \ {'name': 'Crumbling Ruins', 'desc': 'Forsaken remnants of an erstwhile splendor.'},
        \ {'name': 'Narrow Path', 'desc': 'An accursed domain in the malevolent grip of claustrophobic corridors.'},
        \ {'name': 'Raised Platform', 'desc': 'A dread platform emerging from bloody depths towards eldritch heavens.'},
        \ {'name': 'Ether', 'desc': 'A desolate expanse where the veils between realms unravel.'},
        \ {'name': 'Subterranean Crypt', 'desc': 'Lightless catacombs cloaked in stygian gloom.'},
        \ {'name': 'Abyssal Pit', 'desc': 'A nefarious chasm and stygian chrysm beckoning with foul peril.'},
        \ {'name': 'Mud Slide', 'desc': 'Mire-laden trails saturated with the ichor of malevolence.'},
        \ {'name': 'Glade', 'desc': 'A dark clearing revealing a foreboding shadow upon the forsaken land.'},
        \ {'name': 'Mysterious Portal', 'desc': 'A veiled gate acting as an extradimensional cosmic plane.'},
        \ {'name': 'Dimensional Nexus', 'desc': 'A grotesque gateway where the very fabric of reality is tormented.'},
        \ {'name': 'Outerworldly Realm', 'desc': 'Grotesque landscapes that defy the very fabric of sanity.'},
        \ {'name': 'Abyssal Murk', 'desc': 'The watery Abyssal Murk echoes with alien wails.'}
        \ ]
  let l:env = l:envs[l:roll - 1]
  let l:room.name = 'ᚲ ' . toupper(substitute(l:env.name, ' ', '_', 'g')) . ' ᚲ'
  let l:room.desc = l:env.desc
  let l:room.difficulty = s:encounter_rank(a:state, a:seed)
  
  let l:enemy_roll = (a:seed / 2) % 100
  if l:enemy_roll > 25
    let l:enemies = s:enemy_pool(l:room.difficulty)
    call add(l:room.entities, deepcopy(l:enemies[(a:seed / 3) % len(l:enemies)]))
  endif
  
  let l:special_object = s:story_object(a:state, a:seed)
  if !empty(l:special_object)
    call add(l:room.objects, l:special_object)
  else
    let l:object_roll = (a:seed / 4) % 100
    if l:object_roll > 35
      let l:interactives = [
            \ {'name': 'Ancient Console', 'desc': 'A flickering terminal still carrying fragments of mission telemetry.', 'effect': 'briefing'},
            \ {'name': 'Chthonic Lever', 'desc': 'A heavy stone mechanism covered in sigils and hidden mechanical locks.', 'effect': 'unlock_exit'},
            \ {'name': 'Void Rift', 'desc': 'A swirling vortex of dark energy that tears at the Loom of Fate.', 'effect': 'surge_rift'},
            \ {'name': 'Field Cache', 'desc': 'A ranger cache tucked into broken masonry and sealed against the murk.', 'effect': 'field_cache'},
            \ {'name': 'Broken Machinery', 'desc': 'Sparks fly from this rusted, extraterrestrial device.'}
            \ ]
      call add(l:room.objects, deepcopy(l:interactives[(a:seed / 7) % len(l:interactives)]))
    endif
  endif
  
  let l:dirs = ['north', 'south', 'east', 'west']
  let l:exit_count = ((a:seed / 5) % 3) + 1
  for l:i in range(l:exit_count)
    let l:d = l:dirs[(a:seed + l:i * 7) % 4]
    if l:d !=# a:entrance_dir
      let l:room.exits[l:d] = 'unexplored'
    endif
  endfor
  
  return l:room
endfunction

function! s:first_hidden_exit(exits) abort
  for l:dir in ['north', 'south', 'east', 'west']
    if !has_key(a:exits, l:dir)
      return l:dir
    endif
  endfor
  return ''
endfunction

function! s:encounter_rank(state, seed) abort
  let l:base = max([1, float2nr(ceil(get(a:state.player, 'level', 1) / 4.0))])
  let l:variance = ((a:seed + get(a:state.progress, 'rooms_explored', 1)) % 2)
  return min([4, l:base + l:variance])
endfunction

function! s:enemy_pool(rank) abort
  if a:rank >= 4
    return [
          \ {'name': 'Storm Titan', 'str': 10, 'agi': 3, 'arc': 8},
          \ {'name': 'Shadowhorn Juggernaut', 'str': 11, 'agi': 3, 'arc': 5},
          \ {'name': 'Magma Leviathan', 'str': 11, 'agi': 2, 'arc': 8},
          \ {'name': 'Abyssal Overfiend', 'str': 10, 'agi': 4, 'arc': 9}
          \ ]
  elseif a:rank == 3
    return [
          \ {'name': 'Byssalspawn', 'str': 9, 'agi': 2, 'arc': 7},
          \ {'name': 'Twilight Weaver', 'str': 4, 'agi': 9, 'arc': 6},
          \ {'name': 'Gravewalker', 'str': 7, 'agi': 4, 'arc': 6},
          \ {'name': 'Flame Corps', 'str': 8, 'agi': 4, 'arc': 5}
          \ ]
  elseif a:rank == 2
    return [
          \ {'name': 'Obsidian Warden', 'str': 7, 'agi': 2, 'arc': 6},
          \ {'name': 'Doomguard', 'str': 8, 'agi': 3, 'arc': 3},
          \ {'name': 'Voidwraith', 'str': 3, 'agi': 6, 'arc': 9},
          \ {'name': 'Cyberflux Guardian', 'str': 6, 'agi': 6, 'arc': 5}
          \ ]
  endif
  return [
        \ {'name': 'Ashwalker', 'str': 4, 'agi': 7, 'arc': 4},
        \ {'name': 'Aether Spirit', 'str': 2, 'agi': 8, 'arc': 8},
        \ {'name': 'Thunder Trooper', 'str': 5, 'agi': 5, 'arc': 4}
        \ ]
endfunction

function! s:story_object(state, seed) abort
  if game#story#has_active_quest(a:state, 'rescue-rangers') && ((a:seed + get(a:state.progress, 'rooms_explored', 1)) % 4 == 0)
    return {
          \ 'name': 'Bound Ranger',
          \ 'desc': 'A reconnaissance operative lies bound in corroded restraints, whispering for extraction.',
          \ 'effect': 'rescue_ranger',
          \ 'quest_id': 'rescue-rangers'
          \ }
  endif

  if game#story#has_active_quest(a:state, 'recover-lost-tomes') && ((a:seed + get(a:state.progress, 'steps', 0)) % 5 == 0)
    return {
          \ 'name': 'Sealed Reliquary',
          \ 'desc': 'A lead-lined reliquary hums with trapped archive energy and transport sigils.',
          \ 'effect': 'recover_tome',
          \ 'quest_id': 'recover-lost-tomes'
          \ }
  endif

  if ((a:seed + get(a:state.player, 'level', 1)) % 6 == 0)
    return {
          \ 'name': 'Field Cache',
          \ 'desc': 'A sealed ranger cache survives beneath the ash and circuitry.',
          \ 'effect': 'field_cache'
          \ }
  endif

  return {}
endfunction
