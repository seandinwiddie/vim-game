" autoload/game/story/commands.vim - Story Commands

function! game#story#commands#cmd_quests(state) abort
  let l:next_state = a:state
  let l:next_state.hint = 'DIRECTIVE: Objectives indexed. Adjust scene focus with "focus [thread#]".'
  let l:lines = [
        \ '--- OBJECTIVES ---',
        \ 'Scene #' . get(l:next_state.scene, 'index', 1) . ': ' . game#story#state#scene_label(l:next_state),
        \ 'Focus Thread: ' . game#story#state#focus_label(l:next_state),
        \ game#story#state#quest_summary(l:next_state)
        \ ]

  for l:quest in get(l:next_state, 'quests', [])
    let l:status = get(l:quest, 'status', 'active') ==# 'complete' ? '[DONE]' : '[ACTIVE]'
    call add(l:lines, l:status . ' ' . l:quest.title . ' [' . l:quest.progress . '/' . l:quest.goal . ']')
    call add(l:lines, '  > ' . l:quest.objective)
    if !empty(get(l:quest, 'target_hint', ''))
      call add(l:lines, '  > Targeting: ' . l:quest.target_hint)
    endif
  endfor

  call add(l:lines, '------------------')
  return game#core#add_log(l:next_state, l:lines)
endfunction

function! game#story#commands#cmd_notes(state) abort
  let l:next_state = a:state
  let l:next_state.hint = 'DIRECTIVE: Notecards synchronized. Use these facts to steer the next scene.'
  let l:focus = game#story#state#focus_label(l:next_state)
  let l:thread_card = game#story#threads#get_thread_card(l:next_state.notes.thread_cards, l:focus)
  let l:lines = [
        \ '--- FIELD NOTES ---',
        \ game#story#state#notes_summary(l:next_state),
        \ 'Focus Thread Card: ' . l:focus
        \ ]

  if !empty(l:thread_card)
    call add(l:lines, '  Stage: TO ' . toupper(get(l:thread_card, 'stage', l:next_state.stage)))
    call add(l:lines, '  Scenes: ' . (empty(get(l:thread_card, 'scenes', [])) ? 'none' : join(l:thread_card.scenes, ' | ')))
    call add(l:lines, '  NPCs: ' . (empty(get(l:thread_card, 'npcs', [])) ? 'none' : join(l:thread_card.npcs, ' | ')))
    call add(l:lines, '  Facts:')
    if empty(get(l:thread_card, 'facts', []))
      call add(l:lines, '   - No established facts yet.')
    else
      for l:fact in l:thread_card.facts
        if type(l:fact) == v:t_dict
          let l:prefix = l:fact.kind ==# 'general' ? '' : toupper(l:fact.kind) . ': '
          call add(l:lines, '   - ' . l:prefix . l:fact.text)
        else
          call add(l:lines, '   - ' . l:fact)
        endif
      endfor
    endif
  endif

  call extend(l:lines, game#story#meeting#lines(l:next_state))

  call extend(l:lines, game#story#ledger#lines(l:next_state))

  call add(l:lines, 'Scene Cards:')
  if empty(l:next_state.notes.scene_cards)
    call add(l:lines, ' * none')
  else
    for l:card in l:next_state.notes.scene_cards
      call add(l:lines, ' * ' . l:card.title . ' | visits: ' . l:card.visits . ' | stage: TO ' . toupper(l:card.stage) . ' | arc: CH' . get(l:card, 'framework_chapter', 1) . ' ' . game#story#framework#phase_name_label(get(l:card, 'framework_phase', 'exposition')) . ' | focus: ' . l:card.focus . ' | npcs: ' . (empty(get(l:card, 'npcs', [])) ? 'none' : join(l:card.npcs, ', ')))
    endfor
  endif

  call add(l:lines, 'Known NPCs:')
  if empty(l:next_state.notes.npc_cards)
    call add(l:lines, ' * none')
  else
    for l:npc in l:next_state.notes.npc_cards
      call add(l:lines, ' * ' . l:npc.name . ' | scenes: ' . join(l:npc.scenes, ', '))
    endfor
  endif

  call add(l:lines, '-------------------')
  return game#core#add_log(l:next_state, l:lines)
endfunction

function! game#story#commands#cmd_focus(state, focus_arg) abort
  let l:threads = get(a:state, 'threads', [])
  if empty(l:threads)
    return game#core#add_log(a:state, 'LOG_ERR: No active threads available to focus.')
  endif

  let l:idx = str2nr(a:focus_arg)
  if l:idx < 1 || l:idx > len(l:threads)
    return game#core#add_log(a:state, 'LOG_ERR: Invalid thread index for scene focus.')
  endif

  let l:next_state = a:state
  let l:next_state.scene.focus = l:idx
  let l:next_state.hint = 'DIRECTIVE: Scene focus aligned to thread ' . l:idx . '.'
  return game#core#add_log(l:next_state, [
        \ 'SCENE_FOCUS: ' . l:threads[l:idx - 1],
        \ 'STAGE LOCK: TO ' . toupper(l:next_state.stage)
        \ ])
endfunction
