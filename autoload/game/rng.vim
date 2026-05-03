" autoload/game/rng.vim - Non-deterministic RNG helpers

function! game#rng#default_seed() abort
  return 0
endfunction

function! game#rng#hydrate(state) abort
  let l:next_state = deepcopy(a:state)
  let l:next_state.rng_seed = 0
  return l:next_state
endfunction

function! game#rng#next(state) abort
  let l:next_state = a:state
  let l:val = s:random_val()
  let l:next_state.rng_seed = l:val
  return {'state': l:next_state, 'value': l:val}
endfunction

function! game#rng#draw(state, sides) abort
  let l:result = game#rng#next(a:state)
  let l:max = a:sides > 0 ? a:sides : 1
  return {'state': l:result.state, 'value': (l:result.value % l:max) + 1}
endfunction

function! s:random_val() abort
  let l:time = reltimestr(reltime())
  let l:parts = split(l:time, '\.')
  if len(l:parts) < 2
    return 42
  endif
  return str2nr(l:parts[1])
endfunction
