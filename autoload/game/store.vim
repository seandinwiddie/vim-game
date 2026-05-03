" autoload/game/store.vim - RTK-style store helpers for Vimscript

function! game#store#create(initial_state) abort
  return {
        \ 'state': deepcopy(a:initial_state),
        \ 'subscribers': {},
        \ 'next_subscriber_id': 1
        \ }
endfunction

function! game#store#get_state(store) abort
  return get(a:store, 'state', {})
endfunction

function! game#store#dispatch(store, action) abort
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

  for l:action in a:actions
    let a:store.state = game#reducer#reduce(a:store.state, l:action)
  endfor
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
