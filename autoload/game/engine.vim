" autoload/game/engine.vim - Side Effect Layer

function! game#engine#start() abort
  let l:state = game#core#init()
  call b:set_up_buffer()
  call s:draw(l:state)
endfunction

function! b:set_up_buffer() abort
  enew
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nonumber
  setlocal norelativenumber
  setlocal cursorline
  setlocal nomodifiable
  file VIM_QUEST
  
  nnoremap <buffer> <silent> <nowait> <Space> :call <SID>on_start_press()<CR>
  nnoremap <buffer> <silent> <nowait> q :bwipe!<CR>
endfunction

function! s:on_start_press() abort
  echo "Game start logic goes here!"
endfunction

function! s:draw(state) abort
  let l:lines = game#core#render(a:state)
  setlocal modifiable
  silent 1,$delete _
  call setline(1, l:lines)
  setlocal nomodifiable
endfunction
