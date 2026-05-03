" autoload/game/action.vim - RTK-style event actions for Vimscript

function! game#action#make(type, payload) abort
  return {'type': a:type, 'payload': a:payload}
endfunction

function! game#action#command(input) abort
  let l:cmd = tolower(trim(a:input))
  let l:parts = split(l:cmd)
  if empty(l:parts)
    return game#action#make('system/noop', {'raw': a:input})
  endif

  let l:head = l:parts[0]
  if l:head ==# 'look' || l:head ==# 'l'
    return game#action#make('explore/lookRequested', {'raw': l:cmd})
  elseif l:head ==# 'go' || l:head ==# 'n' || l:head ==# 's' || l:head ==# 'e' || l:head ==# 'w'
    let l:dir = len(l:parts) > 1 ? l:parts[1] : l:head
    return game#action#make('explore/travelRequested', {'raw': l:cmd, 'dir': l:dir})
  elseif l:head ==# 'ask'
    return game#action#make('oracle/questionAsked', {'raw': l:cmd, 'question': join(l:parts[1:], ' ')})
  elseif l:head ==# 'stage'
    return game#action#make('oracle/stageRequested', {'raw': l:cmd, 'stage': len(l:parts) > 1 ? l:parts[1] : ''})
  elseif l:head ==# 'thread'
    return game#action#make('story/threadCommandRequested', {'raw': l:cmd, 'subcmd': len(l:parts) > 1 ? l:parts[1] : 'list', 'args': len(l:parts) > 2 ? join(l:parts[2:], ' ') : ''})
  elseif l:head ==# 'focus'
    return game#action#make('story/focusRequested', {'raw': l:cmd, 'focus': len(l:parts) > 1 ? l:parts[1] : ''})
  elseif l:head ==# 'frame'
    return game#action#make('story/frameRequested', {'raw': l:cmd, 'thread_ref': len(l:parts) > 1 ? l:parts[1] : '', 'stage': len(l:parts) > 2 ? l:parts[2] : ''})
  elseif l:head ==# 'scene' || l:head ==# 'sc'
    return game#action#make('story/sceneReviewed', {'raw': l:cmd})
  elseif l:head ==# 'npc'
    return game#action#make('story/npcCommandRequested', {'raw': l:cmd, 'subcmd': len(l:parts) > 1 ? l:parts[1] : 'list', 'npc_name': join(l:parts[2:], ' ')})
  elseif l:head ==# 'fade'
    return game#action#make('story/fadeRequested', {'raw': l:cmd, 'summary': join(l:parts[1:], ' ')})
  elseif l:head ==# 'aside'
    return game#action#make('story/asideRequested', {'raw': l:cmd, 'thread_ref': len(l:parts) > 1 ? l:parts[1] : '', 'fact': join(l:parts[2:], ' ')})
  elseif l:head ==# 'quests' || l:head ==# 'objectives' || l:head ==# 'o'
    return game#action#make('story/questsRequested', {'raw': l:cmd})
  elseif l:head ==# 'notes' || l:head ==# 'journal' || l:head ==# 'facts' || l:head ==# 'j'
    return game#action#make('story/notesRequested', {'raw': l:cmd})
  elseif l:head ==# 'shop' || l:head ==# 'wares' || l:head ==# 'trade' || l:head ==# 't'
    return game#action#make('economy/shopRequested', {'raw': l:cmd})
  elseif l:head ==# 'buy'
    return game#action#make('economy/purchaseRequested', {'raw': l:cmd, 'item': join(l:parts[1:], ' ')})
  elseif l:head ==# 'sell'
    return game#action#make('economy/saleRequested', {'raw': l:cmd, 'item': join(l:parts[1:], ' ')})
  elseif l:head ==# 'attack' || l:head ==# 'fight' || l:head ==# 'c'
    return game#action#make('combat/attackRequested', {'raw': l:cmd})
  elseif l:head ==# 'cast' || l:head ==# 'm'
    return game#action#make('combat/castRequested', {'raw': l:cmd, 'spell': join(l:parts[1:], ' ')})
  elseif l:head ==# 'interact'
    return game#action#make('explore/interactionRequested', {'raw': l:cmd, 'object': join(l:parts[1:], ' ')})
  elseif l:head ==# 'use' || l:head ==# 'consume'
    return game#action#make('player/itemUseRequested', {'raw': l:cmd, 'item': join(l:parts[1:], ' ')})
  elseif l:head ==# 'inventory' || l:head ==# 'i'
    return game#action#make('player/inventoryRequested', {'raw': l:cmd})
  elseif l:head ==# 'profile' || l:head ==# 'p'
    return game#action#make('player/profileRequested', {'raw': l:cmd})
  elseif l:head ==# 'rest' || l:head ==# 'r'
    return game#action#make('player/restRequested', {'raw': l:cmd})
  elseif l:head ==# 'save'
    return game#action#make('player/saveRequested', {'raw': l:cmd})
  elseif l:head ==# 'load'
    return game#action#make('player/loadRequested', {'raw': l:cmd})
  endif

  return game#action#make('system/unknownCommand', {'raw': l:cmd, 'name': l:head})
endfunction
