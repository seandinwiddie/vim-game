" autoload/game/quest.vim - Quest Lifecycle and Rewards

function! game#quest#new(definition) abort
  let l:quest = {
        \ 'id': '',
        \ 'title': '',
        \ 'thread': '',
        \ 'objective': '',
        \ 'target_hint': '',
        \ 'status': 'active',
        \ 'progress': 0,
        \ 'goal': 1,
        \ 'reward_item': '',
        \ 'reward_spell': ''
        \ }
  return extend(l:quest, deepcopy(a:definition), 'force')
endfunction

function! game#quest#normalize(quest) abort
  let l:quest = game#quest#new(a:quest)
  let l:quest.status = s:normalize_status(get(l:quest, 'status', 'active'))
  let l:quest.goal = max([1, get(l:quest, 'goal', 1)])
  let l:quest.progress = max([0, min([l:quest.goal, get(l:quest, 'progress', 0)])])
  if l:quest.status ==# 'complete'
    let l:quest.progress = l:quest.goal
  endif
  return l:quest
endfunction

function! game#quest#index(quests, quest_id) abort
  let l:idx = 0
  for l:quest in a:quests
    if get(l:quest, 'id', '') ==# a:quest_id
      return l:idx
    endif
    let l:idx += 1
  endfor
  return -1
endfunction

function! game#quest#get(state, quest_id) abort
  let l:idx = game#quest#index(get(a:state, 'quests', []), a:quest_id)
  return l:idx == -1 ? {} : game#quest#normalize(a:state.quests[l:idx])
endfunction

function! game#quest#ensure(state, quest) abort
  let l:quest = game#quest#normalize(a:quest)
  if game#quest#index(get(a:state, 'quests', []), l:quest.id) != -1
    return {'state': a:state, 'added': 0}
  endif

  let l:next_state = deepcopy(a:state)
  call add(l:next_state.quests, l:quest)
  let l:next_state = game#story#threads#ensure_thread(l:next_state, l:quest.thread)
  return {'state': l:next_state, 'added': 1}
endfunction

function! game#quest#has_active(state, quest_id) abort
  return get(game#quest#get(a:state, a:quest_id), 'status', '') ==# 'active'
endfunction

function! game#quest#is_complete(state, quest_id) abort
  return get(game#quest#get(a:state, a:quest_id), 'status', '') ==# 'complete'
endfunction

function! game#quest#set_status(state, quest_id, status) abort
  let l:idx = game#quest#index(get(a:state, 'quests', []), a:quest_id)
  if l:idx == -1
    return {'state': a:state, 'log': [], 'events': []}
  endif

  let l:current = game#quest#normalize(a:state.quests[l:idx])
  let l:next_status = s:normalize_status(a:status)
  if l:current.status ==# l:next_status
    return {'state': a:state, 'log': [], 'events': []}
  endif
  if !s:can_transition(l:current.status, l:next_status)
    return {'state': a:state, 'log': ['OBJECTIVE_ERR: Invalid quest status transition for ' . l:current.title . '.'], 'events': []}
  endif

  let l:next_state = deepcopy(a:state)
  let l:next_quest = game#quest#normalize(l:next_state.quests[l:idx])
  let l:next_quest.status = l:next_status
  if l:next_status ==# 'complete'
    let l:next_quest.progress = l:next_quest.goal
  endif
  let l:next_state.quests[l:idx] = l:next_quest
  let l:events = s:events_for_transition(l:current.status, l:next_status, l:next_quest)
  let l:event_result = s:apply_events(l:next_state, l:events)
  return {'state': l:event_result.state, 'log': l:event_result.log, 'events': l:events}
endfunction

function! game#quest#advance(state, quest_id, amount) abort
  let l:idx = game#quest#index(get(a:state, 'quests', []), a:quest_id)
  if l:idx == -1
    return {'state': a:state, 'log': [], 'events': []}
  endif

  let l:quest = game#quest#normalize(a:state.quests[l:idx])
  if l:quest.status ==# 'complete'
    return {'state': a:state, 'log': ['OBJECTIVE CACHE: ' . l:quest.title . ' already complete.'], 'events': []}
  endif
  if l:quest.status !=# 'active'
    return {'state': a:state, 'log': ['OBJECTIVE CACHE: ' . l:quest.title . ' is no longer active.'], 'events': []}
  endif

  let l:next_state = deepcopy(a:state)
  let l:next_quest = game#quest#normalize(l:next_state.quests[l:idx])
  let l:next_quest.progress = min([l:next_quest.goal, l:next_quest.progress + a:amount])
  let l:next_state.quests[l:idx] = l:next_quest
  let l:log_lines = ['OBJECTIVE UPDATED: ' . l:next_quest.title . ' [' . l:next_quest.progress . '/' . l:next_quest.goal . ']']

  if l:next_quest.progress < l:next_quest.goal
    return {'state': l:next_state, 'log': l:log_lines, 'events': []}
  endif

  let l:completion = game#quest#set_status(l:next_state, a:quest_id, 'complete')
  let l:log_lines += ['OBJECTIVE COMPLETE: ' . l:next_quest.title] + l:completion.log
  return {'state': l:completion.state, 'log': l:log_lines, 'events': get(l:completion, 'events', [])}
endfunction

function! s:normalize_status(status) abort
  return index(['active', 'complete', 'replaced'], a:status) == -1 ? 'active' : a:status
endfunction

function! s:can_transition(current, next) abort
  return a:current ==# 'active' && index(['complete', 'replaced'], a:next) != -1
endfunction

function! s:events_for_transition(current, next, quest) abort
  if a:current ==# 'active' && a:next ==# 'complete'
    return [{'type': 'quest/completed', 'quest': deepcopy(a:quest)}]
  endif
  if a:current ==# 'active' && a:next ==# 'replaced'
    return [{'type': 'quest/replaced', 'quest': deepcopy(a:quest)}]
  endif
  return []
endfunction

function! s:apply_events(state, events) abort
  let l:next_state = a:state
  let l:log_lines = []

  for l:event in a:events
    if get(l:event, 'type', '') ==# 'quest/completed'
      let l:result = s:on_completed(l:next_state, get(l:event, 'quest', {}))
      let l:next_state = l:result.state
      let l:log_lines += l:result.log
    elseif get(l:event, 'type', '') ==# 'quest/replaced'
      let l:result = s:on_replaced(l:next_state, get(l:event, 'quest', {}))
      let l:next_state = l:result.state
      let l:log_lines += l:result.log
    endif
  endfor

  return {'state': l:next_state, 'log': l:log_lines}
endfunction

function! s:on_completed(state, quest) abort
  let l:next_state = a:state
  let l:log_lines = []

  if !empty(get(a:quest, 'reward_item', '')) && index(get(get(l:next_state, 'player', {}), 'inv', []), a:quest.reward_item) == -1
    call add(l:next_state.player.inv, a:quest.reward_item)
    call add(l:log_lines, 'REWARD ITEM: ' . a:quest.reward_item)
  endif
  if !empty(get(a:quest, 'reward_spell', '')) && index(get(get(l:next_state, 'player', {}), 'spells', []), a:quest.reward_spell) == -1
    call add(l:next_state.player.spells, a:quest.reward_spell)
    call add(l:log_lines, 'REWARD SPELL: ' . a:quest.reward_spell)
  endif

  return {'state': l:next_state, 'log': l:log_lines}
endfunction

function! s:on_replaced(state, _quest) abort
  return {'state': a:state, 'log': []}
endfunction
