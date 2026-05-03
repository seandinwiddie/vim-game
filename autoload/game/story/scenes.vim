" autoload/game/story/scenes.vim - Scene Review, Fade Out, and Elsewhere

function! game#story#scenes#cmd_scene(state) abort
  let l:next_state = deepcopy(a:state)
  let l:next_state.hint = 'DIRECTIVE: Review the current scene card before pushing to the next scene.'
  let l:card = game#story#records#get_scene_card(l:next_state.notes.scene_cards, l:next_state.loc)
  let l:lines = [
        \ '--- SCENE CARD ---',
        \ 'Scene #' . get(l:next_state.scene, 'index', 1) . ': ' . game#story#state#scene_label(l:next_state),
        \ 'Focus: ' . game#story#state#focus_label(l:next_state),
        \ 'Stage: TO ' . toupper(l:next_state.stage)
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
  if empty(a:summary)
    return game#core#add_log(a:state, 'LOG_ERR: Use "fade [summary]" to close the current scene with an effect summary.')
  endif

  let l:next_state = deepcopy(a:state)
  let l:next_state = game#story#records#append_scene_closing(l:next_state, l:next_state.loc, a:summary)
  let l:next_state = game#story#records#record_fact(l:next_state, 'Fade Out: ' . a:summary)
  let l:next_state.hint = 'DIRECTIVE: Scene closed. Re-evaluate focus, stage, and next location before moving on.'

  return game#core#add_log(l:next_state, [
        \ 'FADE OUT: ' . a:summary,
        \ 'BOOKKEEPING: Review thread changes, new facts, and scene fallout before the next transition.'
        \ ])
endfunction

function! game#story#scenes#cmd_aside(state, thread_ref, fact) abort
  if empty(a:thread_ref) || empty(a:fact)
    return game#core#add_log(a:state, 'LOG_ERR: Use "aside [thread#] [fact]" to record an elsewhere sidebar fact.')
  endif

  let l:threads = get(a:state, 'threads', [])
  let l:idx = str2nr(a:thread_ref)
  if l:idx < 1 || l:idx > len(l:threads)
    return game#core#add_log(a:state, 'LOG_ERR: Invalid thread index for elsewhere scene.')
  endif

  let l:thread_name = l:threads[l:idx - 1]
  let l:next_state = deepcopy(a:state)
  let l:next_state = game#story#records#record_fact_for_thread(l:next_state, l:thread_name, 'Elsewhere: ' . a:fact)
  let l:next_state.hint = 'DIRECTIVE: Elsewhere fact recorded without disrupting the active scene.'

  return game#core#add_log(l:next_state, [
        \ 'ELSEWHERE: ' . l:thread_name,
        \ 'SIDEBAR FACT: ' . a:fact
        \ ])
endfunction
