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
        
  if has_key(l:room, 'objects') && !empty(l:room.objects)
    call add(l:lines, 'INTERACTIVE OBJECTS:')
    for l:obj in l:room.objects
      let l:obj_name = type(l:obj) == v:t_dict ? get(l:obj, 'name', 'Unknown Object') : l:obj
      call add(l:lines, '  > [?] ' . l:obj_name)
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
  call add(l:lines, '[HP: ' . a:state.player.hp . '/' . a:state.player.max_hp . ']')
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
  for l:obj in l:room.objects
    let l:name = type(l:obj) == v:t_dict ? get(l:obj, 'name', '') : l:obj
    if tolower(l:name) ==# tolower(a:object_name) || tolower(l:name) =~# '^' . tolower(a:object_name)
      let l:found = 1
      let l:matched_obj = l:obj
      break
    endif
  endfor

  if !l:found
    return game#core#add_log(a:state, "LOG_ERR: You don't see a '" . a:object_name . "' here.")
  endif

  let l:desc = type(l:matched_obj) == v:t_dict ? get(l:matched_obj, 'desc', 'It does nothing.') : 'It does nothing.'
  let l:name = type(l:matched_obj) == v:t_dict ? get(l:matched_obj, 'name', 'Unknown Object') : l:matched_obj
  
  let l:next_state = copy(a:state)
  let l:val = str2nr(split(reltimestr(reltime()), '\.')[1])
  
  let l:log_lines = ["INTERACT: You examine the " . l:name . ".", l:desc]
  
  " Trigger event chance
  if (l:val % 100) > 70
    call add(l:log_lines, "EVENT TRIGGERED: A hidden compartment opens!")
    call add(l:next_state.player.inv, 'Lost Tomes')
    call add(l:log_lines, "LOOT RECOVERED: Lost Tomes")
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
  
  let l:next_state = copy(a:state)
  let l:next_state.rooms = copy(a:state.rooms)
  
  if l:room.exits[l:target_dir] ==# 'unexplored'
    " Procedural generation triggered!
    let l:val = str2nr(split(reltimestr(reltime()), '\.')[1])
    let l:room_id = 'proc_room_' . l:val
    
    let l:next_state.rooms[a:state.loc] = copy(l:room)
    let l:next_state.rooms[a:state.loc].exits = copy(l:room.exits)
    let l:next_state.rooms[a:state.loc].exits[l:target_dir] = l:room_id
    
    let l:new_room = game#explore#generate_room(l:val, l:inv_dir, a:state.loc)
    let l:next_state.rooms[l:room_id] = l:new_room
    let l:next_state = game#core#add_log(l:next_state, "PROCEDURAL_GENERATION: New zone synthesized.")
  endif

  let l:new_loc = l:next_state.rooms[a:state.loc].exits[l:target_dir]
  let l:next_state.loc = l:new_loc
  let l:next_state.hint = 'DIRECTIVE: Area change detected. "look" to update sensor data.'
  let l:next_state = game#core#add_log(l:next_state, "NEURAL_TRACKING: Shifting coordinates to " . l:target_dir)
  return game#explore#cmd_look(l:next_state)
endfunction

function! game#explore#generate_room(seed, entrance_dir, entrance_id) abort
  let l:roll = (a:seed % 20) + 1
  let l:room = {'exits': {a:entrance_dir : a:entrance_id}, 'entities': []}
  
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
  
  let l:enemy_roll = (a:seed / 2) % 100
  if l:enemy_roll > 40
    let l:enemies = [
          \ {'name': 'Obsidian Warden', 'str': 7, 'agi': 2, 'arc': 6},
          \ {'name': 'Doomguard', 'str': 8, 'agi': 3, 'arc': 3},
          \ {'name': 'Ashwalker', 'str': 4, 'agi': 7, 'arc': 4},
          \ {'name': 'Aether Spirit', 'str': 2, 'agi': 8, 'arc': 8},
          \ {'name': 'Voidwraith', 'str': 3, 'agi': 6, 'arc': 9},
          \ {'name': 'Cyberflux Guardian', 'str': 6, 'agi': 6, 'arc': 5},
          \ {'name': 'Byssalspawn', 'str': 9, 'agi': 2, 'arc': 7},
          \ {'name': 'Twilight Weaver', 'str': 4, 'agi': 9, 'arc': 6},
          \ {'name': 'Storm Titan', 'str': 10, 'agi': 3, 'arc': 8},
          \ {'name': 'Flame Corps', 'str': 8, 'agi': 4, 'arc': 5}
          \ ]
    call add(l:room.entities, l:enemies[(a:seed / 3) % len(l:enemies)])
  endif
  
  let l:room.objects = []
  let l:object_roll = (a:seed / 4) % 100
  if l:object_roll > 50
    let l:interactives = [
          \ {'name': 'Ancient Console', 'desc': 'A flickering terminal detailing recent shipments.'},
          \ {'name': 'Chthonic Lever', 'desc': 'A heavy stone mechanism covered in sigils.'},
          \ {'name': 'Void Rift', 'desc': 'A swirling vortex of dark energy.'},
          \ {'name': 'Strange Altar', 'desc': 'A blood-stained altar dedicated to an unknown deity.'},
          \ {'name': 'Broken Machinery', 'desc': 'Sparks fly from this rusted, extraterrestrial device.'}
          \ ]
    call add(l:room.objects, l:interactives[(a:seed / 7) % len(l:interactives)])
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
