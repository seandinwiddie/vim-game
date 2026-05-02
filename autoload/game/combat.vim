" autoload/game/combat.vim - Combat Mechanics

function! game#combat#cmd_attack(state) abort
  let l:room = a:state.rooms[a:state.loc]
  if empty(l:room.entities)
    return game#core#add_log(a:state, "COMBAT_LOG: Target vector empty. No hostiles found.")
  endif

  let l:target = l:room.entities[0]
  let l:val = str2nr(split(reltimestr(reltime()), '\.')[1])
  let l:roll = (l:val % 100) + 1
  
  let l:next_state = copy(a:state)
  let l:next_state.rooms = copy(a:state.rooms)
  let l:next_state.rooms[a:state.loc] = copy(l:room)
  let l:next_state.rooms[a:state.loc].entities = copy(l:room.entities)
  let l:next_state.player = copy(a:state.player)

  let l:log_lines = ["COMBAT_INITIATED: Engaging " . l:target . "...", "TACTICAL_ROLL: " . l:roll]
  
  if l:roll >= 40
    let l:dmg = (l:val % 15) + 5
    let l:next_state.player.hp -= l:dmg
    call remove(l:next_state.rooms[a:state.loc].entities, 0)
    call add(l:log_lines, "SUCCESS: You execute a flurry of strikes! " . l:target . " is annihilated.")
    call add(l:log_lines, "SUSTAINED DAMAGE: -" . l:dmg . " HP.")
    
    let l:loot_roll = (l:val % 100)
    if l:loot_roll > 30
      let l:relics = ['Gibsonian Shard', 'Eldritch Medallion', 'Zinc Plating', 'Obsidian Fragment', 'Abyssal Ash', 'Corrupt Watcher Core', 'Pollen Vial']
      let l:loot = l:relics[l:val % len(l:relics)]
      call add(l:next_state.player.inv, l:loot)
      call add(l:log_lines, "LOOT RECOVERED: " . l:loot)
    endif
    
    let l:next_state.hint = 'DIRECTIVE: Hostile neutralized. Sector secure.'
  else
    let l:dmg = (l:val % 30) + 20
    let l:next_state.player.hp -= l:dmg
    call add(l:log_lines, "CRITICAL FAILURE: The " . l:target . " retaliates with lethal force!")
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
