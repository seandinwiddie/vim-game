" autoload/game/enemies.vim - Enemy archetype lore and boss mechanics

function! game#enemies#archetype(name) abort
  let l:lookup = s:archetypes()
  let l:key = tolower(a:name)
  for l:k in keys(l:lookup)
    if l:key =~# l:k
      return l:lookup[l:k]
    endif
  endfor
  return {}
endfunction

function! game#enemies#flavor_lines(target_name) abort
  let l:archetype = game#enemies#archetype(a:target_name)
  if empty(l:archetype)
    return []
  endif
  return [
        \ 'ENEMY SIGNATURE: ' . get(l:archetype, 'signature', 'Unknown') . ' -- ' . get(l:archetype, 'flavor', '')
        \ ]
endfunction

function! game#enemies#counter_signature(state, target_name, log_lines) abort
  let l:archetype = game#enemies#archetype(a:target_name)
  if empty(l:archetype)
    return
  endif
  let l:counter = get(l:archetype, 'counter', '')
  if empty(l:counter)
    return
  endif
  call add(a:log_lines, 'COUNTER_SIGNATURE: ' . a:target_name . ' lashes back with ' . get(l:archetype, 'signature', 'Unknown') . '.')

  if l:counter ==# 'surge_spike'
    let a:state.surge += 2
    call add(a:log_lines, 'SURGE_SPIKE: The signature distortion bumps the Surge Count by +2.')
  elseif l:counter ==# 'mark_strip'
    if !empty(get(a:state, 'mark', ''))
      let l:lost = a:state.mark
      let a:state.mark = ''
      call add(a:log_lines, 'TARGET_LOCK_LOST: The signature shatters Hunter''s Mark on ' . l:lost . '.')
    else
      let a:state.surge += 1
      call add(a:log_lines, 'EM_BLEED: With no mark to strip, the signature just bumps Surge by +1.')
    endif
  elseif l:counter ==# 'guard_strip'
    if get(a:state, 'guard', 0) > 0
      let l:burned = a:state.guard
      let a:state.guard = 0
      call add(a:log_lines, 'WARD_SHATTER: The signature wipes ' . l:burned . ' guard from your barrier.')
    endif
  elseif l:counter ==# 'soul_siphon'
    let a:state.surge += 1
    call add(a:log_lines, 'SOUL_SIPHON: The signature drains your resolve, bumping Surge by +1.')
  endif
endfunction

function! game#enemies#build_boss(name) abort
  if a:name ==# 'Abyssal Overfiend'
    return {
          \ 'name': 'Abyssal Overfiend',
          \ 'str': 14,
          \ 'agi': 6,
          \ 'arc': 12,
          \ 'is_boss': 1,
          \ 'phases': 2,
          \ 'phases_done': 0,
          \ 'phase_label': 'Voidmaw Form'
          \ }
  endif
  return {}
endfunction

function! game#enemies#handle_boss_defeat(state, room_key, target, log_lines) abort
  let l:phases = get(a:target, 'phases', 1)
  let l:done = get(a:target, 'phases_done', 0) + 1
  if l:done < l:phases
    let l:next_target = copy(a:target)
    let l:next_target.phases_done = l:done
    let l:next_target.str = get(a:target, 'str', 8) + 2
    let l:next_target.agi = get(a:target, 'agi', 4) + 1
    let l:next_target.arc = get(a:target, 'arc', 8) + 2
    let l:next_target.phase_label = 'Tyrant of the Abyss'
    let a:state.rooms[a:room_key].entities[0] = l:next_target
    call add(a:log_lines, 'PHASE_SHIFT: The ' . a:target.name . ' tears its physical form apart and reconstitutes as the ' . l:next_target.phase_label . '.')
    call add(a:log_lines, 'BOSS_TRACE: STR+2 AGI+1 ARC+2. The duel resumes -- attack again.')
    return {'fully_defeated': 0}
  endif
  return {'fully_defeated': 1}
endfunction

function! game#enemies#trigger_overfiend_epilogue(state, log_lines) abort
  let l:quest_progress = game#story#advance_quest(a:state, 'confront-overfiend', 1)
  call extend(a:state, l:quest_progress.state, 'force')
  call extend(a:log_lines, l:quest_progress.log)
  let l:state2 = game#story#record_fact_for_thread(a:state, 'Confront the Abyssal Overfiend', 'The Voidmaw Abyssalgeist was annihilated atop the Abyssal Throne, severing Goeteian Chthonica''s anchor to Quadar Tower.')
  call extend(a:state, l:state2, 'force')
  call add(a:log_lines, 'ᚷ EPILOGUE: The tower trembles. The Loom of Fate untangles. The missing rangers can be ferried home. ᚷ')
endfunction

function! game#enemies#all_climax_quests_complete(state) abort
  for l:id in ['rescue-rangers', 'recover-lost-tomes', 'purify-altars']
    if !s:quest_complete(a:state, l:id)
      return 0
    endif
  endfor
  return 1
endfunction

function! game#enemies#climax_quest_definition() abort
  return {
        \ 'id': 'confront-overfiend',
        \ 'title': 'Confront the Abyssal Overfiend',
        \ 'thread': 'Confront the Abyssal Overfiend',
        \ 'objective': 'Descend to the Abyssal Throne and annihilate the Voidmaw Abyssalgeist before the tower devours the rangers.',
        \ 'target_hint': 'Activate the Abyssal Sigil in the Merchandise Store Room and confront the Overfiend on its throne.',
        \ 'status': 'active',
        \ 'progress': 0,
        \ 'goal': 1,
        \ 'reward_item': 'Voidmaw Sigil',
        \ 'reward_spell': 'Stellar Burst Barrage'
        \ }
endfunction

function! game#enemies#abyssal_throne_room() abort
  return {
        \ 'name': 'ᚷ ABYSSAL_THRONE_OF_QUADAR ᚷ',
        \ 'desc': 'A monstrous throne carved from interdimensional nightmares. The Voidmaw Abyssalgeist coils upon the seat, tentacles writhing in the eldritch heart of Migdal Kudar. Reality itself recoils.',
        \ 'exits': {'south': 'nexus'},
        \ 'services': [],
        \ 'entities': [game#enemies#build_boss('Abyssal Overfiend')],
        \ 'objects': [
        \   {'name': 'Throne Sigil', 'desc': 'The carved sigil that anchors the Abyssal Throne to mortal reality. Defile it after the kill to seal the breach.', 'effect': 'overfiend_seal'}
        \ ],
        \ 'difficulty': 4
        \ }
endfunction

function! s:quest_complete(state, quest_id) abort
  for l:quest in get(a:state, 'quests', [])
    if get(l:quest, 'id', '') ==# a:quest_id
      return get(l:quest, 'status', 'active') ==# 'complete'
    endif
  endfor
  return 0
endfunction

function! s:archetypes() abort
  return {
        \ 'obsidian warden\|sentinel of terror': {'signature': 'Dark Crystal Shielding', 'flavor': 'Crystalline poison shards lash out from the obsidian form.', 'counter': 'guard_strip'},
        \ 'doomguard': {'signature': 'Explosive Barrage', 'flavor': 'Heavy zinc plate clangs as a chant of dread chains the air.', 'counter': 'surge_spike'},
        \ 'ashwalker': {'signature': 'Ember Dash', 'flavor': 'A renegade junkie streaks through ember trails wielding salvaged relics.', 'counter': 'mark_strip'},
        \ 'iron armored guardian': {'signature': 'Ironclad Charge', 'flavor': 'A medieval swordsman in iseon plate hurls explosive projectiles.', 'counter': 'guard_strip'},
        \ 'aether spirit': {'signature': 'Astral Bolt', 'flavor': 'Phasing in and out of the material plane between bursts of dark energy.', 'counter': 'mark_strip'},
        \ 'thunder trooper': {'signature': 'Shotgun Barrage', 'flavor': 'Pyroclash infantry deploy flashbangs and electroshock shielding.', 'counter': 'surge_spike'},
        \ 'voidwraith': {'signature': 'Soul Siphon', 'flavor': 'Spectral tendrils drain morale while a haunting moan caves the air in.', 'counter': 'soul_siphon'},
        \ 'cyberflux guardian': {'signature': 'Magik-Shield Deflector', 'flavor': 'Bionetic soldier vents EMP overload through nano-repair plating.', 'counter': 'guard_strip'},
        \ 'byssalspawn': {'signature': 'Eldritch Devouring Gaze', 'flavor': 'Tendrils of cosmic rage erupt from the grotesque maw.', 'counter': 'soul_siphon'},
        \ 'twilight weaver': {'signature': 'Shadowstep Ambush', 'flavor': 'Dark ghost dances through electric darkness, horns serrated with shadow.', 'counter': 'mark_strip'},
        \ 'storm titan': {'signature': 'Thunderous Slam', 'flavor': 'Hulking thunderbeast unleashes electrostatic discharges between hammer blows.', 'counter': 'guard_strip'},
        \ 'aksov hexe-spinne': {'signature': 'Rocket Barrage', 'flavor': 'Rocketweaver arachnid lobs guided missiles in long-range death arcs.', 'counter': 'surge_spike'},
        \ 'flame corps': {'signature': 'Napalm Grenade Toss', 'flavor': 'Brimstone Behemoth wreathes the field in inferno overdrive.', 'counter': 'surge_spike'},
        \ 'aetherwing herald': {'signature': 'Celestial Beam', 'flavor': 'Ether-spirit angel projects translucent forms wreathed in spectral storms.', 'counter': 'guard_strip'},
        \ 'gravewalker': {'signature': 'Necrotic Strike', 'flavor': 'A reanimated corpse drags decay through every melee strike.', 'counter': 'soul_siphon'},
        \ 'shadowhorn juggernaut': {'signature': 'Horned Charge of the Possessed', 'flavor': 'Shadow stalker pounces with serrated horns and crushing impact.', 'counter': 'guard_strip'},
        \ 'magma leviathan': {'signature': 'Lava Surge Breath', 'flavor': 'Molten armor radiates a core heat aura as the colossus stomps.', 'counter': 'guard_strip'},
        \ 'abyssal overfiend': {'signature': 'Void Tentacles', 'flavor': 'High Demon coils through dimensional rifts wielding abyssal cataclysms.', 'counter': 'soul_siphon'}
        \ }
endfunction
