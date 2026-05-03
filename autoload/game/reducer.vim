" autoload/game/reducer.vim - Root reducer for event-style actions

function! game#reducer#reduce(state, action) abort
  let l:type = get(a:action, 'type', '')
  let l:payload = get(a:action, 'payload', {})

  if l:type ==# 'system/noop'
    return a:state
  elseif l:type ==# 'explore/lookRequested'
    return game#explore#cmd_look(a:state)
  elseif l:type ==# 'explore/travelRequested'
    return game#explore#cmd_go(a:state, get(l:payload, 'dir', ''))
  elseif l:type ==# 'oracle/questionAsked'
    return game#oracle#cmd_ask(a:state, get(l:payload, 'question', ''))
  elseif l:type ==# 'oracle/stageRequested'
    return game#oracle#cmd_stage(a:state, get(l:payload, 'stage', ''))
  elseif l:type ==# 'story/threadCommandRequested'
    return game#story#cmd_thread(a:state, get(l:payload, 'subcmd', 'list'), get(l:payload, 'args', ''))
  elseif l:type ==# 'story/focusRequested'
    return game#story#cmd_focus(a:state, get(l:payload, 'focus', ''))
  elseif l:type ==# 'story/frameRequested'
    return game#story#cmd_frame(a:state, get(l:payload, 'thread_ref', ''), get(l:payload, 'stage', ''))
  elseif l:type ==# 'story/frameworkRequested'
    return game#story#cmd_framework(a:state, get(l:payload, 'subcmd', 'show'), get(l:payload, 'args', ''))
  elseif l:type ==# 'story/meetingRequested'
    return game#story#cmd_meeting(a:state, get(l:payload, 'subcmd', 'show'), get(l:payload, 'args', ''))
  elseif l:type ==# 'story/sceneReviewed'
    return game#story#cmd_scene(a:state)
  elseif l:type ==# 'story/npcCommandRequested'
    return game#story#cmd_npc(a:state, get(l:payload, 'subcmd', 'list'), get(l:payload, 'npc_name', ''))
  elseif l:type ==# 'story/fadeRequested'
    return game#story#cmd_fade(a:state, get(l:payload, 'summary', ''))
  elseif l:type ==# 'story/asideRequested'
    return game#story#cmd_aside(a:state, get(l:payload, 'thread_ref', ''), get(l:payload, 'fact', ''))
  elseif l:type ==# 'story/questsRequested'
    return game#story#cmd_quests(a:state)
  elseif l:type ==# 'story/notesRequested'
    return game#story#cmd_notes(a:state)
  elseif l:type ==# 'party/commandRequested'
    return game#party#cmd_party(a:state, get(l:payload, 'subcmd', 'show'), get(l:payload, 'args', ''))
  elseif l:type ==# 'economy/shopRequested'
    return game#economy#cmd_shop(a:state)
  elseif l:type ==# 'economy/purchaseRequested'
    return game#economy#cmd_buy(a:state, get(l:payload, 'item', ''))
  elseif l:type ==# 'economy/saleRequested'
    return game#economy#cmd_sell(a:state, get(l:payload, 'item', ''))
  elseif l:type ==# 'combat/attackRequested'
    return game#combat#cmd_attack(a:state)
  elseif l:type ==# 'combat/castRequested'
    return game#combat#cmd_cast(a:state, get(l:payload, 'spell', ''))
  elseif l:type ==# 'explore/interactionRequested'
    return game#explore#cmd_interact(a:state, get(l:payload, 'object', ''))
  elseif l:type ==# 'player/itemUseRequested'
    return game#player#cmd_use(a:state, get(l:payload, 'item', ''))
  elseif l:type ==# 'player/inventoryRequested'
    return game#player#cmd_inventory(a:state)
  elseif l:type ==# 'player/profileRequested'
    return game#player#cmd_profile(a:state)
  elseif l:type ==# 'player/restRequested'
    return game#player#cmd_rest(a:state)
  elseif l:type ==# 'player/saveRequested'
    return game#player#cmd_save(a:state)
  elseif l:type ==# 'player/loadRequested'
    return game#player#cmd_load(a:state)
  elseif l:type ==# 'system/unknownCommand'
    return game#core#add_log(a:state, "LOG_ERR_CRITICAL: Unknown input_vector '" . get(l:payload, 'name', '') . "'")
  endif

  return game#core#add_log(a:state, "LOG_ERR_CRITICAL: Unknown action_vector '" . l:type . "'")
endfunction
