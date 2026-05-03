" autoload/game/story/setup.vim - Scene Setup and NPC Presence

function! game#story#setup#cmd_frame(state, thread_ref, stage_name) abort
  let l:threads = get(a:state, 'threads', [])
  let l:idx = str2nr(a:thread_ref)
  let l:stage = tolower(a:stage_name)

  if l:idx < 1 || l:idx > len(l:threads)
    return game#core#add_log(a:state, 'LOG_ERR: Use "frame [thread#] [stage]" with a valid thread index.')
  endif
  if index(['knowledge', 'conflict', 'endings'], l:stage) == -1
    return game#core#add_log(a:state, 'LOG_ERR: Frame stage must be knowledge, conflict, or endings.')
  endif

  let l:next_state = deepcopy(a:state)
  let l:next_state.scene.focus = l:idx
  let l:next_state.stage = l:stage
  let l:opening = 'Scene framed around ' . l:threads[l:idx - 1] . ' at TO ' . toupper(l:stage) . ' during ' . game#story#framework_phase_label(l:next_state) . '.'
  let l:next_state = game#story#records#append_scene_opening(l:next_state, l:next_state.loc, l:opening)
  let l:next_state = game#story#threads#record_fact_for_thread(l:next_state, l:threads[l:idx - 1], l:opening)
  let l:next_state.hint = 'DIRECTIVE: Scene frame locked. Choose present NPCs or press forward.'

  return game#core#add_log(l:next_state, [
        \ 'FADE IN: ' . game#story#state#scene_label(l:next_state),
        \ 'MAIN THREAD: ' . l:threads[l:idx - 1],
        \ 'STAGE: TO ' . toupper(l:stage),
        \ 'ARC: ' . game#story#framework_summary(l:next_state)
        \ ])
endfunction

function! game#story#setup#cmd_npc(state, subcmd, npc_name) abort
  let l:scene_card = game#story#records#get_scene_card(get(get(a:state, 'notes', {}), 'scene_cards', []), a:state.loc)
  let l:scene_name = game#story#state#scene_label(a:state)

  if empty(a:subcmd) || a:subcmd ==# 'list'
    let l:lines = ['--- SCENE NPCS ---', 'Scene: ' . l:scene_name]
    let l:npcs = empty(l:scene_card) ? [] : get(l:scene_card, 'npcs', [])
    if empty(l:npcs)
      call add(l:lines, ' * none')
    else
      for l:npc in l:npcs
        call add(l:lines, ' * ' . l:npc)
      endfor
    endif
    call add(l:lines, '------------------')
    return game#core#add_log(a:state, l:lines)
  endif

  let l:next_state = deepcopy(a:state)
  if a:subcmd ==# 'add'
    let l:next_state = game#story#records#assign_scene_npc(l:next_state, l:next_state.loc, a:npc_name)
    let l:next_state = game#story#threads#record_fact(l:next_state, a:npc_name . ' is present in the current scene.')
    let l:next_state.hint = 'DIRECTIVE: NPC presence updated for the active scene.'
    return game#core#add_log(l:next_state, ['SCENE CAST: Added ' . a:npc_name . ' to ' . l:scene_name . '.'])
  elseif a:subcmd ==# 'rm' || a:subcmd ==# 'del'
    let l:next_state = game#story#records#remove_scene_npc(l:next_state, l:next_state.loc, a:npc_name)
    let l:next_state.hint = 'DIRECTIVE: NPC roster updated for the active scene.'
    return game#core#add_log(l:next_state, ['SCENE CAST: Removed ' . a:npc_name . ' from ' . l:scene_name . '.'])
  endif

  return game#core#add_log(a:state, 'LOG_ERR: NPC command supports add, rm, or list.')
endfunction
