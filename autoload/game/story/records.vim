" autoload/game/story/records.vim - Story Records and Notecards

function! game#story#records#ensure_quest(state, quest) abort
  return game#quest#ensure(a:state, a:quest)
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
  return game#quest#has_active(a:state, a:quest_id)
endfunction

function! game#story#records#advance_quest(state, quest_id, amount) abort
  return game#quest#advance(a:state, a:quest_id, a:amount)
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
    call add(l:next_state.notes.thread_cards, game#story#cards#new_thread(l:focus, l:next_state.stage))
    let l:thread_idx = len(l:next_state.notes.thread_cards) - 1
  endif
  let l:next_state.notes.thread_cards[l:thread_idx] = game#story#cards#normalize_thread(l:next_state.notes.thread_cards[l:thread_idx], l:next_state.stage)
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
    call add(l:next_state.notes.npc_cards, game#story#cards#new_npc(a:npc_name, a:scene_name))
  else
    let l:next_state.notes.npc_cards[l:idx] = game#story#cards#normalize_npc(l:next_state.notes.npc_cards[l:idx])
    if !empty(a:scene_name) && index(l:next_state.notes.npc_cards[l:idx].scenes, a:scene_name) == -1
      call add(l:next_state.notes.npc_cards[l:idx].scenes, a:scene_name)
    endif
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

function! s:ensure_scene_card(state, loc) abort
  let l:next_state = deepcopy(a:state)
  let l:defaults = s:scene_card_defaults(l:next_state, a:loc)
  let l:idx = game#story#records#scene_card_index(l:next_state.notes.scene_cards, a:loc)
  let l:card = l:idx == -1
        \ ? game#story#cards#new_scene(l:defaults.loc, l:defaults.title, l:defaults.stage, l:defaults.focus, l:defaults.framework_phase, l:defaults.framework_chapter)
        \ : game#story#cards#normalize_scene(l:next_state.notes.scene_cards[l:idx], l:defaults)
  let l:card.stage = l:defaults.stage
  let l:card.focus = l:defaults.focus
  let l:card.framework_phase = l:defaults.framework_phase
  let l:card.framework_chapter = l:defaults.framework_chapter

  if l:idx == -1
    call add(l:next_state.notes.scene_cards, l:card)
  else
    let l:next_state.notes.scene_cards[l:idx] = l:card
  endif

  return l:next_state
endfunction

function! s:scene_card_defaults(state, loc) abort
  let l:title = has_key(get(a:state, 'rooms', {}), a:loc) ? get(a:state.rooms[a:loc], 'name', toupper(a:loc)) : toupper(a:loc)
  return {
        \ 'loc': a:loc,
        \ 'title': l:title,
        \ 'visits': 0,
        \ 'stage': a:state.stage,
        \ 'focus': game#story#state#focus_label(a:state),
        \ 'framework_phase': get(get(a:state, 'framework', {}), 'phase', 'exposition'),
        \ 'framework_chapter': get(get(a:state, 'framework', {}), 'chapter', 1),
        \ 'closings': [],
        \ 'openings': [],
        \ 'npcs': []
        \ }
endfunction
