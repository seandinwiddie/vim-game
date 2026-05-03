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

  let l:val = str2nr(split(reltimestr(reltime()), '\.')[1])
  let l:p_roll = (l:val % 20) + 1
  let l:e_roll = ((l:val / 10) % 20) + 1
  
  let l:p_score = l:p_roll + l:p_str + l:p_agi + l:p_arc
  let l:e_score = l:e_roll + l:e_str + l:e_agi + l:e_arc

  let l:next_state = copy(a:state)
  let l:next_state.rooms = copy(a:state.rooms)
  let l:next_state.rooms[a:state.loc] = copy(l:room)
  let l:next_state.rooms[a:state.loc].entities = copy(l:room.entities)
  let l:next_state.player = copy(a:state.player)

  let l:log_lines = [
        \ "COMBAT_INITIATED: Engaging " . l:target_name . " (Shadows of Fate Duel)",
        \ "PLAYER: Roll[d20]=" . l:p_roll . " + STR(" . l:p_str . ")+AGI(" . l:p_agi . ")+ARC(" . l:p_arc . ") = " . l:p_score,
        \ "ENEMY : Roll[d20]=" . l:e_roll . " + STR(" . l:e_str . ")+AGI(" . l:e_agi . ")+ARC(" . l:e_arc . ") = " . l:e_score
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
    
    let l:next_state.player.hp -= l:dmg
    if l:dmg > 0
      call add(l:log_lines, "SUSTAINED DAMAGE: -" . l:dmg . " HP.")
    endif
    
    call remove(l:next_state.rooms[a:state.loc].entities, 0)
    
    let l:loot_roll = (l:val % 100)
    if l:loot_roll > 30
      let l:relics = ['Gibsonian Shard', 'Eldritch Medallion', 'Zinc Plating', 'Obsidian Fragment', 'Abyssal Ash', 'Corrupt Watcher Core', 'Pollen Vial']
      let l:loot = l:relics[l:val % len(l:relics)]
      call add(l:next_state.player.inv, l:loot)
      call add(l:log_lines, "LOOT RECOVERED: " . l:loot)
    endif
    
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
    
    let l:next_state.player.hp -= l:dmg
    call add(l:log_lines, "SUSTAINED DAMAGE: -" . l:dmg . " HP.")
    let l:next_state.hint = 'WARNING: Vital signs dropping. Consider retreat!'
  endif

  if l:next_state.player.hp <= 0
    let l:next_state.player.hp = 0
    call add(l:log_lines, "FATAL_ERROR: NEURAL LINK SEVERED. YOU HAVE DIED.")
    let l:next_state.hint = 'GAME OVER: Type "q" to quit.'
  endif

  return game#core#add_log(l:next_state, l:log_lines)
endfunction
