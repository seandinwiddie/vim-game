" autoload/game/store.vim - RTK-style store helpers for Vimscript

function! game#store#create(initial_state) abort
  return {
        \ 'state': deepcopy(a:initial_state),
        \ 'previous_state': {},
        \ 'subscribers': {},
        \ 'next_subscriber_id': 1
        \ }
endfunction

function! game#store#get_state(store) abort
  return get(a:store, 'state', {})
endfunction

function! game#store#dispatch(store, action) abort
  if s:is_undo_requested(a:action) && !empty(get(a:store, 'previous_state', {}))
    let a:store.state = game#reducer#reduce(a:store.state, s:undo_action(a:store))
    let a:store.previous_state = {}
    call s:notify(a:store)
    return a:action
  endif

  if s:tracks_history(a:action)
    let a:store.previous_state = deepcopy(a:store.state)
  endif
  let a:store.state = game#reducer#reduce(a:store.state, a:action)
  call s:notify(a:store)
  return a:action
endfunction

function! game#store#dispatch_input(store, input) abort
  return game#store#dispatch(a:store, game#action#command(a:input))
endfunction

function! game#store#dispatch_batch(store, actions) abort
  if empty(a:actions)
    return []
  endif

  let l:batch_previous = deepcopy(a:store.state)
  let l:tracks_history = 0
  let l:used_undo = 0
  for l:action in a:actions
    if s:is_undo_requested(l:action) && !empty(get(a:store, 'previous_state', {}))
      let a:store.state = game#reducer#reduce(a:store.state, s:undo_action(a:store))
      let a:store.previous_state = {}
      let l:used_undo = 1
    else
      if s:tracks_history(l:action)
        let l:tracks_history = 1
      endif
      let a:store.state = game#reducer#reduce(a:store.state, l:action)
    endif
  endfor
  if l:tracks_history && !l:used_undo
    let a:store.previous_state = l:batch_previous
  endif
  call s:notify(a:store)
  return a:actions
endfunction

function! game#store#subscribe(store, callback) abort
  let l:id = get(a:store, 'next_subscriber_id', 1)
  let a:store.next_subscriber_id = l:id + 1
  let a:store.subscribers[string(l:id)] = a:callback
  return l:id
endfunction

function! game#store#unsubscribe(store, id) abort
  let l:key = string(a:id)
  if has_key(get(a:store, 'subscribers', {}), l:key)
    call remove(a:store.subscribers, l:key)
  endif
endfunction

function! s:notify(store) abort
  for l:key in sort(keys(get(a:store, 'subscribers', {})))
    call call(a:store.subscribers[l:key], [a:store.state])
  endfor
endfunction

function! s:is_undo_requested(action) abort
  return get(a:action, 'type', '') ==# 'system/undoRequested'
endfunction

function! s:tracks_history(action) abort
  return index(['system/noop', 'system/undoRequested', 'system/undo'], get(a:action, 'type', '')) == -1
endfunction

function! s:undo_action(store) abort
  return game#action#make('system/undo', {'previous_state': deepcopy(get(a:store, 'previous_state', {}))})
endfunction
