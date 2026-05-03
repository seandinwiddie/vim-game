" autoload/game/story/framework.vim - Vignette framework and hook commands

function! game#story#framework#cmd_framework(state, subcmd, args) abort
  let l:subcmd = empty(a:subcmd) ? 'show' : a:subcmd

  if l:subcmd ==# 'show' || l:subcmd ==# 'list' || l:subcmd ==# 'status'
    let l:next_state = deepcopy(a:state)
    let l:next_state.hint = 'DIRECTIVE: Keep the vignette hook in mind while you frame the next scene.'
    return game#core#add_log(l:next_state, s:framework_lines(l:next_state))
  elseif l:subcmd ==# 'theme'
    let l:next_state = deepcopy(a:state)
    let l:next_state.framework.theme = a:args
    let l:next_state.hint = 'DIRECTIVE: Framework theme set. Frame scenes that drive this subject toward closure.'
    let l:next_state = game#story#record_fact(l:next_state, 'Framework theme fixed on ' . a:args . '.')
    return game#core#add_log(l:next_state, ['FRAMEWORK THEME: ' . a:args])
  elseif l:subcmd ==# 'hook'
    let l:next_state = deepcopy(a:state)
    let l:next_state.framework.hook = a:args
    let l:next_state.hint = 'DIRECTIVE: Hook stored. Let it tug the next scene without turning it into rails.'
    let l:next_state = game#story#record_fact(l:next_state, 'Framework hook established: ' . a:args . '.')
    return game#core#add_log(l:next_state, ['FRAMEWORK HOOK: ' . a:args])
  elseif l:subcmd ==# 'phase'
    let l:phase = s:normalize_phase(a:args)
    if empty(l:phase)
      return game#core#add_log(a:state, 'LOG_ERR: Framework phase must be exposition, rising, climax, or epilogue.')
    endif
    let l:next_state = deepcopy(a:state)
    let l:next_state.framework.phase = l:phase
    let l:next_state.hint = 'DIRECTIVE: Arc phase updated. Let the next scene match the dramatic pressure.'
    let l:next_state = game#story#record_fact(l:next_state, 'Framework phase shifted to ' . s:phase_label(l:phase) . ' in chapter ' . l:next_state.framework.chapter . '.')
    return game#core#add_log(l:next_state, ['FRAMEWORK PHASE: ' . s:phase_label(l:phase)])
  elseif l:subcmd ==# 'next'
    let l:next_state = deepcopy(a:state)
    let l:current = get(l:next_state.framework, 'phase', 'exposition')
    let l:next_phase = s:next_phase(l:current)
    if l:current ==# 'epilogue'
      let l:next_state.framework.chapter += 1
    endif
    let l:next_state.framework.phase = l:next_phase
    let l:next_state.hint = 'DIRECTIVE: Advance the framework only when the current scene has earned the next act.'
    let l:next_state = game#story#record_fact(l:next_state, 'Framework advanced to ' . s:phase_label(l:next_phase) . ' in chapter ' . l:next_state.framework.chapter . '.')
    return game#core#add_log(l:next_state, [
          \ 'FRAMEWORK ADVANCE: ' . s:phase_label(l:current) . ' -> ' . s:phase_label(l:next_phase),
          \ 'CHAPTER: ' . l:next_state.framework.chapter
          \ ])
  endif

  return game#core#add_log(a:state, 'LOG_ERR: Framework command supports show, theme, hook, phase, or next.')
endfunction

function! game#story#framework#summary(state) abort
  let l:framework = get(a:state, 'framework', {})
  return 'Arc: CH' . get(l:framework, 'chapter', 1) . ' ' . s:phase_label(get(l:framework, 'phase', 'exposition'))
endfunction

function! game#story#framework#phase_label(state) abort
  return s:phase_label(get(get(a:state, 'framework', {}), 'phase', 'exposition'))
endfunction

function! game#story#framework#phase_name_label(phase_name) abort
  return s:phase_label(a:phase_name)
endfunction

function! s:framework_lines(state) abort
  let l:framework = get(a:state, 'framework', {})
  return [
        \ '--- VIGNETTE FRAMEWORK ---',
        \ 'Framework: ' . get(l:framework, 'name', 'Vignette'),
        \ 'Chapter: ' . get(l:framework, 'chapter', 1),
        \ 'Phase: ' . s:phase_label(get(l:framework, 'phase', 'exposition')),
        \ 'Theme: ' . get(l:framework, 'theme', 'none'),
        \ 'Hook: ' . get(l:framework, 'hook', 'none'),
        \ 'Focus: ' . game#story#state#focus_label(a:state),
        \ 'Guidance: ' . s:guidance(get(l:framework, 'phase', 'exposition')),
        \ '---------------------------'
        \ ]
endfunction

function! s:normalize_phase(phase_name) abort
  let l:phase = substitute(trim(tolower(a:phase_name)), '[-_]', ' ', 'g')
  if l:phase ==# 'exposition'
    return 'exposition'
  elseif l:phase ==# 'rising' || l:phase ==# 'rising action'
    return 'rising'
  elseif l:phase ==# 'climax'
    return 'climax'
  elseif l:phase ==# 'epilogue'
    return 'epilogue'
  endif
  return ''
endfunction

function! s:next_phase(current_phase) abort
  if a:current_phase ==# 'exposition'
    return 'rising'
  elseif a:current_phase ==# 'rising'
    return 'climax'
  elseif a:current_phase ==# 'climax'
    return 'epilogue'
  endif
  return 'exposition'
endfunction

function! s:phase_label(phase_name) abort
  if a:phase_name ==# 'rising'
    return 'RISING ACTION'
  endif
  return toupper(a:phase_name)
endfunction

function! s:guidance(phase_name) abort
  if a:phase_name ==# 'exposition'
    return 'Set the stage, discover facts, and decide what this arc is really about.'
  elseif a:phase_name ==# 'rising'
    return 'Use what you know to line up conflict, pressure, and troublesome questions.'
  elseif a:phase_name ==# 'climax'
    return 'Push the decisive thread toward confrontation, closure, or revelation.'
  endif
  return 'Montage the fallout, record consequences, and choose what the next chapter will chase.'
endfunction
