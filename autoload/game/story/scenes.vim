" autoload/game/story/scenes.vim - Scene Review, Fade Out, and Elsewhere

function! game#story#scenes#cmd_scene(state) abort
  let l:next_state = deepcopy(a:state)
  let l:next_state.hint = 'DIRECTIVE: Review the current scene card before pushing to the next scene.'
  let l:card = game#story#records#get_scene_card(l:next_state.notes.scene_cards, l:next_state.loc)
  let l:framework_chapter = empty(l:card) ? get(get(l:next_state, 'framework', {}), 'chapter', 1) : get(l:card, 'framework_chapter', get(get(l:next_state, 'framework', {}), 'chapter', 1))
  let l:framework_phase = empty(l:card) ? get(get(l:next_state, 'framework', {}), 'phase', 'exposition') : get(l:card, 'framework_phase', get(get(l:next_state, 'framework', {}), 'phase', 'exposition'))
  let l:lines = [
        \ '--- SCENE CARD ---',
        \ 'Scene #' . get(l:next_state.scene, 'index', 1) . ': ' . game#story#state#scene_label(l:next_state),
        \ 'Focus: ' . game#story#state#focus_label(l:next_state),
        \ 'Stage: TO ' . toupper(l:next_state.stage),
        \ 'Framework: CH' . l:framework_chapter . ' ' . game#story#framework#phase_name_label(l:framework_phase)
        \ ]

  if empty(l:card)
    call add(l:lines, 'Visits: 0')
    call add(l:lines, 'Closings: none')
  else
    call add(l:lines, 'Visits: ' . get(l:card, 'visits', 0))
    call add(l:lines, 'Openings:')
    if empty(get(l:card, 'openings', []))
      call add(l:lines, ' - none')
    else
      for l:opening in l:card.openings
        call add(l:lines, ' - ' . l:opening)
      endfor
    endif
    call add(l:lines, 'Closings:')
    if empty(get(l:card, 'closings', []))
      call add(l:lines, ' - none')
    else
      for l:closing in l:card.closings
        call add(l:lines, ' - ' . l:closing)
      endfor
    endif
    call add(l:lines, 'NPCs: ' . (empty(get(l:card, 'npcs', [])) ? 'none' : join(l:card.npcs, ', ')))
  endif

  call add(l:lines, '------------------')
  return game#core#add_log(l:next_state, l:lines)
endfunction

function! game#story#scenes#cmd_fade(state, summary) abort
  let l:next_state = deepcopy(a:state)
  let l:next_state = game#story#records#append_scene_closing(l:next_state, l:next_state.loc, a:summary)
  let l:next_state = game#story#threads#record_fact(l:next_state, 'Fade Out: ' . a:summary)
  let l:next_state.hint = 'DIRECTIVE: Scene closed. Use thread mod/split/replace, then advance the framework when the next act is earned.'

  return game#core#add_log(l:next_state, [
        \ 'FADE OUT: ' . a:summary,
        \ 'BOOKKEEPING: Review thread changes, new facts, and scene fallout before the next transition.'
        \ ])
endfunction

function! game#story#scenes#cmd_montage(state, summary) abort
  let l:next_state = deepcopy(a:state)
  let l:next_state = game#story#records#append_scene_closing(l:next_state, l:next_state.loc, 'MONTAGE: ' . a:summary)
  let l:next_state = game#story#threads#record_fact(l:next_state, 'Montage: ' . a:summary)
  for l:thread in get(l:next_state, 'threads', [])
    let l:next_state = game#story#threads#record_fact_for_thread(l:next_state, l:thread, 'Montage carry: ' . a:summary)
  endfor
  let l:next_state.scene.index = get(l:next_state.scene, 'index', 1) + 1
  let l:next_state.surge = 0
  let l:next_state.hint = 'DIRECTIVE: Montage advances the scene index and resets Surge. Choose the next stage when the action settles.'
  return game#core#add_log(l:next_state, [
        \ 'MONTAGE: ' . a:summary,
        \ 'TIMEFRAME_SHIFT: Multiple threads carry the action forward; new scene index = ' . l:next_state.scene.index . '.',
        \ 'SURGE_RESET: The Loom of Fate exhales between acts.'
        \ ])
endfunction

function! game#story#scenes#cmd_aside(state, thread_ref, fact) abort
  let l:threads = get(a:state, 'threads', [])
  let l:idx = str2nr(a:thread_ref)
  if l:idx < 1 || l:idx > len(l:threads)
    return game#core#add_log(a:state, 'LOG_ERR: Invalid thread index for elsewhere scene.')
  endif

  let l:thread_name = l:threads[l:idx - 1]
  let l:next_state = deepcopy(a:state)
  let l:next_state = game#story#threads#record_fact_for_thread(l:next_state, l:thread_name, 'Elsewhere: ' . a:fact)
  let l:next_state.hint = 'DIRECTIVE: Elsewhere fact recorded without disrupting the active scene.'

  return game#core#add_log(l:next_state, [
        \ 'ELSEWHERE: ' . l:thread_name,
        \ 'SIDEBAR FACT: ' . a:fact
        \ ])
endfunction
