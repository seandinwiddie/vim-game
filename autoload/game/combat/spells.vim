" autoload/game/combat/spells.vim - Spell registry and cast handlers

function! game#combat#spells#match_known(known_spells, spell_name) abort
  let l:needle = tolower(a:spell_name)
  for l:spell in a:known_spells
    if tolower(l:spell) ==# l:needle || tolower(l:spell) =~# '^' . l:needle
      return l:spell
    endif
  endfor
  return ''
endfunction

function! game#combat#spells#get(spell_name) abort
  return get(s:registry(), a:spell_name, {})
endfunction

function! game#combat#spells#cast(state, spell_name, ctx) abort
  let l:spell = game#combat#spells#get(a:spell_name)
  if empty(l:spell)
    return game#core#add_log(a:state, "LOG_ERR_CRITICAL: No combat handler registered for '" . a:spell_name . "'.")
  endif
  return call(l:spell.handler, [a:state, a:spell_name, l:spell, a:ctx])
endfunction

function! s:registry() abort
  return {
        \ 'Dark Crystal Shielding': {'handler': function('s:cast_guard'), 'needs_target': 0, 'tuning_key': 'combat.spells.dark_crystal', 'hint': 'DIRECTIVE: Barrier online. You can absorb the next heavy strike.', 'effect_line': 'DEFENSIVE MATRIX: Crystalline shielding coils around the neural link.'},
        \ 'Resurgence Ritual': {'handler': function('s:cast_heal'), 'needs_target': 0, 'tuning_key': 'combat.spells.resurgence_ritual', 'hint': 'DIRECTIVE: Vital reserves replenished.'},
        \ 'Dimensional Weave Shield': {'handler': function('s:cast_guard'), 'needs_target': 0, 'tuning_key': 'combat.spells.dimensional_weave', 'hint': 'DIRECTIVE: Extradimensional ward fortified.', 'effect_line': 'STARWEAVE: A protective lattice of dimensional energy guards the link.'},
        \ "Hunter's Mark": {'handler': function('s:cast_mark'), 'needs_target': 1},
        \ 'Precision Shot': {'handler': function('s:cast_precision'), 'needs_target': 1},
        \ 'Ethereal Dagger Assault': {'handler': function('s:cast_offensive'), 'needs_target': 1, 'kind': 'ARCANE', 'bonus_attr': 'arc'},
        \ 'Cloak of Shadows': {'handler': function('s:cast_offensive'), 'needs_target': 1, 'kind': 'ARCANE', 'bonus_attr': 'arc'},
        \ 'Explosive Barrage': {'handler': function('s:cast_offensive'), 'needs_target': 1, 'kind': 'RANGED', 'bonus_attr': 'agi'},
        \ 'Shatterstrike Slam': {'handler': function('s:cast_offensive'), 'needs_target': 1, 'kind': 'MELEE', 'bonus_attr': 'str'},
        \ 'Ethereal Siren Imprisonment': {'handler': function('s:cast_offensive'), 'needs_target': 1, 'kind': 'ARCANE', 'bonus_attr': 'arc'},
        \ 'Plasma Charge Launchers': {'handler': function('s:cast_offensive'), 'needs_target': 1, 'kind': 'RANGED', 'bonus_attr': 'agi'},
        \ 'Stellar Burst Barrage': {'handler': function('s:cast_offensive'), 'needs_target': 1, 'kind': 'RANGED', 'bonus_attr': 'agi'},
        \ 'Astral Lance Thrust': {'handler': function('s:cast_offensive'), 'needs_target': 1, 'kind': 'ARCANE', 'bonus_attr': 'arc'},
        \ 'Shadowstep Mastery': {'handler': function('s:cast_offensive'), 'needs_target': 1, 'kind': 'ARCANE', 'bonus_attr': 'arc'}
        \ }
endfunction

function! s:cast_guard(state, spell_name, spell, ctx) abort
  let l:next_state = a:state
  let l:next_state.guard = game#tuning#get(a:spell.tuning_key . '.base_guard') + a:ctx.player_arc
  let l:next_state.hint = a:spell.hint
  return game#core#add_log(l:next_state, [
        \ 'CASTING: ' . a:spell_name . '...',
        \ 'WARD STRENGTH: ' . l:next_state.guard,
        \ a:spell.effect_line
        \ ])
endfunction

function! s:cast_heal(state, spell_name, spell, ctx) abort
  let l:next_state = a:state
  let l:heal = game#tuning#get(a:spell.tuning_key . '.base_heal') + a:ctx.player_arc
  let l:next_state = game#player#heal(l:next_state, l:heal)
  let l:next_state.hint = a:spell.hint
  return game#core#add_log(l:next_state, [
        \ 'CASTING: ' . a:spell_name . '...',
        \ 'RESTORED: +' . l:heal . ' HP.'
        \ ])
endfunction

function! s:cast_mark(state, spell_name, spell, ctx) abort
  let l:next_state = a:state
  let l:next_state.mark = a:ctx.target_name
  let l:next_state.hint = 'DIRECTIVE: Target marked. Follow with attack or offensive casting.'
  return game#core#add_log(l:next_state, [
        \ 'CASTING: ' . a:spell_name . ' on ' . a:ctx.target_name . '...',
        \ 'TARGET LOCK: +' . game#tuning#get('combat.mark_bonus') . ' to the next strike against this hostile.'
        \ ])
endfunction

function! s:cast_precision(state, spell_name, spell, ctx) abort
  let l:roll = s:player_roll(a:state, a:ctx)
  let l:next_state = l:roll.state
  let l:precision_tuning = game#tuning#get('combat.spells.precision_shot')
  let l:aim_roll = l:roll.roll + a:ctx.player_agi + a:ctx.mark_bonus
  let l:log_lines = [
        \ 'CASTING: ' . a:spell_name . ' on ' . a:ctx.target_name . '...',
        \ 'AIM_ROLL: ' . l:aim_roll
        \ ]
  if l:aim_roll >= l:precision_tuning.hit_threshold
    call add(l:log_lines, 'HEADSHOT VECTOR: The shot tears through the target''s weak point.')
    call game#combat#defeat_target(l:next_state, a:ctx.loc, a:ctx.target, l:roll.value, l:log_lines)
    let l:next_state.hint = 'DIRECTIVE: Precision elimination confirmed.'
  else
    let l:dmg = (l:roll.value % l:precision_tuning.damage.mod) + l:precision_tuning.damage.base
    call add(l:log_lines, 'SHOT SPOILED: The target twists away and counters from cover.')
    call game#combat#apply_damage(l:next_state, l:dmg, l:log_lines)
    let l:next_state.hint = 'WARNING: Precision Shot failed. Reposition or strike hard.'
  endif
  return s:finalize_resolution(l:next_state, l:log_lines)
endfunction

function! s:cast_offensive(state, spell_name, spell, ctx) abort
  let l:roll = s:player_roll(a:state, a:ctx)
  let l:next_state = l:roll.state
  let l:offensive_tuning = game#tuning#get('combat.spells.offensive')
  let l:bonus = s:bonus_for(a:ctx, a:spell.bonus_attr)
  let l:combat_roll = l:roll.roll + l:bonus + a:ctx.mark_bonus + a:ctx.group_bonus
  let l:log_lines = [
        \ 'CASTING: ' . a:spell_name . ' on ' . a:ctx.target_name . '...',
        \ a:spell.kind . '_ROLL: ' . l:combat_roll . (a:ctx.group_bonus > 0 ? ' (includes +' . a:ctx.group_bonus . ' PARTY bonus)' : '')
        \ ]

  if l:combat_roll >= l:offensive_tuning.hit_threshold
    call add(l:log_lines, 'CRITICAL HIT: The spell overwhelms the ' . a:ctx.target_name . '!')
    call game#combat#defeat_target(l:next_state, a:ctx.loc, a:ctx.target, l:roll.value, l:log_lines)
    let l:next_state.hint = 'DIRECTIVE: Target eliminated.'
  else
    let l:dmg = (l:roll.value % l:offensive_tuning.damage.mod) + l:offensive_tuning.damage.base
    call add(l:log_lines, 'RESISTED: The ' . a:ctx.target_name . ' deflects the magic and counterattacks!')
    call game#combat#apply_damage(l:next_state, l:dmg, l:log_lines)
    let l:next_state.hint = 'WARNING: Spell failed. Consider standard attack.'
  endif

  return s:finalize_resolution(l:next_state, l:log_lines)
endfunction

function! s:bonus_for(ctx, attr) abort
  if a:attr ==# 'str'
    return a:ctx.player_str
  elseif a:attr ==# 'agi'
    return a:ctx.player_agi
  endif
  return a:ctx.player_arc
endfunction

function! s:player_roll(state, ctx) abort
  let l:opts = get(a:ctx, 'opts', {})
  let l:rolls = get(l:opts, 'rolls', {})
  if has_key(l:rolls, 'player')
    return {
          \ 'state': a:state,
          \ 'value': get(l:opts, 'seed', s:synthetic_seed(l:rolls.player)),
          \ 'roll': l:rolls.player
          \ }
  endif

  let l:rng = game#rng#next(a:state)
  return {
        \ 'state': l:rng.state,
        \ 'value': l:rng.value,
        \ 'roll': (l:rng.value % 20) + 1
        \ }
endfunction

function! s:synthetic_seed(player_roll) abort
  return (type(a:player_roll) == v:t_number ? a:player_roll : str2nr(a:player_roll)) * 31
endfunction

function! s:finalize_resolution(state, log_lines) abort
  if a:state.player.hp <= 0
    let a:state.player.hp = 0
    call add(a:log_lines, 'FATAL_ERROR: NEURAL LINK SEVERED. YOU HAVE DIED.')
    let a:state.hint = 'GAME OVER: Type "q" to quit.'
  endif
  return game#core#add_log(a:state, a:log_lines)
endfunction
