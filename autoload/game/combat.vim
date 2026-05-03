" autoload/game/combat.vim - Combat Mechanics

function! game#combat#cmd_attack(state) abort
  let l:room = a:state.rooms[a:state.loc]
  if empty(l:room.entities)
    return game#core#add_log(a:state, "COMBAT_LOG: Target vector empty. No hostiles found.")
  endif

  let l:target = l:room.entities[0]
  let l:target_name = type(l:target) == v:t_dict ? get(l:target, 'name', 'Unknown Entity') : l:target
  
  " Shadows of Fate Technique: Attributes Assessment
  let l:p_str = get(a:state.player, 'str', 5)
  let l:p_agi = get(a:state.player, 'agi', 8)
  let l:p_arc = get(a:state.player, 'arc', 4)
  
  let l:e_str = type(l:target) == v:t_dict ? get(l:target, 'str', 5) : 5
  let l:e_agi = type(l:target) == v:t_dict ? get(l:target, 'agi', 4) : 4
  let l:e_arc = type(l:target) == v:t_dict ? get(l:target, 'arc', 3) : 3

  " Group Dynamics Calculation
  let l:e_group_score = 0
  if len(l:room.entities) > 1
    for l:i in range(1, len(l:room.entities) - 1)
      let l:m = l:room.entities[l:i]
      let l:m_str = type(l:m) == v:t_dict ? get(l:m, 'str', 5) : 5
      let l:m_agi = type(l:m) == v:t_dict ? get(l:m, 'agi', 4) : 4
      let l:m_arc = type(l:m) == v:t_dict ? get(l:m, 'arc', 3) : 3
      let l:e_group_score += float2nr(ceil((l:m_str + l:m_agi + l:m_arc) / 6.0)) " Halved for balance
    endfor
  endif

  let l:val = str2nr(split(reltimestr(reltime()), '\.')[1])
  let l:p_roll = (l:val % 20) + 1
  let l:e_roll = ((l:val / 10) % 20) + 1
  let l:mark_bonus = s:mark_bonus(a:state, l:target_name)
  
  let l:p_score = l:p_roll + l:p_str + l:p_agi + l:p_arc + l:mark_bonus
  let l:e_score = l:e_roll + l:e_str + l:e_agi + l:e_arc + l:e_group_score

  let l:next_state = copy(a:state)
  let l:next_state.rooms = copy(a:state.rooms)
  let l:next_state.rooms[a:state.loc] = copy(l:room)
  let l:next_state.rooms[a:state.loc].entities = copy(l:room.entities)
  let l:next_state.player = copy(a:state.player)

  let l:log_lines = [
        \ "COMBAT_INITIATED: Engaging " . l:target_name . " (Shadows of Fate Duel)",
        \ "PLAYER: Roll[d20]=" . l:p_roll . " + STR(" . l:p_str . ")+AGI(" . l:p_agi . ")+ARC(" . l:p_arc . ")" . (l:mark_bonus > 0 ? "+MARK(" . l:mark_bonus . ")" : '') . " = " . l:p_score,
        \ "ENEMY : Roll[d20]=" . l:e_roll . " + STR(" . l:e_str . ")+AGI(" . l:e_agi . ")+ARC(" . l:e_arc . ")" . (l:e_group_score > 0 ? "+GROUP(" . l:e_group_score . ")" : '') . " = " . l:e_score
        \ ]
  
  if l:p_score >= l:e_score
    let l:diff = l:p_score - l:e_score
    if l:diff >= 5
      call add(l:log_lines, "CLEAR VICTORY: You execute a flurry of strikes! " . l:target_name . " is annihilated.")
      let l:dmg = (l:val % 5) + 1
    else
      call add(l:log_lines, "CLOSE CALL: You barely overpower the " . l:target_name . ", sustaining minor injuries.")
      let l:dmg = (l:val % 10) + 5
    endif
    
    call s:apply_damage(l:next_state, l:dmg, l:log_lines)
    call s:defeat_target(l:next_state, a:state.loc, l:target, l:val, l:log_lines)
    
    let l:next_state.hint = 'DIRECTIVE: Hostile neutralized. Sector secure.'
  else
    let l:diff = l:e_score - l:p_score
    if l:diff >= 5
      call add(l:log_lines, "CRITICAL FAILURE: The " . l:target_name . " retaliates with lethal force!")
      let l:dmg = (l:val % 20) + 15
    else
      call add(l:log_lines, "CLOSE CALL DEFEAT: The " . l:target_name . " edges you out in combat.")
      let l:dmg = (l:val % 15) + 5
    endif
    
    call s:apply_damage(l:next_state, l:dmg, l:log_lines)
    let l:next_state.hint = 'WARNING: Vital signs dropping. Consider retreat!'
  endif

  if l:next_state.player.hp <= 0
    let l:next_state.player.hp = 0
    call add(l:log_lines, "FATAL_ERROR: NEURAL LINK SEVERED. YOU HAVE DIED.")
    let l:next_state.hint = 'GAME OVER: Type "q" to quit.'
  endif

  return game#core#add_log(l:next_state, l:log_lines)
endfunction

function! game#combat#cmd_cast(state, spell_name) abort
  if empty(a:spell_name)
    return game#core#add_log(a:state, "LOG_ERR: Specify a spell to cast (e.g. 'cast Ethereal Dagger Assault').")
  endif
  
  let l:has_spell = 0
  for l:sp in a:state.player.spells
    if tolower(l:sp) ==# tolower(a:spell_name) || tolower(l:sp) =~# '^' . tolower(a:spell_name)
      let l:has_spell = 1
      let l:matched_spell = l:sp
      break
    endif
  endfor
  
  if !l:has_spell
    return game#core#add_log(a:state, "SPELL_ERR: You do not know the spell '" . a:spell_name . "'.")
  endif

  let l:next_state = copy(a:state)
  let l:next_state.player = copy(a:state.player)
  let l:p_arc = get(a:state.player, 'arc', 4)
  let l:p_agi = get(a:state.player, 'agi', 8)
  let l:val = str2nr(split(reltimestr(reltime()), '\.')[1])

  if l:matched_spell ==# 'Dark Crystal Shielding'
    let l:next_state.guard = 10 + l:p_arc
    let l:next_state.hint = 'DIRECTIVE: Barrier online. You can absorb the next heavy strike.'
    return game#core#add_log(l:next_state, [
          \ 'CASTING: Dark Crystal Shielding...',
          \ 'WARD STRENGTH: ' . l:next_state.guard,
          \ 'DEFENSIVE MATRIX: Crystalline shielding coils around the neural link.'
          \ ])
  elseif l:matched_spell ==# 'Resurgence Ritual'
    let l:heal = 35 + l:p_arc
    let l:next_state.player.hp = min([l:next_state.player.max_hp, l:next_state.player.hp + l:heal])
    let l:next_state.hint = 'DIRECTIVE: Vital reserves replenished.'
    return game#core#add_log(l:next_state, [
          \ 'CASTING: Resurgence Ritual...',
          \ 'RESTORED: +' . l:heal . ' HP.'
          \ ])
  endif

  let l:room = a:state.rooms[a:state.loc]
  if empty(l:room.entities)
    return game#core#add_log(a:state, "CAST_LOG: You channel " . l:matched_spell . ", but the energy dissipates in the empty air.")
  endif

  let l:target = l:room.entities[0]
  let l:target_name = type(l:target) == v:t_dict ? get(l:target, 'name', 'Unknown Entity') : l:target

  let l:next_state.rooms = copy(a:state.rooms)
  let l:next_state.rooms[a:state.loc] = copy(l:room)
  let l:next_state.rooms[a:state.loc].entities = copy(l:room.entities)
  let l:mark_bonus = s:mark_bonus(a:state, l:target_name)

  if l:matched_spell ==# "Hunter's Mark"
    let l:next_state.mark = l:target_name
    let l:next_state.hint = 'DIRECTIVE: Target marked. Follow with attack or offensive casting.'
    return game#core#add_log(l:next_state, [
          \ "CASTING: Hunter's Mark on " . l:target_name . "...",
          \ 'TARGET LOCK: +' . s:mark_bonus_value() . ' to the next strike against this hostile.'
          \ ])
  endif

  if l:matched_spell ==# 'Precision Shot'
    let l:roll = (l:val % 20) + 1 + l:p_agi + l:mark_bonus
    let l:log_lines = [
          \ "CASTING: Precision Shot on " . l:target_name . "...",
          \ "AIM_ROLL: " . l:roll
          \ ]
    if l:roll >= 18
      call add(l:log_lines, 'HEADSHOT VECTOR: The shot tears through the target''s weak point.')
      call s:defeat_target(l:next_state, a:state.loc, l:target, l:val, l:log_lines)
      let l:next_state.hint = 'DIRECTIVE: Precision elimination confirmed.'
    else
      let l:dmg = (l:val % 8) + 4
      call add(l:log_lines, 'SHOT SPOILED: The target twists away and counters from cover.')
      call s:apply_damage(l:next_state, l:dmg, l:log_lines)
      let l:next_state.hint = 'WARNING: Precision Shot failed. Reposition or strike hard.'
    endif
    if l:next_state.player.hp <= 0
      let l:next_state.player.hp = 0
      call add(l:log_lines, 'FATAL_ERROR: NEURAL LINK SEVERED. YOU HAVE DIED.')
      let l:next_state.hint = 'GAME OVER: Type "q" to quit.'
    endif
    return game#core#add_log(l:next_state, l:log_lines)
  endif

  let l:roll = (l:val % 20) + 1 + l:p_arc + l:mark_bonus
  
  let l:log_lines = [
        \ "CASTING: " . l:matched_spell . " on " . l:target_name . "...",
        \ "ARCANE_ROLL: " . l:roll
        \ ]

  if l:roll >= 15
    call add(l:log_lines, "CRITICAL HIT: The spell overwhelms the " . l:target_name . "!")
    call s:defeat_target(l:next_state, a:state.loc, l:target, l:val, l:log_lines)
    let l:next_state.hint = 'DIRECTIVE: Target eliminated.'
  else
    let l:dmg = (l:val % 10) + 5
    call add(l:log_lines, "RESISTED: The " . l:target_name . " deflects the magic and counterattacks!")
    call s:apply_damage(l:next_state, l:dmg, l:log_lines)
    let l:next_state.hint = 'WARNING: Spell failed. Consider standard attack.'
  endif

  if l:next_state.player.hp <= 0
    let l:next_state.player.hp = 0
    call add(l:log_lines, "FATAL_ERROR: NEURAL LINK SEVERED. YOU HAVE DIED.")
    let l:next_state.hint = 'GAME OVER: Type "q" to quit.'
  endif

  return game#core#add_log(l:next_state, l:log_lines)
endfunction

function! s:defeat_target(state, room_key, target, seed, log_lines) abort
  let l:target_name = type(a:target) == v:t_dict ? get(a:target, 'name', 'Unknown Entity') : a:target
  call remove(a:state.rooms[a:room_key].entities, 0)

  if get(a:state, 'mark', '') ==# l:target_name
    let a:state.mark = ''
    call add(a:log_lines, 'HUNTER''S MARK: Target lock collapses with the kill.')
  endif

  let l:bounty = s:salvage_value(a:target)
  let l:reward = game#economy#reward_trade(a:state, l:bounty, l:target_name)
  call extend(a:log_lines, l:reward.log)
  call extend(a:state, {'player': l:reward.state.player}, 'force')

  let l:loot_roll = (a:seed % 100)
  if l:loot_roll > 30
    let l:relics = ['Gibsonian Shard', 'Eldritch Medallion', 'Zinc Plating', 'Obsidian Fragment', 'Abyssal Ash', 'Corrupt Watcher Core', 'Pollen Vial']
    let l:loot = l:relics[a:seed % len(l:relics)]
    call add(a:state.player.inv, l:loot)
    call add(a:log_lines, 'LOOT RECOVERED: ' . l:loot)
  endif
endfunction

function! s:apply_damage(state, dmg, log_lines) abort
  let l:remaining = a:dmg
  if get(a:state, 'guard', 0) > 0
    let l:absorbed = min([a:state.guard, l:remaining])
    let a:state.guard -= l:absorbed
    let l:remaining -= l:absorbed
    call add(a:log_lines, 'DARK CRYSTAL SHIELDING absorbs ' . l:absorbed . ' damage.')
  endif

  if l:remaining > 0
    let a:state.player.hp -= l:remaining
    call add(a:log_lines, 'SUSTAINED DAMAGE: -' . l:remaining . ' HP.')
  else
    call add(a:log_lines, 'NO HP LOSS: The barrier carries the impact.')
  endif
endfunction

function! s:mark_bonus(state, target_name) abort
  return get(a:state, 'mark', '') ==# a:target_name ? s:mark_bonus_value() : 0
endfunction

function! s:mark_bonus_value() abort
  return 4
endfunction

function! s:salvage_value(target) abort
  if type(a:target) != v:t_dict
    return 5
  endif
  return max([4, float2nr(ceil((get(a:target, 'str', 5) + get(a:target, 'agi', 5) + get(a:target, 'arc', 5)) / 4.0))])
endfunction
