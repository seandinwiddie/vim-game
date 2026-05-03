" autoload/game/enemies.vim - Enemy archetype lore and boss mechanics

function! game#enemies#catalog() abort
  let l:boss_tuning = game#tuning#get('enemies.boss.abyssal_overfiend')
  let l:crystal_guard = {
        \ 'signature': 'Dark Crystal Shielding',
        \ 'flavor': 'Crystalline poison shards lash out from the obsidian form.',
        \ 'counter': 'guard_strip'
        \ }
  return {
        \ 'storm-titan': s:entry('Storm Titan', 4, {'str': 10, 'agi': 3, 'arc': 8}, {'pool_order': 0, 'signature': 'Thunderous Slam', 'flavor': 'Hulking thunderbeast unleashes electrostatic discharges between hammer blows.', 'counter': 'guard_strip'}),
        \ 'shadowhorn-juggernaut': s:entry('Shadowhorn Juggernaut', 4, {'str': 11, 'agi': 3, 'arc': 5}, {'pool_order': 1, 'signature': 'Horned Charge of the Possessed', 'flavor': 'Shadow stalker pounces with serrated horns and crushing impact.', 'counter': 'guard_strip'}),
        \ 'magma-leviathan': s:entry('Magma Leviathan', 4, {'str': 11, 'agi': 2, 'arc': 8}, {'pool_order': 2, 'signature': 'Lava Surge Breath', 'flavor': 'Molten armor radiates a core heat aura as the colossus stomps.', 'counter': 'guard_strip'}),
        \ 'abyssal-overfiend': s:entry('Abyssal Overfiend', 4, {'str': l:boss_tuning.str, 'agi': l:boss_tuning.agi, 'arc': l:boss_tuning.arc}, {'pool_order': 3, 'signature': 'Void Tentacles', 'flavor': 'High Demon coils through dimensional rifts wielding abyssal cataclysms.', 'counter': 'soul_siphon', 'boss': {'phases': [{'label': 'Voidmaw Form', 'delta': {'str': 0, 'agi': 0, 'arc': 0}}, {'label': 'Tyrant of the Abyss', 'delta': l:boss_tuning.phase_delta}]}}),
        \ 'aksov-hexe-spinne': s:entry('Aksov Hexe-Spinne', 4, {'str': 8, 'agi': 10, 'arc': 10}, {'pool_order': 4, 'signature': 'Rocket Barrage', 'flavor': 'Rocketweaver arachnid lobs guided missiles in long-range death arcs.', 'counter': 'surge_spike'}),
        \ 'byssalspawn': s:entry('Byssalspawn', 3, {'str': 9, 'agi': 2, 'arc': 7}, {'pool_order': 0, 'signature': 'Eldritch Devouring Gaze', 'flavor': 'Tendrils of cosmic rage erupt from the grotesque maw.', 'counter': 'soul_siphon'}),
        \ 'twilight-weaver': s:entry('Twilight Weaver', 3, {'str': 4, 'agi': 9, 'arc': 6}, {'pool_order': 1, 'signature': 'Shadowstep Ambush', 'flavor': 'Dark ghost dances through electric darkness, horns serrated with shadow.', 'counter': 'mark_strip'}),
        \ 'gravewalker': s:entry('Gravewalker', 3, {'str': 7, 'agi': 4, 'arc': 6}, {'pool_order': 2, 'signature': 'Necrotic Strike', 'flavor': 'A reanimated corpse drags decay through every melee strike.', 'counter': 'soul_siphon'}),
        \ 'flame-corps': s:entry('Flame Corps', 3, {'str': 8, 'agi': 4, 'arc': 5}, {'pool_order': 3, 'signature': 'Napalm Grenade Toss', 'flavor': 'Brimstone Behemoth wreathes the field in inferno overdrive.', 'counter': 'surge_spike'}),
        \ 'aetherwing-herald': s:entry('Aetherwing Herald', 3, {'str': 5, 'agi': 9, 'arc': 8}, {'pool_order': 4, 'signature': 'Celestial Beam', 'flavor': 'Ether-spirit angel projects translucent forms wreathed in spectral storms.', 'counter': 'guard_strip'}),
        \ 'obsidian-warden': s:entry('Obsidian Warden', 2, {'str': 7, 'agi': 2, 'arc': 6}, extend({'pool_order': 0}, l:crystal_guard)),
        \ 'doomguard': s:entry('Doomguard', 2, {'str': 8, 'agi': 3, 'arc': 3}, {'pool_order': 1, 'signature': 'Explosive Barrage', 'flavor': 'Heavy zinc plate clangs as a chant of dread chains the air.', 'counter': 'surge_spike'}),
        \ 'voidwraith': s:entry('Voidwraith', 2, {'str': 3, 'agi': 6, 'arc': 9}, {'pool_order': 2, 'signature': 'Soul Siphon', 'flavor': 'Spectral tendrils drain morale while a haunting moan caves the air in.', 'counter': 'soul_siphon'}),
        \ 'cyberflux-guardian': s:entry('Cyberflux Guardian', 2, {'str': 6, 'agi': 6, 'arc': 5}, {'pool_order': 3, 'signature': 'Magik-Shield Deflector', 'flavor': 'Bionetic soldier vents EMP overload through nano-repair plating.', 'counter': 'guard_strip'}),
        \ 'sentinel-of-terror': s:entry('Sentinel of Terror', 2, {'str': 8, 'agi': 5, 'arc': 4}, extend({'pool_order': 4}, l:crystal_guard)),
        \ 'ashwalker': s:entry('Ashwalker', 1, {'str': 4, 'agi': 7, 'arc': 4}, {'pool_order': 0, 'signature': 'Ember Dash', 'flavor': 'A renegade junkie streaks through ember trails wielding salvaged relics.', 'counter': 'mark_strip'}),
        \ 'aether-spirit': s:entry('Aether Spirit', 1, {'str': 2, 'agi': 8, 'arc': 8}, {'pool_order': 1, 'signature': 'Astral Bolt', 'flavor': 'Phasing in and out of the material plane between bursts of dark energy.', 'counter': 'mark_strip'}),
        \ 'thunder-trooper': s:entry('Thunder Trooper', 1, {'str': 5, 'agi': 5, 'arc': 4}, {'pool_order': 2, 'signature': 'Shotgun Barrage', 'flavor': 'Pyroclash infantry deploy flashbangs and electroshock shielding.', 'counter': 'surge_spike'}),
        \ 'iron-armored-guardian': s:entry('Iron Armored Guardian', 1, {'str': 6, 'agi': 2, 'arc': 2}, {'pool_order': 3, 'signature': 'Ironclad Charge', 'flavor': 'A medieval swordsman in iseon plate hurls explosive projectiles.', 'counter': 'guard_strip'})
        \ }
endfunction

function! game#enemies#archetype(name) abort
  return s:catalog_match(a:name)
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

function! game#enemies#pool(rank) abort
  let l:entries = []
  let l:rank = a:rank >= 4 ? 4 : max([1, a:rank])
  for l:entry in values(game#enemies#catalog())
    if get(l:entry, 'rank', 0) == l:rank
      call add(l:entries, deepcopy(l:entry))
    endif
  endfor
  call sort(l:entries, 's:compare_pool_order')
  let l:pool = []
  for l:entry in l:entries
    call add(l:pool, s:enemy(l:entry))
  endfor
  return l:pool
endfunction

function! game#enemies#select(names) abort
  let l:selected = []
  for l:name in a:names
    let l:entry = s:catalog_by_name(l:name)
    if !empty(l:entry)
      call add(l:selected, s:enemy(l:entry))
    endif
  endfor
  return l:selected
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
  let l:entry = s:catalog_by_name(a:name)
  let l:phases = s:boss_phases(l:entry)
  if empty(l:phases)
    return {}
  endif

  let l:boss = s:enemy(l:entry)
  let l:phase = l:phases[0]
  let l:stats = s:phase_stats(l:entry, 0)
  let l:boss.str = l:stats.str
  let l:boss.agi = l:stats.agi
  let l:boss.arc = l:stats.arc
  let l:boss.is_boss = 1
  let l:boss.phases = len(l:phases)
  let l:boss.phases_done = 0
  let l:boss.phase_label = get(l:phase, 'label', 'First Form')
  return l:boss
endfunction

function! game#enemies#handle_boss_defeat(state, room_key, target, log_lines) abort
  let l:entry = s:catalog_by_name(get(a:target, 'name', ''))
  let l:phases = s:boss_phases(l:entry)
  let l:done = get(a:target, 'phases_done', 0) + 1
  if l:done < len(l:phases)
    let l:next_target = copy(a:target)
    let l:next_phase = l:phases[l:done]
    let l:next_stats = s:phase_stats(l:entry, l:done)
    let l:next_target.phases_done = l:done
    let l:next_target.str = l:next_stats.str
    let l:next_target.agi = l:next_stats.agi
    let l:next_target.arc = l:next_stats.arc
    let l:next_target.phase_label = get(l:next_phase, 'label', 'Next Form')
    let a:state.rooms[a:room_key].entities[0] = l:next_target
    call add(a:log_lines, 'PHASE_SHIFT: The ' . a:target.name . ' tears its physical form apart and reconstitutes as the ' . l:next_target.phase_label . '.')
    call add(a:log_lines, 'BOSS_TRACE: STR+' . get(get(l:next_phase, 'delta', {}), 'str', 0) . ' AGI+' . get(get(l:next_phase, 'delta', {}), 'agi', 0) . ' ARC+' . get(get(l:next_phase, 'delta', {}), 'arc', 0) . '. The duel resumes -- attack again.')
    return {'fully_defeated': 0}
  endif
  return {'fully_defeated': 1}
endfunction

function! game#enemies#trigger_overfiend_epilogue(state, log_lines) abort
  let l:quest_progress = game#quest#advance(a:state, 'confront-overfiend', 1)
  call extend(a:state, l:quest_progress.state, 'force')
  call extend(a:log_lines, l:quest_progress.log)
  let l:state2 = game#story#record_fact_for_thread(a:state, 'Confront the Abyssal Overfiend', 'The Voidmaw Abyssalgeist was annihilated atop the Abyssal Throne, severing Goeteian Chthonica''s anchor to Quadar Tower.')
  call extend(a:state, l:state2, 'force')
  call add(a:log_lines, 'ᚷ EPILOGUE: The tower trembles. The Loom of Fate untangles. The missing rangers can be ferried home. ᚷ')
endfunction

function! game#enemies#all_climax_quests_complete(state) abort
  for l:id in ['rescue-rangers', 'recover-lost-tomes', 'purify-altars']
    if !game#quest#is_complete(a:state, l:id)
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
  return game#data#new_room('abyssal_throne', 'spire', 'ᚷ ABYSSAL_THRONE_OF_QUADAR ᚷ',
        \ 'A monstrous throne carved from interdimensional nightmares. The Voidmaw Abyssalgeist coils upon the seat, tentacles writhing in the eldritch heart of Migdal Kudar. Reality itself recoils.',
        \ {
        \   'exits': {'south': 'nexus'},
        \   'entities': [game#enemies#build_boss('Abyssal Overfiend')],
        \   'objects': [
        \     {'name': 'Throne Sigil', 'desc': 'The carved sigil that anchors the Abyssal Throne to mortal reality. Defile it after the kill to seal the breach.', 'effect': 'overfiend_seal'}
        \   ],
        \   'difficulty': 4
        \ })
endfunction

function! s:entry(name, rank, stats, attrs) abort
  let l:entry = {'name': a:name, 'rank': a:rank, 'stats': deepcopy(a:stats)}
  return extend(l:entry, deepcopy(a:attrs))
endfunction

function! s:enemy(entry) abort
  let l:stats = get(a:entry, 'stats', {})
  return {
        \ 'name': get(a:entry, 'name', ''),
        \ 'str': get(l:stats, 'str', 0),
        \ 'agi': get(l:stats, 'agi', 0),
        \ 'arc': get(l:stats, 'arc', 0)
        \ }
endfunction

function! s:catalog_by_name(name) abort
  for l:entry in values(game#enemies#catalog())
    if get(l:entry, 'name', '') ==# a:name
      return deepcopy(l:entry)
    endif
  endfor
  return {}
endfunction

function! s:catalog_match(name) abort
  let l:entries = values(game#enemies#catalog())
  let l:names = map(copy(l:entries), "get(v:val, 'name', '')")
  let l:match = game#match#one(l:names, a:name)
  return get(l:match, 'found', 0) ? deepcopy(l:entries[l:match.index]) : {}
endfunction

function! s:boss_phases(entry) abort
  return get(get(a:entry, 'boss', {}), 'phases', [])
endfunction

function! s:phase_stats(entry, phase_idx) abort
  let l:stats = deepcopy(get(a:entry, 'stats', {}))
  let l:phase = get(s:boss_phases(a:entry), a:phase_idx, {})
  let l:delta = get(l:phase, 'delta', {})
  let l:stats.str += get(l:delta, 'str', 0)
  let l:stats.agi += get(l:delta, 'agi', 0)
  let l:stats.arc += get(l:delta, 'arc', 0)
  return l:stats
endfunction

function! s:compare_pool_order(left, right) abort
  return get(a:left, 'pool_order', 0) - get(a:right, 'pool_order', 0)
endfunction
