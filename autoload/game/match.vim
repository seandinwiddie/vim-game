" autoload/game/match.vim - Shared exact/unique-prefix matching

function! game#match#one(choices, query) abort
  let l:query = tolower(trim(a:query))
  if empty(l:query)
    return {'found': 0, 'ambiguous': 0, 'index': -1, 'value': '', 'matches': []}
  endif

  let l:exact = []
  let l:prefix = []
  let l:idx = 0
  for l:choice in a:choices
    let l:value = type(l:choice) == v:t_string ? l:choice : string(l:choice)
    let l:normalized = tolower(trim(l:value))
    if l:normalized ==# l:query
      call add(l:exact, {'index': l:idx, 'value': l:value})
    elseif stridx(l:normalized, l:query) == 0
      call add(l:prefix, {'index': l:idx, 'value': l:value})
    endif
    let l:idx += 1
  endfor

  let l:matches = !empty(l:exact) ? s:unique_matches(l:exact) : s:unique_matches(l:prefix)
  if len(l:matches) == 1
    return {'found': 1, 'ambiguous': 0, 'index': l:matches[0].index, 'value': l:matches[0].value, 'matches': [l:matches[0].value]}
  endif

  return {'found': 0, 'ambiguous': len(l:matches) > 1, 'index': -1, 'value': '', 'matches': map(copy(l:matches), 'v:val.value')}
endfunction

function! s:unique_matches(candidates) abort
  let l:seen = {}
  let l:unique = []
  for l:candidate in a:candidates
    let l:key = tolower(l:candidate.value)
    if !has_key(l:seen, l:key)
      let l:seen[l:key] = 1
      call add(l:unique, l:candidate)
    endif
  endfor
  return l:unique
endfunction
