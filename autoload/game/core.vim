" autoload/game/core.vim - Quadar Micro-MUD Functional Core

" === PURE LOGIC: INITIAL STATE ===
function! game#core#init() abort
  let l:s = game#state#bootstrap()
  let l:s = game#story#record_scene(l:s, l:s.loc)
  let l:s = game#story#record_fact_for_thread(l:s, 'Find Missing Rangers', 'general', 'Kamenal begins in the Merchandise Store Room under orders to recover missing rangers.')
  return game#core#add_log(l:s, ['NEURAL_LINK_ESTABLISHED', 'SYSTEM_OVERRIDE: INITIATING RECONNAISSANCE PROTOCOL ᚠ', 'You materialize in the Merchandise Store Room.'])
endfunction

" === PURE LOGIC: COMMAND PROCESSING ===

function! game#core#process(state, input) abort
  return game#reducer#reduce(a:state, game#action#command(a:input))
endfunction

" === INTERNAL PURE HELPERS ===

function! game#core#cmd_help(state) abort
  let l:next_state = a:state
  let l:next_state.hint = 'DIRECTIVE: Use "help" any time to review the command surface.'
  return game#core#add_log(l:next_state, game#action#help_lines())
endfunction

function! game#core#add_log(state, msg) abort
  let l:next_state = a:state
  let l:next_state.log_cursor = s:log_cursor(a:state)
  if type(a:msg) == v:t_list
    let l:next_state.log += a:msg
  else
    let l:next_state.log += [a:msg]
  endif
  if len(l:next_state.log) > 100
    let l:overflow = len(l:next_state.log) - 100
    call remove(l:next_state.log, 0, l:overflow - 1)
    let l:next_state.log_cursor = max([0, l:next_state.log_cursor - l:overflow])
  endif
  return l:next_state
endfunction

function! game#core#header(state) abort
  let l:state = game#core#normalize(a:state)
  let l:header = [
        \ "ᚠ ᛫ ᛟ ᛫ ᚱ ᛫ ᛒ ᛫ ᛟ ᛫ ᚲ",
        \ "== QUA'DAR NEURAL LINK ==",
        \ "Stage: TO " . toupper(l:state.stage) . " | Surge Count: " . l:state.surge,
        \ "Scene #" . get(l:state.scene, 'index', 1) . ": " . game#story#scene_label(l:state),
        \ game#story#framework_summary(l:state),
        \ game#story#meeting_summary(l:state),
        \ "Focus: " . game#story#focus_label(l:state),
        \ game#story#quest_summary(l:state),
        \ game#story#notes_summary(l:state),
        \ game#party#status_label(l:state),
        \ game#economy#status_label(l:state),
        \ l:state.hint,
        \ "--- ACTIVE THREADS ---"
        \ ]
  let l:idx = 1
  for l:th in l:state.threads
    call add(l:header, l:idx . ". " . l:th)
    let l:idx += 1
  endfor
  call add(l:header, "")
  return l:header
endfunction

function! game#core#mark_rendered(state) abort
  let l:next_state = a:state
  let l:next_state.log_cursor = len(get(a:state, 'log', []))
  return l:next_state
endfunction

function! game#core#reset_render_cursor(state) abort
  let l:next_state = a:state
  let l:next_state.log_cursor = 0
  return l:next_state
endfunction

function! game#core#render(state) abort
  let l:state = game#core#normalize(a:state)
  let l:cursor = s:log_cursor(l:state)
  let l:unread = copy(l:state.log)
  if l:cursor > 0 && !empty(l:unread)
    call remove(l:unread, 0, l:cursor - 1)
  endif
  let l:header = game#core#header(l:state)
  return l:header + l:unread
endfunction

function! s:log_cursor(state) abort
  return min([max([get(a:state, 'log_cursor', 0), 0]), len(get(a:state, 'log', []))])
endfunction

function! game#core#normalize(state) abort
  return game#state#hydrate(a:state)
endfunction
