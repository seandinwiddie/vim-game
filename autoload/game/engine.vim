" autoload/game/engine.vim - Quadar MUD Engine

let s:state = {}

function! game#engine#start() abort
  let s:state = game#core#init()
  call s:set_up_buffer()
  call s:draw()
endfunction

function! s:set_up_buffer() abort
  enew
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nonumber
  setlocal norelativenumber
  setlocal nocursorline
  setlocal nomodifiable
  setlocal wrap
  setlocal filetype=mud
  file QUA_DAR_MUD
  
  " UI Mappings
  nnoremap <buffer> <silent> <nowait> : :call <SID>prompt_cmd()<CR>
  nnoremap <buffer> <silent> <nowait> i :call <SID>prompt_cmd()<CR>
  nnoremap <buffer> <silent> <nowait> q :bwipe!<CR>
  
  " Quick game commands
  nnoremap <buffer> <silent> l :call <SID>run('look')<CR>
  nnoremap <buffer> <silent> n :call <SID>run('go north')<CR>
  nnoremap <buffer> <silent> s :call <SID>run('go south')<CR>
  nnoremap <buffer> <silent> e :call <SID>run('go east')<CR>
  nnoremap <buffer> <silent> w :call <SID>run('go west')<CR>
  
  echo "Press 'i' or ':' to type a command. 'q' to quit."
endfunction

function! s:prompt_cmd() abort
  let l:input = input('Command > ')
  if !empty(l:input)
    call s:run(l:input)
  endif
endfunction

function! s:run(input) abort
  let s:state = game#core#process(s:state, a:input)
  call s:draw()
endfunction

function! s:draw() abort
  let l:lines = game#core#render(s:state)
  if empty(l:lines)
    let l:lines = ['DEBUG: No lines returned from render()']
  endif

  setlocal modifiable
  silent %delete _
  call setline(1, l:lines)
  setlocal nomodifiable
  normal! G
  redraw!
endfunction
