" autoload/game/oracle.vim - Loom of Fate Oracle Mechanics

function! game#oracle#cmd_stage(state, stage_name) abort
  let l:valid = ['knowledge', 'conflict', 'endings']
  if index(l:valid, a:stage_name) == -1
    return game#core#add_log(a:state, "LOG_ERR: Invalid stage. Use: stage knowledge, stage conflict, or stage endings.")
  endif
  let l:next_state = copy(a:state)
  let l:next_state.stage = a:stage_name
  let l:next_state.hint = 'DIRECTIVE: Stage of the Scene shifted to ' . toupper(a:stage_name) . '.'
  return game#core#add_log(l:next_state, "NARRATIVE_SHIFT: Loom of Fate probabilities calibrated to " . toupper(a:stage_name) . ".")
endfunction

function! game#oracle#cmd_ask(state, question) abort
  if empty(a:question)
    return game#core#add_log(a:state, "LOG_ERR: You must ask a question (e.g., 'ask is the door locked?').")
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
  let l:oracle_note = 'Oracle: ' . a:question . ' -> ' . l:res

  if l:is_unexpected
    let l:val2 = str2nr(split(reltimestr(reltime()), '\.')[1])
    let l:d20 = (l:val2 % 20) + 1
    let l:table2 = ['foreshadowing', 'tying off', 'to conflict', 'costume change', 'key grip', 'to knowledge', 'framing', 'set change', 'upstaged', 'pattern change', 'limelit', 'entering the red', 'to endings', 'montage', 'enter stage left', 'cross-stitch', 'six degrees', 're-roll/reserved', 're-roll/reserved', 're-roll/reserved']
    let l:modifier = l:table2[l:d20 - 1]
    call add(l:log_lines, "UNEXPECTED MODIFIER: " . toupper(l:modifier))
    let l:oracle_note .= ' [' . toupper(l:modifier) . ']'
    let l:next_state = s:apply_table2_modifier(l:next_state, l:modifier, l:log_lines)
  endif

  let l:next_state = game#story#record_fact(l:next_state, l:oracle_note)
  return game#core#add_log(l:next_state, l:log_lines)
endfunction

function! game#oracle#apply_modifier(state, modifier) abort
  let l:log_lines = []
  let l:next_state = s:apply_table2_modifier(a:state, a:modifier, l:log_lines)
  return {'state': l:next_state, 'log': l:log_lines}
endfunction

function! s:apply_table2_modifier(state, modifier, log_lines) abort
  let l:next_state = a:state
  if a:modifier ==# 'limelit'
    let l:next_state.surge = 0
    call add(a:log_lines, 'LIMELIT: The scene tilts toward the PCs. Surge Count zeroed.')
  elseif a:modifier ==# 'entering the red'
    let l:room = get(get(l:next_state, 'rooms', {}), get(l:next_state, 'loc', ''), {})
    if !empty(l:room)
      let l:val = str2nr(split(reltimestr(reltime()), '\.')[1])
      let l:pool = [
            \ {'name': 'Ashwalker', 'str': 4, 'agi': 7, 'arc': 4},
            \ {'name': 'Voidwraith', 'str': 3, 'agi': 6, 'arc': 9},
            \ {'name': 'Doomguard', 'str': 8, 'agi': 3, 'arc': 3},
            \ {'name': 'Twilight Weaver', 'str': 4, 'agi': 9, 'arc': 6}
            \ ]
      let l:spawn = deepcopy(l:pool[l:val % len(l:pool)])
      let l:next_state.rooms[l:next_state.loc] = copy(l:room)
      let l:next_state.rooms[l:next_state.loc].entities = copy(get(l:room, 'entities', [])) + [l:spawn]
      let l:next_state.surge += 3
      call add(a:log_lines, 'ENTERING THE RED: A ' . l:spawn.name . ' enters the scene. Surge Count +3.')
    endif
  elseif a:modifier ==# 'enter stage left'
    let l:val = str2nr(split(reltimestr(reltime()), '\.')[1])
    let l:names = ['Strider Velari', 'Twilightrider Onn', 'Emberogue Kresh', 'Gloamstrider Theb']
    let l:npc = l:names[l:val % len(l:names)]
    let l:next_state = game#story#records#assign_scene_npc(l:next_state, l:next_state.loc, l:npc)
    call add(a:log_lines, 'ENTER STAGE LEFT: ' . l:npc . ' arrives in the active scene.')
  elseif a:modifier ==# 'to knowledge'
    let l:next_state.stage = 'knowledge'
    call add(a:log_lines, 'TO KNOWLEDGE: Loom of Fate recalibrates the next scene toward investigation.')
  elseif a:modifier ==# 'to conflict'
    let l:next_state.stage = 'conflict'
    call add(a:log_lines, 'TO CONFLICT: Loom of Fate recalibrates the next scene toward confrontation.')
  elseif a:modifier ==# 'to endings'
    let l:next_state.stage = 'endings'
    call add(a:log_lines, 'TO ENDINGS: Loom of Fate recalibrates the next scene toward resolution.')
  elseif a:modifier ==# 'foreshadowing' || a:modifier ==# 'key grip'
    let l:focus_name = game#story#focus_label(l:next_state)
    let l:next_state = game#story#record_fact_for_thread(l:next_state, l:focus_name, 'Foreshadowing: this thread will headline the next scene.')
    call add(a:log_lines, 'FORESHADOWING: Current focus thread is locked in as the main thread for the next scene.')
  elseif a:modifier ==# 'set change'
    let l:room = get(get(l:next_state, 'rooms', {}), get(l:next_state, 'loc', ''), {})
    if !empty(l:room) && has_key(l:room, 'exits')
      for l:dir in ['north', 'south', 'east', 'west']
        if !has_key(l:room.exits, l:dir)
          let l:next_state.rooms[l:next_state.loc] = copy(l:room)
          let l:next_state.rooms[l:next_state.loc].exits = copy(l:room.exits)
          let l:next_state.rooms[l:next_state.loc].exits[l:dir] = 'unexplored'
          call add(a:log_lines, 'SET CHANGE: A new ' . l:dir . ' exit warps into existence.')
          break
        endif
      endfor
    endif
  elseif a:modifier ==# 'montage'
    let l:next_state.surge = 0
    let l:next_state.scene = copy(get(l:next_state, 'scene', {}))
    let l:next_state.scene.index = get(l:next_state.scene, 'index', 1) + 1
    call add(a:log_lines, 'MONTAGE: Timeframe accelerates. Scene index advanced; Surge reset.')
  elseif a:modifier ==# 'tying off'
    let l:focus_name = game#story#focus_label(l:next_state)
    let l:next_state = game#story#record_fact_for_thread(l:next_state, l:focus_name, 'Tying off: narrative decree pushes this thread toward resolution.')
    call add(a:log_lines, 'TYING OFF: Current focus thread receives a narrative-decreed push toward resolution.')
  elseif a:modifier ==# 'upstaged'
    let l:next_state.surge += 4
    call add(a:log_lines, 'UPSTAGED: An NPC goes into overdrive. Surge Count +4.')
  endif
  return l:next_state
endfunction
