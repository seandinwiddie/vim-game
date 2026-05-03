" autoload/game/rng.vim - Seeded RNG helpers

function! game#rng#default_seed() abort
  return 424242
endfunction

function! game#rng#hydrate(state) abort
  let l:next_state = deepcopy(a:state)
  let l:next_state.rng_seed = s:normalize_seed(get(l:next_state, 'rng_seed', game#rng#default_seed()))
  return l:next_state
endfunction

function! game#rng#next(state) abort
  let l:seed = s:normalize_seed(get(a:state, 'rng_seed', game#rng#default_seed()))
  let l:next_seed = (l:seed * 48271) % 2147483647
  let l:next_state = copy(a:state)
  let l:next_state.rng_seed = l:next_seed
  return {'state': l:next_state, 'value': l:next_seed}
endfunction

function! game#rng#draw(state, sides) abort
  let l:result = game#rng#next(a:state)
  let l:max = a:sides > 0 ? a:sides : 1
  return {'state': l:result.state, 'value': (l:result.value % l:max) + 1}
endfunction

function! s:normalize_seed(seed) abort
  let l:seed = type(a:seed) == v:t_number ? a:seed : game#rng#default_seed()
  let l:seed = l:seed % 2147483647
  return l:seed > 0 ? l:seed : game#rng#default_seed()
endfunction
