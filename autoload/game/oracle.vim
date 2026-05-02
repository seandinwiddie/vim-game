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

function! game#oracle#cmd_thread(state, subcmd, args) abort
  let l:next_state = copy(a:state)
  if a:subcmd ==# 'add'
    call add(l:next_state.threads, a:args)
    return game#core#add_log(l:next_state, "THREAD ADDED: " . a:args)
  elseif a:subcmd ==# 'rm' || a:subcmd ==# 'del'
    let l:idx = str2nr(a:args) - 1
    if l:idx >= 0 && l:idx < len(l:next_state.threads)
      let l:removed = remove(l:next_state.threads, l:idx)
      return game#core#add_log(l:next_state, "THREAD RESOLVED: " . l:removed)
    endif
    return game#core#add_log(a:state, "LOG_ERR: Invalid thread index.")
  endif
  return game#core#add_log(a:state, "LOG_ERR: Unknown thread subcommand.")
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

  if l:is_unexpected
    let l:val2 = str2nr(split(reltimestr(reltime()), '\.')[1])
    let l:d20 = (l:val2 % 20) + 1
    let l:table2 = ['foreshadowing', 'tying off', 'to conflict', 'costume change', 'key grip', 'to knowledge', 'framing', 'set change', 'upstaged', 'pattern change', 'limelit', 'entering the red', 'to endings', 'montage', 'enter stage left', 'cross-stitch', 'six degrees', 're-roll/reserved', 're-roll/reserved', 're-roll/reserved']
    let l:modifier = l:table2[l:d20 - 1]
    call add(l:log_lines, "UNEXPECTED MODIFIER: " . toupper(l:modifier))
  endif

  return game#core#add_log(l:next_state, l:log_lines)
endfunction
