" autoload/game/story/meeting.vim - Meeting of Minds bookkeeping

function! game#story#meeting#cmd_meeting(state, subcmd, args) abort
  let l:subcmd = empty(a:subcmd) ? 'show' : a:subcmd

  if index(['show', 'list', 'status'], l:subcmd) != -1
    let l:next_state = deepcopy(a:state)
    let l:next_state.hint = 'DIRECTIVE: Keep the social contract visible while you choose threats, fallout, and scene pressure.'
    return game#core#add_log(l:next_state, game#story#meeting#lines(l:next_state))
  elseif l:subcmd ==# 'focus'
    return s:add_entry(a:state, 'focuses', a:args, 'focus theme', 'Accord focus updated. Build scenes toward the chosen themes.')
  elseif l:subcmd ==# 'ban' || l:subcmd ==# 'banned'
    return s:add_entry(a:state, 'banned', a:args, 'banned theme', 'Accord boundary updated. Steer away from the banned material.')
  elseif l:subcmd ==# 'note' || l:subcmd ==# 'assume' || l:subcmd ==# 'assumption'
    return s:add_entry(a:state, 'assumptions', a:args, 'assumption', 'Accord note updated. Let this shape consequences and concessions.')
  elseif l:subcmd ==# 'rm' || l:subcmd ==# 'del'
    return s:remove_entry(a:state, a:args)
  endif

  return game#core#add_log(a:state, 'LOG_ERR: Minds command supports show, focus, ban, note, and rm.')
endfunction

function! game#story#meeting#summary(state) abort
  let l:meeting = get(a:state, 'meeting', {})
  return 'Accord: ' . len(get(l:meeting, 'focuses', [])) . ' focus / ' . len(get(l:meeting, 'banned', [])) . ' banned / ' . len(get(l:meeting, 'assumptions', [])) . ' assumptions'
endfunction

function! game#story#meeting#lines(state) abort
  let l:meeting = get(a:state, 'meeting', {})
  return [
        \ '--- MEETING OF MINDS ---',
        \ game#story#meeting#summary(a:state),
        \ 'Focus Themes: ' . s:format_list(get(l:meeting, 'focuses', [])),
        \ 'Banned Themes: ' . s:format_list(get(l:meeting, 'banned', [])),
        \ 'Assumptions: ' . s:format_list(get(l:meeting, 'assumptions', [])),
        \ '-------------------------'
        \ ]
endfunction

function! s:add_entry(state, list_name, args, label, hint_text) abort
  if empty(a:args)
    return game#core#add_log(a:state, 'LOG_ERR: Use "minds ' . s:list_command(a:list_name) . ' [text]" to record a ' . a:label . '.')
  endif

  let l:next_state = deepcopy(a:state)
  if index(l:next_state.meeting[a:list_name], a:args) == -1
    call add(l:next_state.meeting[a:list_name], a:args)
  endif
  let l:next_state.hint = 'DIRECTIVE: ' . a:hint_text
  return game#core#add_log(l:next_state, [
        \ 'MEETING OF MINDS: Added ' . a:label . '.',
        \ 'ENTRY: ' . a:args
        \ ])
endfunction

function! s:remove_entry(state, args) abort
  let l:parts = split(trim(a:args))
  if len(l:parts) != 2
    return game#core#add_log(a:state, 'LOG_ERR: Use "minds rm [focus|ban|note] [idx]" to remove an accord entry.')
  endif

  let l:list_name = s:list_name(l:parts[0])
  let l:idx = str2nr(l:parts[1])
  if empty(l:list_name)
    return game#core#add_log(a:state, 'LOG_ERR: Minds rm category must be focus, ban, or note.')
  endif

  let l:entries = get(get(a:state, 'meeting', {}), l:list_name, [])
  if l:idx < 1 || l:idx > len(l:entries)
    return game#core#add_log(a:state, 'LOG_ERR: Invalid Meeting of Minds entry index.')
  endif

  let l:next_state = deepcopy(a:state)
  let l:removed = remove(l:next_state.meeting[l:list_name], l:idx - 1)
  let l:next_state.hint = 'DIRECTIVE: Accord trimmed. Keep the current run inside the remaining boundaries.'
  return game#core#add_log(l:next_state, [
        \ 'MEETING OF MINDS: Removed ' . s:list_command(l:list_name) . ' entry.',
        \ 'ENTRY: ' . l:removed
        \ ])
endfunction

function! s:list_name(raw_name) abort
  if a:raw_name ==# 'focus'
    return 'focuses'
  elseif a:raw_name ==# 'ban' || a:raw_name ==# 'banned'
    return 'banned'
  elseif a:raw_name ==# 'note' || a:raw_name ==# 'assume' || a:raw_name ==# 'assumption'
    return 'assumptions'
  endif
  return ''
endfunction

function! s:list_command(list_name) abort
  if a:list_name ==# 'focuses'
    return 'focus'
  elseif a:list_name ==# 'banned'
    return 'ban'
  endif
  return 'note'
endfunction

function! s:format_list(entries) abort
  return empty(a:entries) ? 'none' : join(a:entries, ' | ')
endfunction
