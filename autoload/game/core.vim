" autoload/game/core.vim - Quadar Micro-MUD Functional Core

" === PURE LOGIC: INITIAL STATE ===
function! game#core#init() abort
  let l:rooms = {
        \ 'nexus': {
        \   'name': 'ᚠ MERCHANDISE_STORE_ROOM ᚠ',
        \   'desc': "A bunker-like emporium, a maggot pile within the starry settlement of Quadar Tower. Shadows dance with the echoes of ancient electronic goth logic. You preside over this emporium, brokering eldritch artifacts.",
        \   'exits': {'north': 'hallway'},
        \   'entities': []
        \ },
        \ 'hallway': {
        \   'name': 'ᚢ UMBRAL_REACH_CORRIDOR ᚢ',
        \   'desc': "A narrow passage of obsidian stone, crystallized in extraterrestrial resonance. The air hums with chthonic frequencies pulsating from the core.",
        \   'exits': {'south': 'nexus', 'north': 'spire_base'},
        \   'entities': ['Ashwalker (Renegade Wanderer)']
        \ },
        \ 'spire_base': {
        \   'name': 'ᚦ BASTION_OF_THE_SPIRE ᚦ',
        \   'desc': "The indomitable tower stands as a testament to long-ago awakening. Colossal structure vibrating with low magic of corrupt watchers. Neon blurs in the Abyssal Murk.",
        \   'exits': {'south': 'hallway', 'east': 'marshes'},
        \   'entities': ['Obsidian Warden (Sentinel of Terror)']
        \ },
        \ 'marshes': {
        \   'name': 'ᚨ ETHEREAL_MARSHES ᚨ',
        \   'desc': "Once lush landscapes now enveloped by poisonous Abyssal Murk. Great furrowing depths of endless ooze and medieval torture.",
        \   'exits': {'west': 'spire_base', 'north': 'abyssal_void'},
        \   'entities': ['Ashwalker Junkie']
        \ },
        \ 'abyssal_void': {
        \   'name': 'ᛟ ABYSSAL_VOID ᛟ',
        \   'desc': "The void that invaded once-holy grounds. The sacredness of the Ethereal Towerlands has given way to the blackness of heavenly damnation.",
        \   'exits': {'south': 'marshes'},
        \   'entities': ['Doomguard (Armored Blood Knight)']
        \ }
        \ }

  let l:s = {
        \ 'view': 'game',
        \ 'player': {'name': 'Kamenal', 'class': 'Rogue/Ranger', 'level': 12, 'hp': 150, 'max_hp': 150, 'inv': ['Basic Dagger', 'Scout Gear']},
        \ 'loc': 'nexus',
        \ 'surge': 0,
        \ 'stage': 'knowledge',
        \ 'threads': ['Find Missing Rangers'],
        \ 'rooms': l:rooms,
        \ 'log': [],
        \ 'hint': 'SYSTEM_INIT: Type "look" to scan your surroundings.',
        \ }
  return s:add_log(l:s, ['NEURAL_LINK_ESTABLISHED', 'SYSTEM_OVERRIDE: INITIATING RECONNAISSANCE PROTOCOL ᚠ', 'You materialize in the Merchandise Store Room.'])
endfunction

" === PURE LOGIC: COMMAND PROCESSING ===
function! game#core#process(state, input) abort
  let l:cmd = tolower(trim(a:input))
  let l:parts = split(l:cmd)
  if empty(l:parts) | return a:state | endif
  
  let l:action = l:parts[0]
  if l:action ==# 'look' || l:action ==# 'l'
    return s:cmd_look(a:state)
  elseif l:action ==# 'go' || l:action ==# 'n' || l:action ==# 's' || l:action ==# 'e' || l:action ==# 'w'
    let l:dir = (len(l:parts) > 1) ? l:parts[1] : l:action
    return s:cmd_go(a:state, l:dir)
  elseif l:action ==# 'scavenge'
    return s:cmd_scavenge(a:state)
  elseif l:action ==# 'ask'
    let l:question = join(l:parts[1:], ' ')
    return s:cmd_ask(a:state, l:question)
  elseif l:action ==# 'stage'
    let l:new_stage = (len(l:parts) > 1) ? tolower(l:parts[1]) : ''
    return s:cmd_stage(a:state, l:new_stage)
  elseif l:action ==# 'thread'
    if len(l:parts) < 2
      return s:add_log(a:state, "LOG_ERR: 'thread add <desc>' or 'thread rm <idx>'.")
    endif
    let l:subcmd = tolower(l:parts[1])
    let l:args = join(l:parts[2:], ' ')
    return s:cmd_thread(a:state, l:subcmd, l:args)
  elseif l:action ==# 'attack' || l:action ==# 'fight'
    return s:cmd_attack(a:state)
  elseif l:action ==# 'inventory' || l:action ==# 'i'
    return s:cmd_inventory(a:state)
  endif

  return s:add_log(a:state, "LOG_ERR_CRITICAL: Unknown input_vector '" . l:action . "'")
endfunction

" === INTERNAL PURE HELPERS ===

function! s:cmd_look(state) abort
  let l:room = a:state.rooms[a:state.loc]
  let l:next_state = copy(a:state)
  let l:next_state.hint = 'DIRECTIVE: Use "go [dir]" to explore, or "ask" the oracle.'
  let l:lines = [
        \ '---',
        \ l:room.name,
        \ l:room.desc
        \ ]
        
  if !empty(l:room.entities)
    call add(l:lines, 'DETECTED ENTITIES:')
    for l:ent in l:room.entities
      call add(l:lines, '  > [!!] ' . l:ent)
    endfor
    let l:next_state.hint = 'DIRECTIVE: Hostiles detected! Type "attack" to engage!'
  endif
  
  call add(l:lines, 'ᚱ ENTRANCES: ' . join(keys(l:room.exits), ', '))
  call add(l:lines, '[HP: ' . a:state.player.hp . '/' . a:state.player.max_hp . ']')
  call add(l:lines, '--')
  return s:add_log(l:next_state, l:lines)
endfunction

function! s:cmd_go(state, dir) abort
  let l:room = a:state.rooms[a:state.loc]
  let l:dir_map = {'n': 'north', 's': 'south', 'e': 'east', 'w': 'west'}
  let l:target_dir = get(l:dir_map, a:dir, a:dir)
  
  if has_key(l:room.exits, l:target_dir)
    let l:new_loc = l:room.exits[l:target_dir]
    let l:next_state = copy(a:state)
    let l:next_state.loc = l:new_loc
    let l:next_state.hint = 'DIRECTIVE: Area change detected. "look" to update sensor data.'
    let l:next_state = s:add_log(l:next_state, "NEURAL_TRACKING: Shifting coordinates to " . l:target_dir)
    return s:cmd_look(l:next_state)
  endif
  return s:add_log(a:state, "PHYSICS_LOGIC_ERR: Cannot penetrate " . l:target_dir)
endfunction

function! s:cmd_inventory(state) abort
  let l:next_state = copy(a:state)
  let l:next_state.hint = 'DIRECTIVE: Local inventory cache accessed.'
  let l:lines = ['--- SECURED RELICS ---']
  for l:item in a:state.player.inv
    call add(l:lines, ' [ᛟ] ' . l:item)
  endfor
  call add(l:lines, '----------------------')
  return s:add_log(l:next_state, l:lines)
endfunction


function! s:cmd_scavenge(state) abort
  let l:next_state = copy(a:state)
  let l:next_state.hint = 'DIRECTIVE: Scavenging implemented via "ask is there loot here?" now.'
  return s:add_log(l:next_state, "Scavenge command deprecated. Use 'ask' for Loom of Fate.")
endfunction

function! s:cmd_stage(state, stage_name) abort
  let l:valid = ['knowledge', 'conflict', 'endings']
  if index(l:valid, a:stage_name) == -1
    return s:add_log(a:state, "LOG_ERR: Invalid stage. Use: stage knowledge, stage conflict, or stage endings.")
  endif
  let l:next_state = copy(a:state)
  let l:next_state.stage = a:stage_name
  let l:next_state.hint = 'DIRECTIVE: Stage of the Scene shifted to ' . toupper(a:stage_name) . '.'
  return s:add_log(l:next_state, "NARRATIVE_SHIFT: Loom of Fate probabilities calibrated to " . toupper(a:stage_name) . ".")
endfunction

function! s:cmd_thread(state, subcmd, args) abort
  let l:next_state = copy(a:state)
  if a:subcmd ==# 'add'
    call add(l:next_state.threads, a:args)
    return s:add_log(l:next_state, "THREAD ADDED: " . a:args)
  elseif a:subcmd ==# 'rm' || a:subcmd ==# 'del'
    let l:idx = str2nr(a:args) - 1
    if l:idx >= 0 && l:idx < len(l:next_state.threads)
      let l:removed = remove(l:next_state.threads, l:idx)
      return s:add_log(l:next_state, "THREAD RESOLVED: " . l:removed)
    endif
    return s:add_log(a:state, "LOG_ERR: Invalid thread index.")
  endif
  return s:add_log(a:state, "LOG_ERR: Unknown thread subcommand.")
endfunction

function! s:cmd_ask(state, question) abort
  if empty(a:question)
    return s:add_log(a:state, "LOG_ERR: You must ask a question (e.g., 'ask is the door locked?').")
  endif

  let l:val = str2nr(split(reltimestr(reltime()), '\.')[1])
  let l:roll = (l:val % 100) + 1
  let l:surge = a:state.surge
  let l:modified_roll = (l:roll > 50) ? (l:roll + l:surge) : (l:roll - l:surge)
  
  let l:res = ""
  let l:new_surge = l:surge
  let l:hint = 'DIRECTIVE: Loom of Fate resolved. "ask" again or explore.'
  let l:is_unexpected = 0

  " Define boundaries based on current stage
  let l:b = {}
  if a:state.stage ==# 'endings'
    let l:b = {'y_un': 100, 'y_but': 99, 'y_and': 81, 'y': 51, 'n': 21, 'n_and': 3, 'n_but': 2, 'n_un': 1}
  elseif a:state.stage ==# 'conflict'
    let l:b = {'y_un': 99, 'y_but': 95, 'y_and': 85, 'y': 51, 'n': 17, 'n_and': 7, 'n_but': 3, 'n_un': 1}
  else " knowledge is default
    let l:b = {'y_un': 96, 'y_but': 86, 'y_and': 81, 'y': 51, 'n': 21, 'n_and': 16, 'n_but': 6, 'n_un': 1}
  endif

  if l:modified_roll >= l:b.y_un
    let l:res = "YES, AND UNEXPECTEDLY"
    let l:new_surge = 0
    let l:is_unexpected = 1
  elseif l:modified_roll >= l:b.y_but
    let l:res = "YES, BUT"
    let l:new_surge = 0
  elseif l:modified_roll >= l:b.y_and
    let l:res = "YES, AND"
    let l:new_surge = 0
  elseif l:modified_roll >= l:b.y
    let l:res = "YES"
    let l:new_surge += 2
  elseif l:modified_roll >= l:b.n
    let l:res = "NO"
    let l:new_surge += 2
  elseif l:modified_roll >= l:b.n_and
    let l:res = "NO, AND"
    let l:new_surge = 0
  elseif l:modified_roll >= l:b.n_but
    let l:res = "NO, BUT"
    let l:new_surge = 0
  else
    let l:res = "NO, AND UNEXPECTEDLY"
    let l:new_surge = 0
    let l:is_unexpected = 1
  endif

  let l:next_state = copy(a:state)
  let l:next_state.surge = l:new_surge
  let l:next_state.hint = l:hint
  
  let l:log_lines = ["Q: " . a:question, "[Loom of Fate: " . l:modified_roll . "] " . l:res]

  if l:is_unexpected
    let l:val2 = str2nr(split(reltimestr(reltime()), '\.')[1])
    let l:d20 = (l:val2 % 20) + 1
    let l:table2 = ['foreshadowing', 'tying off', 'to conflict', 'costume change', 'key grip', 'to knowledge', 'framing', 'set change', 'upstaged', 'pattern change', 'limelit', 'entering the red', 'to endings', 'montage', 'enter stage left', 'cross-stitch', 'six degrees', 're-roll/reserved', 're-roll/reserved', 're-roll/reserved']
    let l:modifier = l:table2[l:d20 - 1]
    call add(l:log_lines, "UNEXPECTED MODIFIER: " . toupper(l:modifier))
  endif

  return s:add_log(l:next_state, l:log_lines)
endfunction

function! s:cmd_attack(state) abort
  let l:room = a:state.rooms[a:state.loc]
  if empty(l:room.entities)
    return s:add_log(a:state, "COMBAT_LOG: Target vector empty. No hostiles found.")
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

  return s:add_log(l:next_state, l:log_lines)
endfunction

function! s:add_log(state, msg) abort
  let l:next_state = copy(a:state)
  if type(a:msg) == v:t_list
    let l:next_state.log += a:msg
  else
    let l:next_state.log += [a:msg]
  endif
  if len(l:next_state.log) > 100
    let l:next_state.log = l:next_state.log[-100:]
  endif
  return l:next_state
endfunction

function! game#core#render(state) abort
  let l:header = [
        \ "ᚠ ᛫ ᛟ ᛫ ᚱ ᛫ ᛒ ᛫ ᛟ ᛫ ᚲ",
        \ "== QUA'DAR NEURAL LINK ==",
        \ "Stage: TO " . toupper(a:state.stage) . " | Surge Count: " . a:state.surge,
        \ a:state.hint,
        \ "--- ACTIVE THREADS ---"
        \ ]
  let l:idx = 1
  for l:th in a:state.threads
    call add(l:header, l:idx . ". " . l:th)
    let l:idx += 1
  endfor
  call add(l:header, "")
  return l:header + a:state.log
endfunction
