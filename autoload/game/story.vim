" autoload/game/story.vim - Story, scene focus, and objectives

function! game#story#bootstrap() abort
  return {
        \ 'scene': {'index': 1, 'location': 'nexus', 'focus': 1},
        \ 'quests': [
        \   {
        \     'id': 'rescue-rangers',
        \     'title': 'Rescue the Missing Rangers',
        \     'thread': 'Find Missing Rangers',
        \     'objective': 'Locate stranded ranger operatives and open a route back through Quadar Tower.',
        \     'target_hint': 'Search newly opened sectors for bound recruits, distress beacons, and field caches.',
        \     'status': 'active',
        \     'progress': 0,
        \     'goal': 2,
        \     'reward_item': 'Ranger Field Kit',
        \     'reward_spell': 'Resurgence Ritual'
        \   }
        \ ],
        \ 'notes': {'scene_cards': [], 'thread_cards': [], 'npc_cards': []},
        \ 'flags': {'terminal_briefed': 0},
        \ 'progress': {'steps': 0, 'rooms_explored': 1}
        \ }
endfunction

function! game#story#hydrate(state) abort
  let l:defaults = game#story#bootstrap()
  let l:next_state = deepcopy(a:state)

  if !has_key(l:next_state, 'scene')
    let l:next_state.scene = deepcopy(l:defaults.scene)
  endif
  if !has_key(l:next_state.scene, 'index')
    let l:next_state.scene.index = l:defaults.scene.index
  endif
  if !has_key(l:next_state.scene, 'location')
    let l:next_state.scene.location = l:defaults.scene.location
  endif
  if !has_key(l:next_state.scene, 'focus')
    let l:next_state.scene.focus = l:defaults.scene.focus
  endif

  if !has_key(l:next_state, 'quests')
    let l:next_state.quests = deepcopy(l:defaults.quests)
  endif
  if !has_key(l:next_state, 'notes')
    let l:next_state.notes = deepcopy(l:defaults.notes)
  endif
  if !has_key(l:next_state, 'flags')
    let l:next_state.flags = deepcopy(l:defaults.flags)
  endif
  if !has_key(l:next_state, 'progress')
    let l:next_state.progress = deepcopy(l:defaults.progress)
  endif
  if !has_key(l:next_state.progress, 'steps')
    let l:next_state.progress.steps = l:defaults.progress.steps
  endif
  if !has_key(l:next_state.progress, 'rooms_explored')
    let l:next_state.progress.rooms_explored = l:defaults.progress.rooms_explored
  endif
  if !has_key(l:next_state.flags, 'terminal_briefed')
    let l:next_state.flags.terminal_briefed = l:defaults.flags.terminal_briefed
  endif
  if !has_key(l:next_state.notes, 'scene_cards')
    let l:next_state.notes.scene_cards = []
  endif
  if !has_key(l:next_state.notes, 'thread_cards')
    let l:next_state.notes.thread_cards = []
  endif
  if !has_key(l:next_state.notes, 'npc_cards')
    let l:next_state.notes.npc_cards = []
  endif

  if l:next_state.scene.focus < 1 || l:next_state.scene.focus > len(get(l:next_state, 'threads', []))
    let l:next_state.scene.focus = len(get(l:next_state, 'threads', [])) > 0 ? 1 : 0
  endif

  for l:thread in get(l:next_state, 'threads', [])
    if s:thread_card_index(l:next_state.notes.thread_cards, l:thread) == -1
      call add(l:next_state.notes.thread_cards, {'name': l:thread, 'stage': l:next_state.stage, 'scenes': [], 'facts': []})
    endif
  endfor

  return l:next_state
endfunction

function! game#story#focus_label(state) abort
  let l:threads = get(a:state, 'threads', [])
  if empty(l:threads)
    return 'NO THREAD FOCUS'
  endif

  let l:focus = get(get(a:state, 'scene', {}), 'focus', 1)
  if l:focus < 1 || l:focus > len(l:threads)
    let l:focus = 1
  endif
  return l:threads[l:focus - 1]
endfunction

function! game#story#scene_label(state) abort
  let l:loc = get(get(a:state, 'scene', {}), 'location', get(a:state, 'loc', 'nexus'))
  if has_key(get(a:state, 'rooms', {}), l:loc)
    return get(a:state.rooms[l:loc], 'name', toupper(l:loc))
  endif
  return toupper(l:loc)
endfunction

function! game#story#quest_summary(state) abort
  let l:active = 0
  let l:complete = 0
  for l:quest in get(a:state, 'quests', [])
    if get(l:quest, 'status', 'active') ==# 'complete'
      let l:complete += 1
    else
      let l:active += 1
    endif
  endfor
  return 'Objectives: ' . l:active . ' active / ' . l:complete . ' complete'
endfunction

function! game#story#notes_summary(state) abort
  return 'Notes: ' . len(get(get(a:state, 'notes', {}), 'scene_cards', [])) . ' scenes / ' . len(get(get(a:state, 'notes', {}), 'npc_cards', [])) . ' NPCs'
endfunction

function! game#story#cmd_quests(state) abort
  let l:next_state = deepcopy(a:state)
  let l:next_state.hint = 'DIRECTIVE: Objectives indexed. Adjust scene focus with "focus [thread#]".'
  let l:lines = [
        \ '--- OBJECTIVES ---',
        \ 'Scene #' . get(l:next_state.scene, 'index', 1) . ': ' . game#story#scene_label(l:next_state),
        \ 'Focus Thread: ' . game#story#focus_label(l:next_state),
        \ game#story#quest_summary(l:next_state)
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

function! game#story#cmd_notes(state) abort
  let l:next_state = deepcopy(a:state)
  let l:next_state.hint = 'DIRECTIVE: Notecards synchronized. Use these facts to steer the next scene.'
  let l:focus = game#story#focus_label(l:next_state)
  let l:thread_card = s:get_thread_card(l:next_state.notes.thread_cards, l:focus)
  let l:lines = [
        \ '--- FIELD NOTES ---',
        \ game#story#notes_summary(l:next_state),
        \ 'Focus Thread Card: ' . l:focus
        \ ]

  if !empty(l:thread_card)
    call add(l:lines, '  Stage: TO ' . toupper(get(l:thread_card, 'stage', l:next_state.stage)))
    call add(l:lines, '  Scenes: ' . (empty(get(l:thread_card, 'scenes', [])) ? 'none' : join(l:thread_card.scenes, ' | ')))
    call add(l:lines, '  Facts:')
    if empty(get(l:thread_card, 'facts', []))
      call add(l:lines, '   - No established facts yet.')
    else
      for l:fact in l:thread_card.facts
        call add(l:lines, '   - ' . l:fact)
      endfor
    endif
  endif

  call add(l:lines, 'Scene Cards:')
  if empty(l:next_state.notes.scene_cards)
    call add(l:lines, ' * none')
  else
    for l:card in l:next_state.notes.scene_cards
      call add(l:lines, ' * ' . l:card.title . ' | visits: ' . l:card.visits . ' | stage: TO ' . toupper(l:card.stage) . ' | focus: ' . l:card.focus)
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

function! game#story#cmd_focus(state, focus_arg) abort
  let l:threads = get(a:state, 'threads', [])
  if empty(l:threads)
    return game#core#add_log(a:state, 'LOG_ERR: No active threads available to focus.')
  endif
  if empty(a:focus_arg)
    return game#core#add_log(a:state, 'LOG_ERR: Use "focus [thread#]" to set the main thread for this scene.')
  endif

  let l:idx = str2nr(a:focus_arg)
  if l:idx < 1 || l:idx > len(l:threads)
    return game#core#add_log(a:state, 'LOG_ERR: Invalid thread index for scene focus.')
  endif

  let l:next_state = deepcopy(a:state)
  let l:next_state.scene.focus = l:idx
  let l:next_state.hint = 'DIRECTIVE: Scene focus aligned to thread ' . l:idx . '.'
  return game#core#add_log(l:next_state, [
        \ 'SCENE_FOCUS: ' . l:threads[l:idx - 1],
        \ 'STAGE LOCK: TO ' . toupper(l:next_state.stage)
        \ ])
endfunction

function! game#story#ensure_thread(state, thread_name) abort
  if index(get(a:state, 'threads', []), a:thread_name) != -1
    let l:next_state = deepcopy(a:state)
    if s:thread_card_index(l:next_state.notes.thread_cards, a:thread_name) == -1
      call add(l:next_state.notes.thread_cards, {'name': a:thread_name, 'stage': l:next_state.stage, 'scenes': [], 'facts': []})
    endif
    return l:next_state
  endif

  let l:next_state = deepcopy(a:state)
  call add(l:next_state.threads, a:thread_name)
  call add(l:next_state.notes.thread_cards, {'name': a:thread_name, 'stage': l:next_state.stage, 'scenes': [], 'facts': []})
  if get(l:next_state.scene, 'focus', 0) == 0
    let l:next_state.scene.focus = len(l:next_state.threads)
  endif
  return l:next_state
endfunction

function! game#story#ensure_quest(state, quest) abort
  if s:quest_index(a:state, a:quest.id) != -1
    return {'state': a:state, 'added': 0}
  endif

  let l:next_state = deepcopy(a:state)
  call add(l:next_state.quests, deepcopy(a:quest))
  let l:next_state = game#story#ensure_thread(l:next_state, a:quest.thread)
  return {'state': l:next_state, 'added': 1}
endfunction

function! game#story#enter_location(state, loc, discovered) abort
  let l:next_state = deepcopy(a:state)
  let l:next_state.scene.location = a:loc
  let l:next_state.progress.steps += 1
  if a:discovered
    let l:next_state.scene.index += 1
    let l:next_state.progress.rooms_explored += 1
  endif
  return game#story#record_scene(l:next_state, a:loc)
endfunction

function! game#story#has_active_quest(state, quest_id) abort
  let l:idx = s:quest_index(a:state, a:quest_id)
  if l:idx == -1
    return 0
  endif
  return get(a:state.quests[l:idx], 'status', 'active') ==# 'active'
endfunction

function! game#story#advance_quest(state, quest_id, amount) abort
  let l:idx = s:quest_index(a:state, a:quest_id)
  if l:idx == -1
    return {'state': a:state, 'log': []}
  endif

  let l:quest = a:state.quests[l:idx]
  if get(l:quest, 'status', 'active') ==# 'complete'
    return {'state': a:state, 'log': ['OBJECTIVE CACHE: ' . l:quest.title . ' already complete.']}
  endif

  let l:next_state = deepcopy(a:state)
  let l:next_quest = l:next_state.quests[l:idx]
  let l:next_quest.progress = min([l:next_quest.goal, l:next_quest.progress + a:amount])
  let l:log_lines = ['OBJECTIVE UPDATED: ' . l:next_quest.title . ' [' . l:next_quest.progress . '/' . l:next_quest.goal . ']']

  if l:next_quest.progress >= l:next_quest.goal
    let l:next_quest.status = 'complete'
    call add(l:log_lines, 'OBJECTIVE COMPLETE: ' . l:next_quest.title)

    if !empty(get(l:next_quest, 'reward_item', '')) && index(l:next_state.player.inv, l:next_quest.reward_item) == -1
      call add(l:next_state.player.inv, l:next_quest.reward_item)
      call add(l:log_lines, 'REWARD ITEM: ' . l:next_quest.reward_item)
    endif
    if !empty(get(l:next_quest, 'reward_spell', '')) && index(l:next_state.player.spells, l:next_quest.reward_spell) == -1
      call add(l:next_state.player.spells, l:next_quest.reward_spell)
      call add(l:log_lines, 'REWARD SPELL: ' . l:next_quest.reward_spell)
    endif
  endif

  return {'state': l:next_state, 'log': l:log_lines}
endfunction

function! game#story#record_scene(state, loc) abort
  let l:next_state = deepcopy(a:state)
  let l:title = has_key(get(l:next_state, 'rooms', {}), a:loc) ? get(l:next_state.rooms[a:loc], 'name', toupper(a:loc)) : toupper(a:loc)
  let l:focus = game#story#focus_label(l:next_state)
  let l:idx = s:scene_card_index(l:next_state.notes.scene_cards, a:loc)

  if l:idx == -1
    call add(l:next_state.notes.scene_cards, {'loc': a:loc, 'title': l:title, 'visits': 1, 'stage': l:next_state.stage, 'focus': l:focus})
  else
    let l:next_state.notes.scene_cards[l:idx].visits += 1
    let l:next_state.notes.scene_cards[l:idx].stage = l:next_state.stage
    let l:next_state.notes.scene_cards[l:idx].focus = l:focus
  endif

  let l:thread_idx = s:thread_card_index(l:next_state.notes.thread_cards, l:focus)
  if l:thread_idx == -1
    call add(l:next_state.notes.thread_cards, {'name': l:focus, 'stage': l:next_state.stage, 'scenes': [], 'facts': []})
    let l:thread_idx = len(l:next_state.notes.thread_cards) - 1
  endif
  let l:next_state.notes.thread_cards[l:thread_idx].stage = l:next_state.stage
  if index(l:next_state.notes.thread_cards[l:thread_idx].scenes, l:title) == -1
    call add(l:next_state.notes.thread_cards[l:thread_idx].scenes, l:title)
  endif

  return l:next_state
endfunction

function! game#story#record_fact(state, fact) abort
  return game#story#record_fact_for_thread(a:state, game#story#focus_label(a:state), a:fact)
endfunction

function! game#story#record_fact_for_thread(state, thread_name, fact) abort
  if empty(a:fact)
    return a:state
  endif

  let l:next_state = deepcopy(a:state)
  let l:next_state = game#story#ensure_thread(l:next_state, a:thread_name)
  let l:idx = s:thread_card_index(l:next_state.notes.thread_cards, a:thread_name)
  if l:idx == -1
    return l:next_state
  endif

  let l:card = l:next_state.notes.thread_cards[l:idx]
  let l:card.stage = l:next_state.stage
  if index(l:card.facts, a:fact) == -1
    call add(l:card.facts, a:fact)
    if len(l:card.facts) > 6
      let l:card.facts = l:card.facts[-6:]
    endif
  endif
  let l:next_state.notes.thread_cards[l:idx] = l:card
  return l:next_state
endfunction

function! game#story#record_npc(state, npc_name, scene_name) abort
  if empty(a:npc_name)
    return a:state
  endif

  let l:next_state = deepcopy(a:state)
  let l:idx = s:npc_card_index(l:next_state.notes.npc_cards, a:npc_name)
  if l:idx == -1
    call add(l:next_state.notes.npc_cards, {'name': a:npc_name, 'scenes': empty(a:scene_name) ? [] : [a:scene_name]})
  elseif !empty(a:scene_name) && index(l:next_state.notes.npc_cards[l:idx].scenes, a:scene_name) == -1
    call add(l:next_state.notes.npc_cards[l:idx].scenes, a:scene_name)
  endif
  return l:next_state
endfunction

function! s:quest_index(state, quest_id) abort
  let l:idx = 0
  for l:quest in get(a:state, 'quests', [])
    if get(l:quest, 'id', '') ==# a:quest_id
      return l:idx
    endif
    let l:idx += 1
  endfor
  return -1
endfunction

function! s:thread_card_index(cards, thread_name) abort
  let l:idx = 0
  for l:card in a:cards
    if get(l:card, 'name', '') ==# a:thread_name
      return l:idx
    endif
    let l:idx += 1
  endfor
  return -1
endfunction

function! s:scene_card_index(cards, loc) abort
  let l:idx = 0
  for l:card in a:cards
    if get(l:card, 'loc', '') ==# a:loc
      return l:idx
    endif
    let l:idx += 1
  endfor
  return -1
endfunction

function! s:npc_card_index(cards, npc_name) abort
  let l:idx = 0
  for l:card in a:cards
    if get(l:card, 'name', '') ==# a:npc_name
      return l:idx
    endif
    let l:idx += 1
  endfor
  return -1
endfunction

function! s:get_thread_card(cards, thread_name) abort
  let l:idx = s:thread_card_index(a:cards, a:thread_name)
  return l:idx == -1 ? {} : a:cards[l:idx]
endfunction
