" autoload/game/core.vim - Functional Core

" Pure: returns initial state
function! game#core#init() abort
  return {'view': 'title', 'frame': 0, 'width': 40, 'height': 15}
endfunction

" Pure: maps state to a list of strings (lines)
function! game#core#render(state) abort
  if a:state.view ==# 'title'
    return s:render_title(a:state)
  endif
  return ['Unknown view']
endfunction

function! s:render_title(state) abort
  let l:lines = repeat([''], a:state.height)
  
  " Center title text
  let l:title = "== VIM QUEST =="
  let l:hint = "(press SPACE to start)"
  
  let l:mid_y = a:state.height / 2
  let l:mid_x = a:state.width / 2
  
  let l:lines[l:mid_y - 1] = s:center(l:title, a:state.width)
  let l:lines[l:mid_y + 1] = s:center(l:hint, a:state.width)
  
  return l:lines
endfunction

function! s:center(text, width) abort
  let l:pad = (a:width - len(a:text)) / 2
  return repeat(' ', l:pad) . a:text
endfunction
