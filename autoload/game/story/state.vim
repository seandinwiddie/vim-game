" autoload/game/story/state.vim - Story State and Summaries

function! game#story#state#bootstrap() abort
  return {
        \ 'scene': {'index': 1, 'location': 'nexus', 'focus': 1},
        \ 'meeting': {'focuses': [], 'banned': [], 'assumptions': []},
        \ 'framework': {
        \   'name': 'Vignette',
        \   'chapter': 1,
        \   'phase': 'exposition',
        \   'theme': 'Recover the missing rangers from Qua''dar Tower.',
        \   'hook': 'Kamenal needs a live witness who knows what the tower is doing to the recruits.'
        \ },
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

function! game#story#state#hydrate(state) abort
  let l:defaults = game#story#state#bootstrap()
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
  if !has_key(l:next_state, 'framework')
    let l:next_state.framework = deepcopy(l:defaults.framework)
  endif
  if !has_key(l:next_state, 'meeting')
    let l:next_state.meeting = deepcopy(l:defaults.meeting)
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
  if !has_key(l:next_state.framework, 'name')
    let l:next_state.framework.name = l:defaults.framework.name
  endif
  if !has_key(l:next_state.framework, 'chapter')
    let l:next_state.framework.chapter = l:defaults.framework.chapter
  endif
  if !has_key(l:next_state.framework, 'phase')
    let l:next_state.framework.phase = l:defaults.framework.phase
  endif
  if !has_key(l:next_state.framework, 'theme')
    let l:next_state.framework.theme = l:defaults.framework.theme
  endif
  if !has_key(l:next_state.framework, 'hook')
    let l:next_state.framework.hook = l:defaults.framework.hook
  endif
  if !has_key(l:next_state.meeting, 'focuses')
    let l:next_state.meeting.focuses = deepcopy(l:defaults.meeting.focuses)
  endif
  if !has_key(l:next_state.meeting, 'banned')
    let l:next_state.meeting.banned = deepcopy(l:defaults.meeting.banned)
  endif
  if !has_key(l:next_state.meeting, 'assumptions')
    let l:next_state.meeting.assumptions = deepcopy(l:defaults.meeting.assumptions)
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
    let l:next_state = game#story#threads#ensure_thread_card(l:next_state, l:thread)
  endfor

  let l:idx = 0
  while l:idx < len(l:next_state.notes.thread_cards)
    let l:next_state.notes.thread_cards[l:idx] = game#story#threads#normalize_card(l:next_state.notes.thread_cards[l:idx], l:next_state.stage)
    let l:idx += 1
  endwhile

  return l:next_state
endfunction

function! game#story#state#focus_label(state) abort
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

function! game#story#state#scene_label(state) abort
  let l:loc = get(get(a:state, 'scene', {}), 'location', get(a:state, 'loc', 'nexus'))
  if has_key(get(a:state, 'rooms', {}), l:loc)
    return get(a:state.rooms[l:loc], 'name', toupper(l:loc))
  endif
  return toupper(l:loc)
endfunction

function! game#story#state#quest_summary(state) abort
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

function! game#story#state#notes_summary(state) abort
  return 'Notes: ' . len(get(get(a:state, 'notes', {}), 'scene_cards', [])) . ' scenes / ' . len(get(get(a:state, 'notes', {}), 'npc_cards', [])) . ' NPCs'
endfunction
