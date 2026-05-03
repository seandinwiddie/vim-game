" autoload/game/story/records.vim - Story Records and Notecards

function! game#story#records#ensure_quest(state, quest) abort
  if s:quest_index(a:state, a:quest.id) != -1
    return {'state': a:state, 'added': 0}
  endif

  let l:next_state = deepcopy(a:state)
  call add(l:next_state.quests, deepcopy(a:quest))
  let l:next_state = game#story#threads#ensure_thread(l:next_state, a:quest.thread)
  return {'state': l:next_state, 'added': 1}
endfunction

function! game#story#records#enter_location(state, loc, discovered) abort
  let l:next_state = deepcopy(a:state)
  let l:next_state.scene.location = a:loc
  let l:next_state.progress.steps += 1
  if a:discovered
    let l:next_state.scene.index += 1
    let l:next_state.progress.rooms_explored += 1
  endif
  return game#story#records#record_scene(l:next_state, a:loc)
endfunction

function! game#story#records#has_active_quest(state, quest_id) abort
  let l:idx = s:quest_index(a:state, a:quest_id)
  if l:idx == -1
    return 0
  endif
  return get(a:state.quests[l:idx], 'status', 'active') ==# 'active'
endfunction

function! game#story#records#advance_quest(state, quest_id, amount) abort
  let l:idx = s:quest_index(a:state, a:quest_id)
  if l:idx == -1
    return {'state': a:state, 'log': []}
  endif

  let l:quest = a:state.quests[l:idx]
  if get(l:quest, 'status', 'active') ==# 'complete'
    return {'state': a:state, 'log': ['OBJECTIVE CACHE: ' . l:quest.title . ' already complete.']}
  endif

  let l:next_state = deepcopy(a:state)
  let l:next_quest = l:next_state.quests[l:idx]
  let l:next_quest.progress = min([l:next_quest.goal, l:next_quest.progress + a:amount])
  let l:log_lines = ['OBJECTIVE UPDATED: ' . l:next_quest.title . ' [' . l:next_quest.progress . '/' . l:next_quest.goal . ']']

  if l:next_quest.progress >= l:next_quest.goal
    let l:next_quest.status = 'complete'
    call add(l:log_lines, 'OBJECTIVE COMPLETE: ' . l:next_quest.title)

    if !empty(get(l:next_quest, 'reward_item', '')) && index(l:next_state.player.inv, l:next_quest.reward_item) == -1
      call add(l:next_state.player.inv, l:next_quest.reward_item)
      call add(l:log_lines, 'REWARD ITEM: ' . l:next_quest.reward_item)
    endif
    if !empty(get(l:next_quest, 'reward_spell', '')) && index(l:next_state.player.spells, l:next_quest.reward_spell) == -1
      call add(l:next_state.player.spells, l:next_quest.reward_spell)
      call add(l:log_lines, 'REWARD SPELL: ' . l:next_quest.reward_spell)
    endif
  endif

  return {'state': l:next_state, 'log': l:log_lines}
endfunction

function! game#story#records#record_scene(state, loc) abort
  let l:next_state = s:ensure_scene_card(a:state, a:loc)
  let l:next_state = game#party#sync_scene(l:next_state)
  let l:scene_idx = game#story#records#scene_card_index(l:next_state.notes.scene_cards, a:loc)
  let l:next_state.notes.scene_cards[l:scene_idx].visits += 1
  let l:title = l:next_state.notes.scene_cards[l:scene_idx].title
  let l:focus = l:next_state.notes.scene_cards[l:scene_idx].focus
  let l:scene_npcs = get(l:next_state.notes.scene_cards[l:scene_idx], 'npcs', [])

  let l:thread_idx = game#story#threads#thread_card_index(l:next_state.notes.thread_cards, l:focus)
  if l:thread_idx == -1
    call add(l:next_state.notes.thread_cards, game#story#threads#default_card(l:focus, l:next_state.stage))
    let l:thread_idx = len(l:next_state.notes.thread_cards) - 1
  endif
  let l:next_state.notes.thread_cards[l:thread_idx] = game#story#threads#normalize_card(l:next_state.notes.thread_cards[l:thread_idx], l:next_state.stage)
  let l:next_state.notes.thread_cards[l:thread_idx].stage = l:next_state.stage
  if index(l:next_state.notes.thread_cards[l:thread_idx].scenes, l:title) == -1
    call add(l:next_state.notes.thread_cards[l:thread_idx].scenes, l:title)
  endif
  for l:npc_name in l:scene_npcs
    if index(l:next_state.notes.thread_cards[l:thread_idx].npcs, l:npc_name) == -1
      call add(l:next_state.notes.thread_cards[l:thread_idx].npcs, l:npc_name)
      if len(l:next_state.notes.thread_cards[l:thread_idx].npcs) > 6
        let l:next_state.notes.thread_cards[l:thread_idx].npcs = l:next_state.notes.thread_cards[l:thread_idx].npcs[-6:]
      endif
    endif
  endfor

  return l:next_state
endfunction

function! game#story#records#append_scene_closing(state, loc, summary) abort
  let l:next_state = s:ensure_scene_card(a:state, a:loc)
  let l:idx = game#story#records#scene_card_index(l:next_state.notes.scene_cards, a:loc)
  if l:idx == -1
    return l:next_state
  endif

  if !has_key(l:next_state.notes.scene_cards[l:idx], 'closings')
    let l:next_state.notes.scene_cards[l:idx].closings = []
  endif
  call add(l:next_state.notes.scene_cards[l:idx].closings, a:summary)
  if len(l:next_state.notes.scene_cards[l:idx].closings) > 4
    let l:next_state.notes.scene_cards[l:idx].closings = l:next_state.notes.scene_cards[l:idx].closings[-4:]
  endif
  return l:next_state
endfunction

function! game#story#records#append_scene_opening(state, loc, summary) abort
  let l:next_state = s:ensure_scene_card(a:state, a:loc)
  let l:idx = game#story#records#scene_card_index(l:next_state.notes.scene_cards, a:loc)
  if l:idx == -1
    return l:next_state
  endif

  if !has_key(l:next_state.notes.scene_cards[l:idx], 'openings')
    let l:next_state.notes.scene_cards[l:idx].openings = []
  endif
  call add(l:next_state.notes.scene_cards[l:idx].openings, a:summary)
  if len(l:next_state.notes.scene_cards[l:idx].openings) > 4
    let l:next_state.notes.scene_cards[l:idx].openings = l:next_state.notes.scene_cards[l:idx].openings[-4:]
  endif
  return l:next_state
endfunction

function! game#story#records#record_npc(state, npc_name, scene_name) abort
  if empty(a:npc_name)
    return a:state
  endif

  let l:next_state = deepcopy(a:state)
  let l:idx = game#story#records#npc_card_index(l:next_state.notes.npc_cards, a:npc_name)
  if l:idx == -1
    call add(l:next_state.notes.npc_cards, {'name': a:npc_name, 'scenes': empty(a:scene_name) ? [] : [a:scene_name]})
  elseif !empty(a:scene_name) && index(l:next_state.notes.npc_cards[l:idx].scenes, a:scene_name) == -1
    call add(l:next_state.notes.npc_cards[l:idx].scenes, a:scene_name)
  endif
  return l:next_state
endfunction

function! game#story#records#assign_scene_npc(state, loc, npc_name) abort
  let l:next_state = s:ensure_scene_card(a:state, a:loc)
  let l:idx = game#story#records#scene_card_index(l:next_state.notes.scene_cards, a:loc)
  if l:idx == -1
    return l:next_state
  endif

  if index(l:next_state.notes.scene_cards[l:idx].npcs, a:npc_name) == -1
    call add(l:next_state.notes.scene_cards[l:idx].npcs, a:npc_name)
  endif
  let l:next_state = game#story#records#record_npc(l:next_state, a:npc_name, l:next_state.notes.scene_cards[l:idx].title)
  return game#story#threads#record_npc_for_thread(l:next_state, game#story#state#focus_label(l:next_state), a:npc_name)
endfunction

function! game#story#records#remove_scene_npc(state, loc, npc_name) abort
  let l:next_state = s:ensure_scene_card(a:state, a:loc)
  let l:idx = game#story#records#scene_card_index(l:next_state.notes.scene_cards, a:loc)
  if l:idx == -1
    return l:next_state
  endif

  let l:npc_idx = index(l:next_state.notes.scene_cards[l:idx].npcs, a:npc_name)
  if l:npc_idx != -1
    call remove(l:next_state.notes.scene_cards[l:idx].npcs, l:npc_idx)
  endif
  return l:next_state
endfunction

function! game#story#records#scene_card_index(cards, loc) abort
  let l:idx = 0
  for l:card in a:cards
    if get(l:card, 'loc', '') ==# a:loc
      return l:idx
    endif
    let l:idx += 1
  endfor
  return -1
endfunction

function! game#story#records#npc_card_index(cards, npc_name) abort
  let l:idx = 0
  for l:card in a:cards
    if get(l:card, 'name', '') ==# a:npc_name
      return l:idx
    endif
    let l:idx += 1
  endfor
  return -1
endfunction

function! game#story#records#get_scene_card(cards, loc) abort
  let l:idx = game#story#records#scene_card_index(a:cards, a:loc)
  return l:idx == -1 ? {} : a:cards[l:idx]
endfunction

function! s:quest_index(state, quest_id) abort
  let l:idx = 0
  for l:quest in get(a:state, 'quests', [])
    if get(l:quest, 'id', '') ==# a:quest_id
      return l:idx
    endif
    let l:idx += 1
  endfor
  return -1
endfunction

function! s:ensure_scene_card(state, loc) abort
  let l:next_state = deepcopy(a:state)
  let l:title = has_key(get(l:next_state, 'rooms', {}), a:loc) ? get(l:next_state.rooms[a:loc], 'name', toupper(a:loc)) : toupper(a:loc)
  let l:focus = game#story#state#focus_label(l:next_state)
  let l:idx = game#story#records#scene_card_index(l:next_state.notes.scene_cards, a:loc)

  if l:idx == -1
    call add(l:next_state.notes.scene_cards, {
          \ 'loc': a:loc,
          \ 'title': l:title,
          \ 'visits': 0,
          \ 'stage': l:next_state.stage,
          \ 'focus': l:focus,
          \ 'framework_phase': get(get(l:next_state, 'framework', {}), 'phase', 'exposition'),
          \ 'framework_chapter': get(get(l:next_state, 'framework', {}), 'chapter', 1),
          \ 'closings': [],
          \ 'openings': [],
          \ 'npcs': []
          \ })
  else
    let l:next_state.notes.scene_cards[l:idx].stage = l:next_state.stage
    let l:next_state.notes.scene_cards[l:idx].focus = l:focus
    let l:next_state.notes.scene_cards[l:idx].framework_phase = get(get(l:next_state, 'framework', {}), 'phase', 'exposition')
    let l:next_state.notes.scene_cards[l:idx].framework_chapter = get(get(l:next_state, 'framework', {}), 'chapter', 1)
    if !has_key(l:next_state.notes.scene_cards[l:idx], 'closings')
      let l:next_state.notes.scene_cards[l:idx].closings = []
    endif
    if !has_key(l:next_state.notes.scene_cards[l:idx], 'openings')
      let l:next_state.notes.scene_cards[l:idx].openings = []
    endif
    if !has_key(l:next_state.notes.scene_cards[l:idx], 'npcs')
      let l:next_state.notes.scene_cards[l:idx].npcs = []
    endif
    if !has_key(l:next_state.notes.scene_cards[l:idx], 'framework_phase')
      let l:next_state.notes.scene_cards[l:idx].framework_phase = get(get(l:next_state, 'framework', {}), 'phase', 'exposition')
    endif
    if !has_key(l:next_state.notes.scene_cards[l:idx], 'framework_chapter')
      let l:next_state.notes.scene_cards[l:idx].framework_chapter = get(get(l:next_state, 'framework', {}), 'chapter', 1)
    endif
  endif

  return l:next_state
endfunction
