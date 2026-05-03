" autoload/game/story/threads.vim - Thread Ledger and Fallout Bookkeeping

function! game#story#threads#default_card(thread_name, stage) abort
  return {
        \ 'name': a:thread_name,
        \ 'stage': a:stage,
        \ 'scenes': [],
        \ 'facts': [],
        \ 'status': 'open',
        \ 'aliases': [],
        \ 'split_from': '',
        \ 'split_into': [],
        \ 'replaced_from': '',
        \ 'replaced_by': ''
        \ }
endfunction

function! game#story#threads#normalize_card(card, stage) abort
  let l:card = deepcopy(a:card)
  let l:defaults = game#story#threads#default_card(get(l:card, 'name', ''), a:stage)
  for l:key in keys(l:defaults)
    if !has_key(l:card, l:key)
      let l:card[l:key] = deepcopy(l:defaults[l:key])
    endif
  endfor
  return l:card
endfunction

function! game#story#threads#thread_card_index(cards, thread_name) abort
  let l:idx = 0
  for l:card in a:cards
    if get(l:card, 'name', '') ==# a:thread_name
      return l:idx
    endif
    let l:idx += 1
  endfor
  return -1
endfunction

function! game#story#threads#get_thread_card(cards, thread_name) abort
  let l:idx = game#story#threads#thread_card_index(a:cards, a:thread_name)
  return l:idx == -1 ? {} : a:cards[l:idx]
endfunction

function! game#story#threads#ensure_thread_card(state, thread_name) abort
  let l:next_state = deepcopy(a:state)
  let l:idx = game#story#threads#thread_card_index(l:next_state.notes.thread_cards, a:thread_name)
  if l:idx == -1
    call add(l:next_state.notes.thread_cards, game#story#threads#default_card(a:thread_name, l:next_state.stage))
  else
    let l:next_state.notes.thread_cards[l:idx] = game#story#threads#normalize_card(l:next_state.notes.thread_cards[l:idx], l:next_state.stage)
  endif
  return l:next_state
endfunction

function! game#story#threads#ensure_thread(state, thread_name) abort
  let l:next_state = game#story#threads#ensure_thread_card(a:state, a:thread_name)
  if index(get(l:next_state, 'threads', []), a:thread_name) == -1
    call add(l:next_state.threads, a:thread_name)
  endif

  let l:idx = game#story#threads#thread_card_index(l:next_state.notes.thread_cards, a:thread_name)
  let l:next_state.notes.thread_cards[l:idx].status = 'open'
  let l:next_state.notes.thread_cards[l:idx].stage = l:next_state.stage
  if get(l:next_state.scene, 'focus', 0) == 0
    let l:next_state.scene.focus = len(l:next_state.threads)
  endif
  return l:next_state
endfunction

function! game#story#threads#record_fact(state, fact) abort
  return game#story#threads#record_fact_for_thread(a:state, game#story#state#focus_label(a:state), a:fact)
endfunction

function! game#story#threads#record_fact_for_thread(state, thread_name, fact) abort
  if empty(a:fact) || empty(a:thread_name)
    return a:state
  endif

  let l:next_state = game#story#threads#ensure_thread_card(a:state, a:thread_name)
  let l:idx = game#story#threads#thread_card_index(l:next_state.notes.thread_cards, a:thread_name)
  let l:card = game#story#threads#normalize_card(l:next_state.notes.thread_cards[l:idx], l:next_state.stage)
  let l:card.stage = l:next_state.stage
  if index(l:card.facts, a:fact) == -1
    call add(l:card.facts, a:fact)
    if len(l:card.facts) > 6
      let l:card.facts = l:card.facts[-6:]
    endif
  endif
  let l:next_state.notes.thread_cards[l:idx] = l:card
  return l:next_state
endfunction

function! game#story#threads#rename_thread(state, thread_ref, new_name) abort
  let l:old_name = s:thread_name_at(a:state, a:thread_ref)
  if empty(l:old_name)
    return {'error': 'LOG_ERR: Invalid thread index.'}
  endif
  if !s:thread_name_available(a:state, l:old_name, a:new_name)
    return {'error': 'LOG_ERR: Thread name already exists in the ledger.'}
  endif

  let l:next_state = game#story#threads#ensure_thread_card(a:state, l:old_name)
  let l:next_state.threads[a:thread_ref - 1] = a:new_name
  call s:rename_quest_threads(l:next_state, l:old_name, a:new_name)
  call s:rename_card_references(l:next_state, l:old_name, a:new_name)
  let l:idx = game#story#threads#thread_card_index(l:next_state.notes.thread_cards, l:old_name)
  let l:card = game#story#threads#normalize_card(l:next_state.notes.thread_cards[l:idx], l:next_state.stage)
  if index(l:card.aliases, l:old_name) == -1
    call add(l:card.aliases, l:old_name)
  endif
  let l:card.name = a:new_name
  let l:card.stage = l:next_state.stage
  let l:next_state.notes.thread_cards[l:idx] = l:card
  let l:next_state = game#story#threads#record_fact_for_thread(l:next_state, a:new_name, 'Thread modified from ' . l:old_name . '.')
  return {'state': l:next_state, 'old_name': l:old_name, 'new_name': a:new_name}
endfunction

function! game#story#threads#split_thread(state, thread_ref, new_name) abort
  let l:old_name = s:thread_name_at(a:state, a:thread_ref)
  if empty(l:old_name)
    return {'error': 'LOG_ERR: Invalid thread index.'}
  endif
  if !s:thread_name_available(a:state, '', a:new_name)
    return {'error': 'LOG_ERR: Thread name already exists in the ledger.'}
  endif

  let l:next_state = game#story#threads#ensure_thread(a:state, a:new_name)
  let l:old_idx = game#story#threads#thread_card_index(l:next_state.notes.thread_cards, l:old_name)
  let l:old_card = game#story#threads#normalize_card(l:next_state.notes.thread_cards[l:old_idx], l:next_state.stage)
  if index(l:old_card.split_into, a:new_name) == -1
    call add(l:old_card.split_into, a:new_name)
  endif
  let l:next_state.notes.thread_cards[l:old_idx] = l:old_card
  let l:new_idx = game#story#threads#thread_card_index(l:next_state.notes.thread_cards, a:new_name)
  let l:new_card = game#story#threads#normalize_card(l:next_state.notes.thread_cards[l:new_idx], l:next_state.stage)
  let l:new_card.split_from = l:old_name
  let l:new_card.stage = l:next_state.stage
  let l:next_state.notes.thread_cards[l:new_idx] = l:new_card
  let l:next_state = game#story#threads#record_fact_for_thread(l:next_state, l:old_name, 'Thread split into ' . a:new_name . '.')
  let l:next_state = game#story#threads#record_fact_for_thread(l:next_state, a:new_name, 'Split from ' . l:old_name . ' after scene fallout.')
  return {'state': l:next_state, 'old_name': l:old_name, 'new_name': a:new_name}
endfunction

function! game#story#threads#replace_thread(state, thread_ref, new_name) abort
  let l:old_name = s:thread_name_at(a:state, a:thread_ref)
  if empty(l:old_name)
    return {'error': 'LOG_ERR: Invalid thread index.'}
  endif
  if !s:thread_name_available(a:state, '', a:new_name)
    return {'error': 'LOG_ERR: Thread name already exists in the ledger.'}
  endif

  let l:next_state = game#story#threads#ensure_thread_card(a:state, l:old_name)
  let l:next_state.threads[a:thread_ref - 1] = a:new_name
  let l:old_idx = game#story#threads#thread_card_index(l:next_state.notes.thread_cards, l:old_name)
  let l:old_card = game#story#threads#normalize_card(l:next_state.notes.thread_cards[l:old_idx], l:next_state.stage)
  let l:old_card.status = 'replaced'
  let l:old_card.replaced_by = a:new_name
  let l:next_state.notes.thread_cards[l:old_idx] = l:old_card
  let l:next_state = game#story#threads#ensure_thread_card(l:next_state, a:new_name)
  let l:new_idx = game#story#threads#thread_card_index(l:next_state.notes.thread_cards, a:new_name)
  let l:new_card = game#story#threads#normalize_card(l:next_state.notes.thread_cards[l:new_idx], l:next_state.stage)
  let l:new_card.status = 'open'
  let l:new_card.replaced_from = l:old_name
  let l:new_card.stage = l:next_state.stage
  let l:next_state.notes.thread_cards[l:new_idx] = l:new_card
  let l:next_state = game#story#threads#record_fact_for_thread(l:next_state, l:old_name, 'Thread replaced by ' . a:new_name . '.')
  let l:next_state = game#story#threads#record_fact_for_thread(l:next_state, a:new_name, 'Replaces ' . l:old_name . ' after scene fallout.')
  return {'state': l:next_state, 'old_name': l:old_name, 'new_name': a:new_name}
endfunction

function! game#story#threads#resolve_thread(state, thread_ref) abort
  let l:old_name = s:thread_name_at(a:state, a:thread_ref)
  if empty(l:old_name)
    return {'error': 'LOG_ERR: Invalid thread index.'}
  endif

  let l:next_state = game#story#threads#ensure_thread_card(a:state, l:old_name)
  call remove(l:next_state.threads, a:thread_ref - 1)
  call s:shift_focus_after_removal(l:next_state, a:thread_ref)
  let l:idx = game#story#threads#thread_card_index(l:next_state.notes.thread_cards, l:old_name)
  let l:card = game#story#threads#normalize_card(l:next_state.notes.thread_cards[l:idx], l:next_state.stage)
  let l:card.status = 'resolved'
  let l:card.stage = l:next_state.stage
  let l:next_state.notes.thread_cards[l:idx] = l:card
  let l:next_state = game#story#threads#record_fact_for_thread(l:next_state, l:old_name, 'Thread resolved and removed from the active ledger.')
  return {'state': l:next_state, 'old_name': l:old_name}
endfunction

function! s:thread_name_at(state, thread_ref) abort
  return (a:thread_ref >= 1 && a:thread_ref <= len(get(a:state, 'threads', []))) ? a:state.threads[a:thread_ref - 1] : ''
endfunction

function! s:thread_name_available(state, old_name, new_name) abort
  if empty(a:new_name)
    return 0
  endif
  let l:idx = game#story#threads#thread_card_index(get(get(a:state, 'notes', {}), 'thread_cards', []), a:new_name)
  return l:idx == -1 || a:new_name ==# a:old_name
endfunction

function! s:rename_quest_threads(state, old_name, new_name) abort
  for l:quest in get(a:state, 'quests', [])
    if get(l:quest, 'thread', '') ==# a:old_name
      let l:quest.thread = a:new_name
    endif
  endfor
endfunction

function! s:rename_card_references(state, old_name, new_name) abort
  for l:card in get(get(a:state, 'notes', {}), 'thread_cards', [])
    if get(l:card, 'split_from', '') ==# a:old_name
      let l:card.split_from = a:new_name
    endif
    if get(l:card, 'replaced_from', '') ==# a:old_name
      let l:card.replaced_from = a:new_name
    endif
    if get(l:card, 'replaced_by', '') ==# a:old_name
      let l:card.replaced_by = a:new_name
    endif
    let l:split_refs = []
    for l:thread_name in get(l:card, 'split_into', [])
      call add(l:split_refs, l:thread_name ==# a:old_name ? a:new_name : l:thread_name)
    endfor
    let l:card.split_into = l:split_refs
  endfor
endfunction

function! s:shift_focus_after_removal(state, thread_ref) abort
  let l:focus = get(get(a:state, 'scene', {}), 'focus', 1)
  if empty(get(a:state, 'threads', []))
    let a:state.scene.focus = 0
  elseif l:focus > a:thread_ref
    let a:state.scene.focus = l:focus - 1
  elseif l:focus == a:thread_ref
    let a:state.scene.focus = min([a:thread_ref, len(a:state.threads)])
  endif
endfunction
