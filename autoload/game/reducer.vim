" autoload/game/reducer.vim - Root reducer for event-style actions

function! game#reducer#reduce(state, action) abort
  let l:next_state = deepcopy(a:state)
  let l:type = get(a:action, 'type', '')
  let l:payload = get(a:action, 'payload', {})

  if l:type ==# 'system/noop'
    return l:next_state
  elseif l:type ==# 'system/undo'
    return game#core#reset_render_cursor(deepcopy(get(l:payload, 'previous_state', l:next_state)))
  elseif l:type ==# 'system/undoRequested'
    return game#core#add_log(l:next_state, 'LOG_ERR: No earlier turn is available to undo.')
  elseif l:type ==# 'system/helpRequested'
    return game#core#cmd_help(l:next_state)
  elseif l:type ==# 'system/invalidInput'
    return game#core#add_log(l:next_state, get(l:payload, 'message', 'LOG_ERR: Invalid input.'))
  elseif l:type ==# 'explore/lookRequested'
    return game#explore#cmd_look(l:next_state)
  elseif l:type ==# 'explore/travelRequested'
    return game#explore#cmd_go(l:next_state, get(l:payload, 'dir', ''))
  elseif l:type ==# 'oracle/questionAsked'
    return game#oracle#cmd_ask(l:next_state, get(l:payload, 'question', ''))
  elseif l:type ==# 'oracle/stageRequested'
    return game#oracle#cmd_stage(l:next_state, get(l:payload, 'stage', ''))
  elseif l:type ==# 'story/threadCommandRequested'
    return game#story#cmd_thread(l:next_state, get(l:payload, 'subcmd', 'list'), get(l:payload, 'args', ''))
  elseif l:type ==# 'story/focusRequested'
    return game#story#cmd_focus(l:next_state, get(l:payload, 'focus', ''))
  elseif l:type ==# 'story/frameRequested'
    return game#story#cmd_frame(l:next_state, get(l:payload, 'thread_ref', ''), get(l:payload, 'stage', ''))
  elseif l:type ==# 'story/frameworkRequested'
    return game#story#cmd_framework(l:next_state, get(l:payload, 'subcmd', 'show'), get(l:payload, 'args', ''))
  elseif l:type ==# 'story/meetingRequested'
    return game#story#cmd_meeting(l:next_state, get(l:payload, 'subcmd', 'show'), get(l:payload, 'args', ''))
  elseif l:type ==# 'story/sceneReviewed'
    return game#story#cmd_scene(l:next_state)
  elseif l:type ==# 'story/npcCommandRequested'
    return game#story#cmd_npc(l:next_state, get(l:payload, 'subcmd', 'list'), get(l:payload, 'npc_name', ''))
  elseif l:type ==# 'story/fadeRequested'
    return game#story#cmd_fade(l:next_state, get(l:payload, 'summary', ''))
  elseif l:type ==# 'story/montageRequested'
    return game#story#cmd_montage(l:next_state, get(l:payload, 'summary', ''))
  elseif l:type ==# 'story/asideRequested'
    return game#story#cmd_aside(l:next_state, get(l:payload, 'thread_ref', ''), get(l:payload, 'fact', ''))
  elseif l:type ==# 'story/questsRequested'
    return game#story#cmd_quests(l:next_state)
  elseif l:type ==# 'story/notesRequested'
    return game#story#cmd_notes(l:next_state)
  elseif l:type ==# 'party/commandRequested'
    return game#party#cmd_party(l:next_state, get(l:payload, 'subcmd', 'show'), get(l:payload, 'args', ''))
  elseif l:type ==# 'economy/shopRequested'
    return game#economy#cmd_shop(l:next_state)
  elseif l:type ==# 'economy/purchaseRequested'
    return game#economy#cmd_buy(l:next_state, get(l:payload, 'item', ''))
  elseif l:type ==# 'economy/saleRequested'
    return game#economy#cmd_sell(l:next_state, get(l:payload, 'item', ''))
  elseif l:type ==# 'combat/attackRequested'
    return game#combat#cmd_attack(l:next_state)
  elseif l:type ==# 'combat/castRequested'
    return game#combat#cmd_cast(l:next_state, get(l:payload, 'spell', ''))
  elseif l:type ==# 'explore/interactionRequested'
    return game#explore#cmd_interact(l:next_state, get(l:payload, 'object', ''))
  elseif l:type ==# 'player/itemUseRequested'
    return game#player#cmd_use(l:next_state, get(l:payload, 'item', ''))
  elseif l:type ==# 'player/inventoryRequested'
    return game#player#cmd_inventory(l:next_state)
  elseif l:type ==# 'player/profileRequested'
    return game#player#cmd_profile(l:next_state)
  elseif l:type ==# 'player/restRequested'
    return game#player#cmd_rest(l:next_state)
  elseif l:type ==# 'player/saveRequested'
    return game#player#cmd_save(l:next_state)
  elseif l:type ==# 'player/loadRequested'
    return game#player#cmd_load(l:next_state)
  elseif l:type ==# 'system/unknownCommand'
    return game#core#add_log(l:next_state, "LOG_ERR_CRITICAL: Unknown input_vector '" . get(l:payload, 'name', '') . "'")
  endif

  return game#core#add_log(l:next_state, "LOG_ERR_CRITICAL: Unknown action_vector '" . l:type . "'")
endfunction
