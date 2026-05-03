" autoload/game/action.vim - RTK-style event actions for Vimscript

function! game#action#make(type, payload) abort
  return {'type': a:type, 'payload': a:payload}
endfunction

function! game#action#invalid(raw, message) abort
  return game#action#make('system/invalidInput', {'raw': a:raw, 'message': a:message})
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
    let l:dir = l:head ==# 'go' ? (len(l:parts) > 1 ? l:parts[1] : '') : l:head
    if empty(l:dir)
      return game#action#invalid(l:cmd, 'LOG_ERR: Use "go [dir]" to explore a connected room.')
    endif
    return game#action#make('explore/travelRequested', {'raw': l:cmd, 'dir': l:dir})
  elseif l:head ==# 'ask'
    let l:question = join(l:parts[1:], ' ')
    if empty(l:question)
      return game#action#invalid(l:cmd, "LOG_ERR: You must ask a question (e.g., 'ask is the door locked?').")
    endif
    return game#action#make('oracle/questionAsked', {'raw': l:cmd, 'question': l:question})
  elseif l:head ==# 'stage'
    let l:stage = len(l:parts) > 1 ? l:parts[1] : ''
    if empty(l:stage)
      return game#action#invalid(l:cmd, 'LOG_ERR: Invalid stage. Use: stage knowledge, stage conflict, or stage endings.')
    endif
    return game#action#make('oracle/stageRequested', {'raw': l:cmd, 'stage': l:stage})
  elseif l:head ==# 'thread'
    let l:subcmd = len(l:parts) > 1 ? l:parts[1] : 'list'
    let l:args = len(l:parts) > 2 ? join(l:parts[2:], ' ') : ''
    if l:subcmd ==# 'add' && empty(l:args)
      return game#action#invalid(l:cmd, 'LOG_ERR: Use "thread add [description]".')
    elseif (l:subcmd ==# 'rm' || l:subcmd ==# 'del') && empty(l:args)
      return game#action#invalid(l:cmd, 'LOG_ERR: Use a valid thread index.')
    elseif index(['mod', 'rename', 'split', 'replace'], l:subcmd) != -1 && len(l:parts) < 4
      let l:messages = {
            \ 'mod': 'LOG_ERR: Use "thread mod [thread#] [new thread]".',
            \ 'rename': 'LOG_ERR: Use "thread mod [thread#] [new thread]".',
            \ 'split': 'LOG_ERR: Use "thread split [thread#] [new thread]".',
            \ 'replace': 'LOG_ERR: Use "thread replace [thread#] [new thread]".'
            \ }
      return game#action#invalid(l:cmd, l:messages[l:subcmd])
    endif
    return game#action#make('story/threadCommandRequested', {'raw': l:cmd, 'subcmd': l:subcmd, 'args': l:args})
  elseif l:head ==# 'focus'
    let l:focus = len(l:parts) > 1 ? l:parts[1] : ''
    if empty(l:focus)
      return game#action#invalid(l:cmd, 'LOG_ERR: Use "focus [thread#]" to set the main thread for this scene.')
    endif
    return game#action#make('story/focusRequested', {'raw': l:cmd, 'focus': l:focus})
  elseif l:head ==# 'frame'
    let l:thread_ref = len(l:parts) > 1 ? l:parts[1] : ''
    let l:stage = len(l:parts) > 2 ? l:parts[2] : ''
    if empty(l:thread_ref) || empty(l:stage)
      return game#action#invalid(l:cmd, 'LOG_ERR: Use "frame [thread#] [stage]" with a valid thread index.')
    endif
    return game#action#make('story/frameRequested', {'raw': l:cmd, 'thread_ref': l:thread_ref, 'stage': l:stage})
  elseif l:head ==# 'framework' || l:head ==# 'arc'
    let l:subcmd = len(l:parts) > 1 ? l:parts[1] : 'show'
    let l:args = len(l:parts) > 2 ? join(l:parts[2:], ' ') : ''
    if l:subcmd ==# 'theme' && empty(l:args)
      return game#action#invalid(l:cmd, 'LOG_ERR: Use "framework theme [subject]" to set the vignette theme.')
    elseif l:subcmd ==# 'hook' && empty(l:args)
      return game#action#invalid(l:cmd, 'LOG_ERR: Use "framework hook [aspiration]" to set the vignette hook.')
    endif
    return game#action#make('story/frameworkRequested', {'raw': l:cmd, 'subcmd': l:subcmd, 'args': l:args})
  elseif l:head ==# 'minds' || l:head ==# 'meeting' || l:head ==# 'accord'
    let l:subcmd = len(l:parts) > 1 ? l:parts[1] : 'show'
    let l:args = len(l:parts) > 2 ? join(l:parts[2:], ' ') : ''
    if l:subcmd ==# 'focus' && empty(l:args)
      return game#action#invalid(l:cmd, 'LOG_ERR: Use "minds focus [text]" to record a focus theme.')
    elseif (l:subcmd ==# 'ban' || l:subcmd ==# 'banned') && empty(l:args)
      return game#action#invalid(l:cmd, 'LOG_ERR: Use "minds ban [text]" to record a banned theme.')
    elseif index(['note', 'assume', 'assumption'], l:subcmd) != -1 && empty(l:args)
      return game#action#invalid(l:cmd, 'LOG_ERR: Use "minds note [text]" to record a assumption.')
    elseif (l:subcmd ==# 'rm' || l:subcmd ==# 'del') && len(l:parts) < 4
      return game#action#invalid(l:cmd, 'LOG_ERR: Use "minds rm [focus|ban|note] [idx]" to remove an accord entry.')
    endif
    return game#action#make('story/meetingRequested', {'raw': l:cmd, 'subcmd': l:subcmd, 'args': l:args})
  elseif l:head ==# 'scene' || l:head ==# 'sc'
    return game#action#make('story/sceneReviewed', {'raw': l:cmd})
  elseif l:head ==# 'npc'
    let l:subcmd = len(l:parts) > 1 ? l:parts[1] : 'list'
    let l:npc_name = join(l:parts[2:], ' ')
    if index(['add', 'rm', 'del'], l:subcmd) != -1 && empty(l:npc_name)
      return game#action#invalid(l:cmd, 'LOG_ERR: Use "npc add [name]" or "npc rm [name]".')
    endif
    return game#action#make('story/npcCommandRequested', {'raw': l:cmd, 'subcmd': l:subcmd, 'npc_name': l:npc_name})
  elseif l:head ==# 'fade'
    let l:summary = join(l:parts[1:], ' ')
    if empty(l:summary)
      return game#action#invalid(l:cmd, 'LOG_ERR: Use "fade [summary]" to close the current scene with an effect summary.')
    endif
    return game#action#make('story/fadeRequested', {'raw': l:cmd, 'summary': l:summary})
  elseif l:head ==# 'montage'
    let l:summary = join(l:parts[1:], ' ')
    if empty(l:summary)
      return game#action#invalid(l:cmd, 'LOG_ERR: Use "montage [summary]" to fast-forward across threads with a montage closing line.')
    endif
    return game#action#make('story/montageRequested', {'raw': l:cmd, 'summary': l:summary})
  elseif l:head ==# 'aside'
    let l:thread_ref = len(l:parts) > 1 ? l:parts[1] : ''
    let l:fact = join(l:parts[2:], ' ')
    if empty(l:thread_ref) || empty(l:fact)
      return game#action#invalid(l:cmd, 'LOG_ERR: Use "aside [thread#] [fact]" to record an elsewhere sidebar fact.')
    endif
    return game#action#make('story/asideRequested', {'raw': l:cmd, 'thread_ref': l:thread_ref, 'fact': l:fact})
  elseif l:head ==# 'quests' || l:head ==# 'objectives' || l:head ==# 'o'
    return game#action#make('story/questsRequested', {'raw': l:cmd})
  elseif l:head ==# 'notes' || l:head ==# 'journal' || l:head ==# 'facts' || l:head ==# 'j'
    return game#action#make('story/notesRequested', {'raw': l:cmd})
  elseif l:head ==# 'party' || l:head ==# 'companions'
    let l:subcmd = len(l:parts) > 1 ? l:parts[1] : 'show'
    let l:args = len(l:parts) > 2 ? join(l:parts[2:], ' ') : ''
    if l:subcmd ==# 'fade' && empty(l:args)
      return game#action#invalid(l:cmd, 'LOG_ERR: Use "party fade [name]" to pull a companion out of the main scene.')
    elseif (l:subcmd ==# 'rally' || l:subcmd ==# 'join') && empty(l:args)
      return game#action#invalid(l:cmd, 'LOG_ERR: Use "party rally [name]" to bring a companion back into the main scene.')
    elseif (l:subcmd ==# 'send' || l:subcmd ==# 'elsewhere') && (len(split(trim(l:args))) < 2 || split(trim(l:args))[-1] !~# '^\d\+$')
      return game#action#invalid(l:cmd, 'LOG_ERR: Use "party send [name] [thread#]" to send a companion elsewhere on another thread.')
    endif
    return game#action#make('party/commandRequested', {'raw': l:cmd, 'subcmd': l:subcmd, 'args': l:args})
  elseif l:head ==# 'shop' || l:head ==# 'wares' || l:head ==# 'trade' || l:head ==# 't'
    return game#action#make('economy/shopRequested', {'raw': l:cmd})
  elseif l:head ==# 'buy'
    let l:item = join(l:parts[1:], ' ')
    if empty(l:item)
      return game#action#invalid(l:cmd, 'TRADE_ERR: Use "buy [ware]" to acquire an item, spell, or upgrade.')
    endif
    return game#action#make('economy/purchaseRequested', {'raw': l:cmd, 'item': l:item})
  elseif l:head ==# 'sell'
    let l:item = join(l:parts[1:], ' ')
    if empty(l:item)
      return game#action#invalid(l:cmd, 'TRADE_ERR: Use "sell [relic]" to liquidate scavenged wares.')
    endif
    return game#action#make('economy/saleRequested', {'raw': l:cmd, 'item': l:item})
  elseif l:head ==# 'attack' || l:head ==# 'fight' || l:head ==# 'c'
    return game#action#make('combat/attackRequested', {'raw': l:cmd})
  elseif l:head ==# 'cast' || l:head ==# 'm'
    let l:spell = join(l:parts[1:], ' ')
    if empty(l:spell)
      return game#action#invalid(l:cmd, "LOG_ERR: Specify a spell to cast (e.g. 'cast Ethereal Dagger Assault').")
    endif
    return game#action#make('combat/castRequested', {'raw': l:cmd, 'spell': l:spell})
  elseif l:head ==# 'interact'
    let l:object = join(l:parts[1:], ' ')
    if empty(l:object)
      return game#action#invalid(l:cmd, "LOG_ERR: Specify an object to interact with (e.g. 'interact Arcane Terminal').")
    endif
    return game#action#make('explore/interactionRequested', {'raw': l:cmd, 'object': l:object})
  elseif l:head ==# 'use' || l:head ==# 'consume'
    let l:item = join(l:parts[1:], ' ')
    if empty(l:item)
      return game#action#invalid(l:cmd, "LOG_ERR: Specify an item to use (e.g. 'use Pollen Vial').")
    endif
    return game#action#make('player/itemUseRequested', {'raw': l:cmd, 'item': l:item})
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
