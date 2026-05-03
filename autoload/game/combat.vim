" autoload/game/combat.vim - Combat Mechanics

function! game#combat#cmd_attack(state, ...) abort
  let l:opts = a:0 > 0 && type(a:1) == v:t_dict ? a:1 : {}
  let l:room = a:state.rooms[a:state.loc]
  if empty(l:room.entities)
    return game#core#add_log(a:state, "COMBAT_LOG: Target vector empty. No hostiles found.")
  endif

  let l:target = l:room.entities[0]
  let l:target_name = type(l:target) == v:t_dict ? get(l:target, 'name', 'Unknown Entity') : l:target
  
  let l:p_str = get(a:state.player, 'str', 5)
  let l:p_agi = get(a:state.player, 'agi', 8)
  let l:p_arc = get(a:state.player, 'arc', 4)
  
  let l:e_str = type(l:target) == v:t_dict ? get(l:target, 'str', 5) : 5
  let l:e_agi = type(l:target) == v:t_dict ? get(l:target, 'agi', 4) : 4
  let l:e_arc = type(l:target) == v:t_dict ? get(l:target, 'arc', 3) : 3

  let l:e_group_score = 0
  if len(l:room.entities) > 1
    for l:i in range(1, len(l:room.entities) - 1)
      let l:m = l:room.entities[l:i]
      let l:m_str = type(l:m) == v:t_dict ? get(l:m, 'str', 5) : 5
      let l:m_agi = type(l:m) == v:t_dict ? get(l:m, 'agi', 4) : 4
      let l:m_arc = type(l:m) == v:t_dict ? get(l:m, 'arc', 3) : 3
      let l:e_group_score += float2nr(ceil((l:m_str + l:m_agi + l:m_arc) / 6.0))
    endfor
  endif

  let l:rolls = s:attack_rolls(a:state, l:opts)
  let l:val = l:rolls.value
  let l:p_roll = l:rolls.player
  let l:e_roll = l:rolls.enemy
  let l:mark_bonus = s:mark_bonus(a:state, l:target_name)
  let l:p_group_score = game#party#group_bonus(a:state)
  let l:attack_tuning = game#tuning#get('combat.attack')
  
  let l:p_score = l:p_roll + l:p_str + l:p_agi + l:p_arc + l:mark_bonus + l:p_group_score
  let l:e_score = l:e_roll + l:e_str + l:e_agi + l:e_arc + l:e_group_score

  let l:next_state = a:state
  let l:next_state.rng_seed = l:rolls.rng_seed
  
  let l:log_lines = [
        \ "COMBAT_INITIATED: Engaging " . l:target_name . " (Shadows of Fate Duel)",
        \ "PLAYER: Roll[d20]=" . l:p_roll . " + STR(" . l:p_str . ")+AGI(" . l:p_agi . ")+ARC(" . l:p_arc . ")" . (l:mark_bonus > 0 ? "+MARK(" . l:mark_bonus . ")" : '') . (l:p_group_score > 0 ? "+PARTY(" . l:p_group_score . ")" : '') . " = " . l:p_score,
        \ "ENEMY : Roll[d20]=" . l:e_roll . " + STR(" . l:e_str . ")+AGI(" . l:e_agi . ")+ARC(" . l:e_arc . ")" . (l:e_group_score > 0 ? "+GROUP(" . l:e_group_score . ")" : '') . " = " . l:e_score
        \ ]
  call extend(l:log_lines, game#enemies#flavor_lines(l:target_name))
  if type(l:target) == v:t_dict && get(l:target, 'is_boss', 0)
    let l:phase_label = get(l:target, 'phase_label', 'First Form')
    call add(l:log_lines, 'BOSS_TRACE: ' . l:target_name . ' [' . l:phase_label . '] phase ' . (get(l:target, 'phases_done', 0) + 1) . '/' . get(l:target, 'phases', 1))
  endif
  
  if l:p_score >= l:e_score
    let l:diff = l:p_score - l:e_score
    if l:diff >= l:attack_tuning.clear_margin
      call add(l:log_lines, "CLEAR VICTORY: You execute a flurry of strikes! " . l:target_name . " is annihilated.")
      let l:dmg = (l:val % l:attack_tuning.clear_damage.mod) + l:attack_tuning.clear_damage.base
    else
      call add(l:log_lines, "CLOSE CALL: You barely overpower the " . l:target_name . ", sustaining minor injuries.")
      let l:dmg = (l:val % l:attack_tuning.close_damage.mod) + l:attack_tuning.close_damage.base
    endif
    
    call game#combat#apply_damage(l:next_state, l:dmg, l:log_lines)
    call game#combat#defeat_target(l:next_state, a:state.loc, l:target, l:val, l:log_lines)
    
    let l:next_state.hint = 'DIRECTIVE: Hostile neutralized. Sector secure.'
  else
    let l:diff = l:e_score - l:p_score
    if l:diff >= l:attack_tuning.defeat_margin
      call add(l:log_lines, "CRITICAL FAILURE: The " . l:target_name . " retaliates with lethal force!")
      let l:dmg = (l:val % l:attack_tuning.critical_damage.mod) + l:attack_tuning.critical_damage.base
    else
      call add(l:log_lines, "CLOSE CALL DEFEAT: The " . l:target_name . " edges you out in combat.")
      let l:dmg = (l:val % l:attack_tuning.close_defeat_damage.mod) + l:attack_tuning.close_defeat_damage.base
    endif
    
    call game#combat#apply_damage(l:next_state, l:dmg, l:log_lines)
    call game#enemies#counter_signature(l:next_state, l:target_name, l:log_lines)
    let l:next_state.hint = 'WARNING: Vital signs dropping. Consider retreat!'
  endif

  if l:next_state.player.hp <= 0
    let l:next_state.player.hp = 0
    call add(l:log_lines, "FATAL_ERROR: NEURAL LINK SEVERED. YOU HAVE DIED.")
    let l:next_state.hint = 'GAME OVER: Type "q" to quit.'
  endif

  return game#core#add_log(l:next_state, l:log_lines)
endfunction

function! game#combat#cmd_cast(state, spell_name, ...) abort
  let l:opts = a:0 > 0 && type(a:1) == v:t_dict ? a:1 : {}
  let l:spell_match = game#combat#spells#match(a:state.player.spells, a:spell_name)
  if get(l:spell_match, 'ambiguous', 0)
    return game#core#add_log(a:state, "SPELL_ERR: '" . a:spell_name . "' matches multiple known spells: " . join(l:spell_match.matches, ', ') . '.')
  endif
  if !get(l:spell_match, 'found', 0)
    return game#core#add_log(a:state, "SPELL_ERR: You do not know the spell '" . a:spell_name . "'.")
  endif
  let l:matched_spell = l:spell_match.value

  let l:spell = game#combat#spells#get(l:matched_spell)
  if empty(l:spell)
    return game#core#add_log(a:state, "LOG_ERR_CRITICAL: No combat handler registered for '" . l:matched_spell . "'.")
  endif

  let l:next_state = a:state
  let l:ctx = {
        \ 'loc': a:state.loc,
        \ 'player_str': get(a:state.player, 'str', 5),
        \ 'player_agi': get(a:state.player, 'agi', 8),
        \ 'player_arc': get(a:state.player, 'arc', 4),
        \ 'group_bonus': game#party#group_bonus(a:state),
        \ 'mark_bonus': 0,
        \ 'opts': l:opts,
        \ 'target': {},
        \ 'target_name': ''
        \ }

  if get(l:spell, 'needs_target', 1)
    let l:room = a:state.rooms[a:state.loc]
    if empty(l:room.entities)
      return game#core#add_log(a:state, "CAST_LOG: You channel " . l:matched_spell . ", but the energy dissipates in the empty air.")
    endif

    let l:ctx.target = l:room.entities[0]
    let l:ctx.target_name = type(l:ctx.target) == v:t_dict ? get(l:ctx.target, 'name', 'Unknown Entity') : l:ctx.target
    let l:ctx.mark_bonus = s:mark_bonus(a:state, l:ctx.target_name)
  endif

  return game#combat#spells#cast(l:next_state, l:matched_spell, l:ctx)
endfunction

function! s:attack_rolls(state, opts) abort
  let l:rolls = get(a:opts, 'rolls', {})
  if has_key(l:rolls, 'player') && has_key(l:rolls, 'enemy')
    return {
          \ 'player': l:rolls.player,
          \ 'enemy': l:rolls.enemy,
          \ 'value': get(a:opts, 'seed', s:synthetic_seed([l:rolls.player, l:rolls.enemy])),
          \ 'rng_seed': get(a:state, 'rng_seed', game#rng#default_seed())
          \ }
  endif

  let l:rng = game#rng#next(a:state)
  return {
        \ 'player': (l:rng.value % 20) + 1,
        \ 'enemy': ((l:rng.value / 10) % 20) + 1,
        \ 'value': l:rng.value,
        \ 'rng_seed': l:rng.state.rng_seed
        \ }
endfunction

function! game#combat#defeat_target(state, room_key, target, seed, log_lines) abort
  let l:target_name = type(a:target) == v:t_dict ? get(a:target, 'name', 'Unknown Entity') : a:target

  if type(a:target) == v:t_dict && get(a:target, 'is_boss', 0)
    let l:result = game#enemies#handle_boss_defeat(a:state, a:room_key, a:target, a:log_lines)
    if !l:result.fully_defeated
      return
    endif
    call game#enemies#trigger_overfiend_epilogue(a:state, a:log_lines)
  endif

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

function! game#combat#apply_damage(state, dmg, log_lines) abort
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
  return game#tuning#get('combat.mark_bonus')
endfunction

function! s:synthetic_seed(parts) abort
  let l:seed = 0
  for l:part in a:parts
    let l:seed = (l:seed * 31) + (type(l:part) == v:t_number ? l:part : str2nr(l:part))
  endfor
  return l:seed
endfunction

function! s:salvage_value(target) abort
  if type(a:target) != v:t_dict
    return 5
  endif
  return max([4, float2nr(ceil((get(a:target, 'str', 5) + get(a:target, 'agi', 5) + get(a:target, 'arc', 5)) / 4.0))])
endfunction
