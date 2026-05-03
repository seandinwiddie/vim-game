" autoload/game/explore/procgen.vim - Procedural Room Generation

function! game#explore#procgen#generate_room(seed, entrance_dir, entrance_id, state) abort
  let l:roll = (a:seed % 20) + 1
  let l:room = {'exits': {a:entrance_dir : a:entrance_id}, 'entities': [], 'objects': [], 'services': []}

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
  endif

  let l:portal_object = s:portal_object(l:room.name)
  if !empty(l:portal_object)
    call add(l:room.objects, l:portal_object)
  elseif empty(l:special_object)
    let l:object_roll = (a:seed / 4) % 100
    if l:object_roll > 35
      let l:interactives = [
            \ {'name': 'Ancient Console', 'desc': 'A flickering terminal still carrying fragments of mission telemetry.', 'effect': 'briefing'},
            \ {'name': 'Chthonic Lever', 'desc': 'A heavy stone mechanism covered in sigils and hidden mechanical locks.', 'effect': 'unlock_exit'},
            \ {'name': 'Void Rift', 'desc': 'A swirling vortex of dark energy that tears at the Loom of Fate.', 'effect': 'surge_rift'},
            \ {'name': 'Field Cache', 'desc': 'A ranger cache tucked into broken masonry and sealed against the murk.', 'effect': 'field_cache'},
            \ {'name': 'Broken Machinery', 'desc': 'Sparks fly from this rusted, extraterrestrial device.'}
            \ ]
            
      if l:room.name =~# 'MILITARY_FACILITY'
        let l:interactives += [
              \ {'name': 'Holographic Terminal', 'desc': 'A distorted projection displaying twisted secrets of the realm.', 'effect': 'hidden_lore'},
              \ {'name': 'Occult Display', 'desc': 'Projects twisted images mocking mortal minds.', 'effect': 'surge_rift'}
              \ ]
      elseif l:room.name =~# 'LABYRINTHINE_DUNGEON' || l:room.name =~# 'NARROW_PATH'
        let l:interactives += [
              \ {'name': 'Cyclopean Button', 'desc': 'A massive stone depressor that alters the surrounding geometry.', 'effect': 'unlock_exit'}
              \ ]
      elseif l:room.name =~# 'HAUNTED_CHAPEL' || l:room.name =~# 'RUNE_TEMPLE'
        let l:interactives += [
              \ {'name': 'Eldritch Fresco', 'desc': 'An unholy painting that whispers forgotten truths.', 'effect': 'hidden_lore'}
              \ ]
      endif

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

function! game#explore#procgen#generate_portal_room(seed, entrance_id, state) abort
  let l:env = s:portal_env(a:seed)
  let l:room = {
        \ 'name': 'ᚲ ' . toupper(substitute(l:env.name, ' ', '_', 'g')) . ' ᚲ',
        \ 'desc': l:env.desc,
        \ 'exits': {'south': a:entrance_id, 'north': 'unexplored'},
        \ 'entities': [],
        \ 'objects': [
        \   {'name': 'Return Gate', 'desc': 'A trembling aperture that still remembers the route back to Qua''dar.', 'effect': 'portal_jump', 'target_room': a:entrance_id}
        \ ],
        \ 'services': [],
        \ 'difficulty': min([4, s:encounter_rank(a:state, a:seed) + 1])
        \ }

  let l:enemy_roll = (a:seed / 3) % 100
  if l:enemy_roll > 40
    let l:enemies = s:enemy_pool(l:room.difficulty)
    call add(l:room.entities, deepcopy(l:enemies[(a:seed / 5) % len(l:enemies)]))
  endif

  if l:room.name =~# 'DIMENSIONAL_NEXUS'
    call add(l:room.objects, {'name': 'Spatial Anchor', 'desc': 'A station-core knotting reality into brutal angles.', 'effect': 'surge_rift'})
  elseif l:room.name =~# 'OUTERWORLDLY_REALM'
    call add(l:room.objects, {'name': 'Alien Monolith', 'desc': 'A geometry of impossible angles whispering macrocosmic threats.', 'effect': 'hidden_lore'})
  endif

  return l:room
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
          \ {'name': 'Abyssal Overfiend', 'str': 10, 'agi': 4, 'arc': 9},
          \ {'name': 'Aksov Hexe-Spinne', 'str': 8, 'agi': 10, 'arc': 10}
          \ ]
  elseif a:rank == 3
    return [
          \ {'name': 'Byssalspawn', 'str': 9, 'agi': 2, 'arc': 7},
          \ {'name': 'Twilight Weaver', 'str': 4, 'agi': 9, 'arc': 6},
          \ {'name': 'Gravewalker', 'str': 7, 'agi': 4, 'arc': 6},
          \ {'name': 'Flame Corps', 'str': 8, 'agi': 4, 'arc': 5},
          \ {'name': 'Aetherwing Herald', 'str': 5, 'agi': 9, 'arc': 8}
          \ ]
  elseif a:rank == 2
    return [
          \ {'name': 'Obsidian Warden', 'str': 7, 'agi': 2, 'arc': 6},
          \ {'name': 'Doomguard', 'str': 8, 'agi': 3, 'arc': 3},
          \ {'name': 'Voidwraith', 'str': 3, 'agi': 6, 'arc': 9},
          \ {'name': 'Cyberflux Guardian', 'str': 6, 'agi': 6, 'arc': 5},
          \ {'name': 'Sentinel of Terror', 'str': 8, 'agi': 5, 'arc': 4}
          \ ]
  endif
  return [
        \ {'name': 'Ashwalker', 'str': 4, 'agi': 7, 'arc': 4},
        \ {'name': 'Aether Spirit', 'str': 2, 'agi': 8, 'arc': 8},
        \ {'name': 'Thunder Trooper', 'str': 5, 'agi': 5, 'arc': 4},
        \ {'name': 'Iron Armored Guardian', 'str': 6, 'agi': 2, 'arc': 2}
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

  let l:room_name_approx = ''
  if has_key(a:state, 'rooms') && has_key(a:state.rooms, get(a:state, 'loc', ''))
    let l:room_name_approx = get(a:state.rooms[a:state.loc], 'name', '')
  endif

  if game#story#has_active_quest(a:state, 'purify-altars') && ((a:seed + get(a:state.progress, 'rooms_explored', 1)) % 3 == 0)
    return {
          \ 'name': 'Corrupted Altar',
          \ 'desc': 'A desecrated monolith pulsating with the eldritch taint of daemons.',
          \ 'effect': 'purify_altar',
          \ 'quest_id': 'purify-altars'
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

function! s:portal_object(room_name) abort
  if a:room_name =~# 'MYSTERIOUS_PORTAL'
    return {'name': 'Veiled Gate', 'desc': 'A thin extradimensional threshold opening onto alien fields beyond Qua''dar.', 'effect': 'portal_jump'}
  elseif a:room_name =~# 'DIMENSIONAL_NEXUS'
    return {'name': 'Nexus Gate', 'desc': 'A grotesque gateway whose stations drift through impossible geometry.', 'effect': 'portal_jump'}
  elseif a:room_name =~# 'OUTERWORLDLY_REALM'
    return {'name': 'Macrocosm Gate', 'desc': 'An unstable aperture through surreal angles and gravity-defying roads.', 'effect': 'portal_jump'}
  endif
  return {}
endfunction

function! s:portal_env(seed) abort
  let l:envs = [
        \ {'name': 'Mysterious Portal', 'desc': 'A thin alien threshold shivering with arcane fields and extradimensional static.'},
        \ {'name': 'Dimensional Nexus', 'desc': 'Reality writhes here, with floating stations and pathways that defy sane geometry.'},
        \ {'name': 'Outerworldly Realm', 'desc': 'A macrocosmic nightmare of abstract structures, hostile angles, and gravity-defying roads.'}
        \ ]
  return l:envs[a:seed % len(l:envs)]
endfunction
