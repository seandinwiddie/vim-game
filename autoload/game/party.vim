" autoload/game/party.vim - Party bookkeeping and Tapestry-inspired scene presence

function! game#party#hydrate(state) abort
  let l:next_state = a:state
  if !has_key(l:next_state, 'player')
    let l:next_state.player = {}
  endif
  if !has_key(l:next_state.player, 'companions')
    let l:next_state.player.companions = []
  endif

  let l:idx = 0
  while l:idx < len(l:next_state.player.companions)
    let l:next_state.player.companions[l:idx] = s:normalize_companion(l:next_state.player.companions[l:idx])
    let l:idx += 1
  endwhile
  return l:next_state
endfunction

function! game#party#create(name, str, agi, arc) abort
  return s:normalize_companion({'name': a:name, 'str': a:str, 'agi': a:agi, 'arc': a:arc})
endfunction

function! game#party#add_companion(state, companion) abort
  let l:next_state = game#party#hydrate(a:state)
  if get(s:companion_match(get(l:next_state.player, 'companions', []), get(a:companion, 'name', '')), 'found', 0)
    return l:next_state
  endif
  call add(l:next_state.player.companions, s:normalize_companion(a:companion))
  return l:next_state
endfunction

function! game#party#group_bonus(state) abort
  let l:group_score = 0
  for l:companion in get(get(a:state, 'player', {}), 'companions', [])
    if get(l:companion, 'status', 'active') ==# 'active'
      let l:group_score += float2nr(ceil((get(l:companion, 'str', 4) + get(l:companion, 'agi', 4) + get(l:companion, 'arc', 4)) / 6.0))
    endif
  endfor
  return l:group_score
endfunction

function! game#party#status_label(state) abort
  let l:counts = s:status_counts(a:state)
  return 'Party: ' . l:counts.active . ' active / ' . l:counts.faded . ' faded / ' . l:counts.elsewhere . ' elsewhere | Group: +' . game#party#group_bonus(a:state)
endfunction

function! game#party#sync_scene(state) abort
  let l:next_state = a:state
  for l:companion in get(get(a:state, 'player', {}), 'companions', [])
    if get(l:companion, 'status', 'active') ==# 'active'
      let l:next_state = game#story#records#assign_scene_npc(l:next_state, l:next_state.loc, l:companion.name)
    endif
  endfor
  return l:next_state
endfunction

function! game#party#cmd_party(state, subcmd, args) abort
  let l:subcmd = empty(a:subcmd) ? 'show' : a:subcmd

  if l:subcmd ==# 'show' || l:subcmd ==# 'list' || l:subcmd ==# 'status'
    let l:next_state = game#party#hydrate(a:state)
    let l:next_state.hint = 'DIRECTIVE: Keep only the right companions in the main scene; fade or send the rest elsewhere.'
    return game#core#add_log(l:next_state, s:party_lines(l:next_state))
  elseif l:subcmd ==# 'fade'
    return s:set_status(a:state, a:args, 'faded', '')
  elseif l:subcmd ==# 'rally' || l:subcmd ==# 'join'
    return s:set_status(a:state, a:args, 'active', '')
  elseif l:subcmd ==# 'send' || l:subcmd ==# 'elsewhere'
    let l:parsed = s:parse_send_args(a:args)
    return s:set_elsewhere(a:state, l:parsed.name, l:parsed.thread_ref)
  endif

  return game#core#add_log(a:state, 'LOG_ERR: Party command supports show, fade, rally, and send.')
endfunction

function! s:party_lines(state) abort
  let l:lines = ['--- PARTY TACTICS ---', game#party#status_label(a:state)]
  let l:companions = get(get(a:state, 'player', {}), 'companions', [])
  if empty(l:companions)
    call add(l:lines, ' * none')
  else
    for l:companion in l:companions
      let l:line = ' * ' . l:companion.name . ' [' . toupper(get(l:companion, 'status', 'active')) . ']'
      if get(l:companion, 'status', 'active') ==# 'elsewhere' && !empty(get(l:companion, 'assignment', ''))
        let l:line .= ' | thread: ' . l:companion.assignment
      elseif get(l:companion, 'status', 'active') ==# 'faded'
        let l:line .= ' | holding back from the main scene'
      else
        let l:line .= ' | present in the main scene'
      endif
      call add(l:lines, l:line)
    endfor
  endif
  call add(l:lines, '---------------------')
  return l:lines
endfunction

function! s:set_status(state, name, status, assignment) abort
  let l:next_state = game#party#hydrate(a:state)
  let l:match = s:companion_match(get(l:next_state.player, 'companions', []), a:name)
  if get(l:match, 'ambiguous', 0)
    return game#core#add_log(a:state, 'LOG_ERR: Companion reference "' . a:name . '" matches multiple companions: ' . join(l:match.matches, ', ') . '.')
  endif
  if !get(l:match, 'found', 0)
    return game#core#add_log(a:state, 'LOG_ERR: Unknown companion "' . a:name . '".')
  endif
  let l:idx = l:match.index
 
  let l:companion = l:next_state.player.companions[l:idx]
  let l:next_state.player.companions[l:idx].status = a:status
  let l:next_state.player.companions[l:idx].assignment = a:assignment

  if a:status ==# 'active'
    let l:next_state = game#story#records#assign_scene_npc(l:next_state, l:next_state.loc, l:companion.name)
    let l:next_state.hint = 'DIRECTIVE: Companion rallied into the main scene.'
    let l:next_state = game#story#record_fact(l:next_state, 'general', l:companion.name . ' rallied back into the main scene.')
    return game#core#add_log(l:next_state, [
          \ 'PARTY UPDATE: ' . l:companion.name . ' rallies to the front.',
          \ 'GROUP DYNAMICS: +' . game#party#group_bonus(l:next_state)
          \ ])
  endif

  let l:next_state = game#story#records#remove_scene_npc(l:next_state, l:next_state.loc, l:companion.name)
  let l:next_state.hint = a:status ==# 'faded'
        \ ? 'DIRECTIVE: Companion faded from the scene so others can react.'
        \ : 'DIRECTIVE: Companion reassigned away from the main scene.'
  let l:note = a:status ==# 'faded'
        \ ? l:companion.name . ' faded from the main scene.'
        \ : l:companion.name . ' peeled away from the main scene to operate elsewhere.'
  let l:next_state = game#story#record_fact(l:next_state, 'general', l:note)
  return game#core#add_log(l:next_state, [
        \ 'PARTY UPDATE: ' . l:companion.name . (a:status ==# 'faded' ? ' fades to the edge of the scene.' : ' breaks away from the scene to handle a sidebar thread.'),
        \ 'GROUP DYNAMICS: +' . game#party#group_bonus(l:next_state)
        \ ])
endfunction

function! s:set_elsewhere(state, name, thread_ref) abort
  let l:threads = get(a:state, 'threads', [])
  let l:idx = str2nr(a:thread_ref)
  if l:idx < 1 || l:idx > len(l:threads)
    return game#core#add_log(a:state, 'LOG_ERR: Invalid thread index for elsewhere party assignment.')
  endif

  let l:thread_name = l:threads[l:idx - 1]
  let l:next_state = s:set_status(a:state, a:name, 'elsewhere', l:thread_name)
  if get(l:next_state, 'log', [])[-1] =~# '^LOG_ERR:'
    return l:next_state
  endif
  let l:companion_name = s:resolved_name(l:next_state, a:name)
  let l:next_state.hint = 'DIRECTIVE: Companion is handling a sidebar thread elsewhere.'
  let l:next_state = game#story#record_fact_for_thread(l:next_state, l:thread_name, 'elsewhere', l:companion_name . ' is operating elsewhere while the main scene continues.')
  return game#core#add_log(l:next_state, [
        \ 'ELSEWHERE UNIT: ' . l:companion_name,
        \ 'THREAD SUPPORT: ' . l:thread_name
        \ ])
endfunction

function! s:normalize_companion(companion) abort
  let l:companion = deepcopy(a:companion)
  if !has_key(l:companion, 'status')
    let l:companion.status = 'active'
  endif
  if !has_key(l:companion, 'assignment')
    let l:companion.assignment = ''
  endif
  return l:companion
endfunction

function! s:companion_match(companions, name) abort
  let l:match = game#match#one(map(copy(a:companions), "get(v:val, 'name', '')"), a:name)
  let l:match.companion = get(l:match, 'found', 0) ? a:companions[l:match.index] : {}
  return l:match
endfunction

function! s:parse_send_args(args) abort
  let l:parts = split(trim(a:args))
  if len(l:parts) < 2
    return {'name': '', 'thread_ref': ''}
  endif
  return {'name': join(l:parts[0 : len(l:parts) - 2], ' '), 'thread_ref': l:parts[-1]}
endfunction

function! s:resolved_name(state, name) abort
  let l:match = s:companion_match(get(get(a:state, 'player', {}), 'companions', []), a:name)
  return get(l:match, 'found', 0) ? l:match.value : a:name
endfunction

function! s:status_counts(state) abort
  let l:counts = {'active': 0, 'faded': 0, 'elsewhere': 0}
  for l:companion in get(get(a:state, 'player', {}), 'companions', [])
    let l:status = get(l:companion, 'status', 'active')
    if !has_key(l:counts, l:status)
      let l:counts[l:status] = 0
    endif
    let l:counts[l:status] += 1
  endfor
  return l:counts
endfunction
