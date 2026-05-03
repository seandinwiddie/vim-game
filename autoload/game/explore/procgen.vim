" autoload/game/explore/procgen.vim - Procedural Room Generation

function! game#explore#procgen#generate_room(seed, entrance_dir, entrance_id, state) abort
  let l:roll = (a:seed % 20) + 1
  let l:room_id = 'proc_room_' . a:seed

  let l:envs = [
        \ {'name': 'Ethereal Marshlands', 'biome': 'marsh', 'desc': 'Swampy, desolate marshlands stretched like a soul-devouring abyss.'},
        \ {'name': 'Toxic Wastes', 'biome': 'toxic', 'desc': 'A ghastly mire of desolation, oozing with ichorous sludge.'},
        \ {'name': 'Haunted Chapel', 'biome': 'temple', 'desc': 'Accursed chapel ensnared in despair, veiled in perpetual gloom.'},
        \ {'name': 'Military Facility', 'biome': 'facility', 'desc': 'Ancient military bastion woven with forgotten warfare machinations.'},
        \ {'name': 'The Tower', 'biome': 'spire', 'desc': 'A twisted and foreboding chamber within the Migdal Kudar.'},
        \ {'name': 'Eldritch Fortress', 'biome': 'fortress', 'desc': 'A majestic but sinister labyrinthine terror.'},
        \ {'name': 'Labyrinthine Dungeon', 'biome': 'dungeon', 'desc': 'Convoluted maze twisted and knotted like the tendrils of horrors.'},
        \ {'name': 'Rune Temple', 'biome': 'temple', 'desc': 'Adorned with cryptic symbols dripping with ichor.'},
        \ {'name': 'Crumbling Ruins', 'biome': 'ruins', 'desc': 'Forsaken remnants of an erstwhile splendor.'},
        \ {'name': 'Narrow Path', 'biome': 'corridor', 'desc': 'An accursed domain in the malevolent grip of claustrophobic corridors.'},
        \ {'name': 'Raised Platform', 'biome': 'platform', 'desc': 'A dread platform emerging from bloody depths towards eldritch heavens.'},
        \ {'name': 'Ether', 'biome': 'void', 'desc': 'A desolate expanse where the veils between realms unravel.'},
        \ {'name': 'Subterranean Crypt', 'biome': 'dungeon', 'desc': 'Lightless catacombs cloaked in stygian gloom.'},
        \ {'name': 'Abyssal Pit', 'biome': 'toxic', 'desc': 'A nefarious chasm and stygian chrysm beckoning with foul peril.'},
        \ {'name': 'Mud Slide', 'biome': 'marsh', 'desc': 'Mire-laden trails saturated with the ichor of malevolence.'},
        \ {'name': 'Glade', 'biome': 'wilderness', 'desc': 'A dark clearing revealing a foreboding shadow upon the forsaken land.'},
        \ {'name': 'Mysterious Portal', 'biome': 'void', 'desc': 'A veiled gate acting as an extradimensional cosmic plane.'},
        \ {'name': 'Dimensional Nexus', 'biome': 'void', 'desc': 'A grotesque gateway where the very fabric of reality is tormented.'},
        \ {'name': 'Outerworldly Realm', 'biome': 'void', 'desc': 'Grotesque landscapes that defy the very fabric of sanity.'},
        \ {'name': 'Abyssal Murk', 'biome': 'marsh', 'desc': 'The watery Abyssal Murk echoes with alien wails.'}
        \ ]
  let l:env = l:envs[l:roll - 1]
  let l:display_name = 'ᚲ ' . toupper(substitute(l:env.name, ' ', '_', 'g')) . ' ᚲ'
  
  let l:exits = {a:entrance_dir : a:entrance_id}
  let l:dirs = ['north', 'south', 'east', 'west']
  let l:exit_count = ((a:seed / 5) % 3) + 1
  for l:i in range(l:exit_count)
    let l:d = l:dirs[(a:seed + l:i * 7) % 4]
    if l:d !=# a:entrance_dir
      let l:exits[l:d] = 'unexplored'
    endif
  endfor

  let l:room = game#data#new_room(l:room_id, l:env.biome, l:display_name, l:env.desc, {
        \ 'exits': l:exits,
        \ 'difficulty': s:encounter_rank(a:state, a:seed)
        \ })

  let l:enemy_roll = (a:seed / 2) % 100
  if l:enemy_roll > 25
    let l:enemies = game#enemies#pool(l:room.difficulty)
    call add(l:room.entities, deepcopy(l:enemies[(a:seed / 3) % len(l:enemies)]))
  endif

  let l:special_object = s:story_object(a:state, a:seed)
  if !empty(l:special_object)
    call add(l:room.objects, l:special_object)
  endif

  let l:portal_object = s:portal_object(l:room)
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
            
      if l:room.biome ==# 'facility'
        let l:interactives += [
              \ {'name': 'Holographic Terminal', 'desc': 'A distorted projection displaying twisted secrets of the realm.', 'effect': 'hidden_lore'},
              \ {'name': 'Occult Display', 'desc': 'Projects twisted images mocking mortal minds.', 'effect': 'surge_rift'}
              \ ]
      elseif l:room.biome ==# 'dungeon' || l:room.biome ==# 'corridor'
        let l:interactives += [
              \ {'name': 'Cyclopean Button', 'desc': 'A massive stone depressor that alters the surrounding geometry.', 'effect': 'unlock_exit'}
              \ ]
      elseif l:room.biome ==# 'temple'
        let l:interactives += [
              \ {'name': 'Eldritch Fresco', 'desc': 'An unholy painting that whispers forgotten truths.', 'effect': 'hidden_lore'}
              \ ]
      endif

      call add(l:room.objects, deepcopy(l:interactives[(a:seed / 7) % len(l:interactives)]))
    endif
  endif

  call s:apply_friendly_spawn(l:room, a:seed)
  return l:room
endfunction

function! s:apply_friendly_spawn(room, seed) abort
  let l:friendly_tuning = game#tuning#get('procgen.friendly_spawn')
  let l:friendly_roll = (a:seed / 11) % 100
  if l:friendly_roll >= l:friendly_tuning.ranger_threshold
    call add(a:room.objects, {
          \ 'name': 'Stranded Ranger',
          \ 'desc': 'A fellow recon operative emerges from cover, signal-token raised. They will fold into your unit if helped.',
          \ 'effect': 'recruit_ranger'
          \ })
  elseif l:friendly_roll >= l:friendly_tuning.merchant_threshold
    call add(a:room.services, 'trade')
    call add(a:room.objects, {
          \ 'name': 'Nomadic Merchant',
          \ 'desc': 'A traveling Gloamstrider has set up a barter cache here, hauling wares between the murky reaches.'
          \ })
  endif
endfunction

function! game#explore#procgen#generate_portal_room(seed, entrance_id, state) abort
  let l:env = s:portal_env(a:seed)
  let l:room_id = 'portal_room_' . a:seed
  let l:display_name = 'ᚲ ' . toupper(substitute(l:env.name, ' ', '_', 'g')) . ' ᚲ'
  
  let l:room = game#data#new_room(l:room_id, 'void', l:display_name, l:env.desc, {
        \ 'exits': {'south': a:entrance_id, 'north': 'unexplored'},
        \ 'objects': [
        \   {'name': 'Return Gate', 'desc': 'A trembling aperture that still remembers the route back to Qua''dar.', 'effect': 'portal_jump', 'target_room': a:entrance_id}
        \ ],
        \ 'difficulty': min([4, s:encounter_rank(a:state, a:seed) + 1])
        \ })

  let l:enemy_roll = (a:seed / 3) % 100
  if l:enemy_roll > 40
    let l:enemies = game#enemies#pool(l:room.difficulty)
    call add(l:room.entities, deepcopy(l:enemies[(a:seed / 5) % len(l:enemies)]))
  endif

  if l:room.display_name =~# 'DIMENSIONAL_NEXUS'
    call add(l:room.objects, {'name': 'Spatial Anchor', 'desc': 'A station-core knotting reality into brutal angles.', 'effect': 'surge_rift'})
  elseif l:room.display_name =~# 'OUTERWORLDLY_REALM'
    call add(l:room.objects, {'name': 'Alien Monolith', 'desc': 'A geometry of impossible angles whispering macrocosmic threats.', 'effect': 'hidden_lore'})
  endif

  return l:room
endfunction

function! s:encounter_rank(state, seed) abort
  let l:base = max([1, float2nr(ceil(get(a:state.player, 'level', 1) / 4.0))])
  let l:variance = ((a:seed + get(a:state.progress, 'rooms_explored', 1)) % 2)
  return min([4, l:base + l:variance])
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

function! s:portal_object(room) abort
  if a:room.biome !=# 'void' | return {} | endif

  if a:room.display_name =~# 'MYSTERIOUS_PORTAL'
    return {'name': 'Veiled Gate', 'desc': 'A thin extradimensional threshold opening onto alien fields beyond Qua''dar.', 'effect': 'portal_jump'}
  elseif a:room.display_name =~# 'DIMENSIONAL_NEXUS'
    return {'name': 'Nexus Gate', 'desc': 'A grotesque gateway whose stations drift through impossible geometry.', 'effect': 'portal_jump'}
  elseif a:room.display_name =~# 'OUTERWORLDLY_REALM'
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
