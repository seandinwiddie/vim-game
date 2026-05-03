" autoload/game/core.vim - Quadar Micro-MUD Functional Core

" === PURE LOGIC: INITIAL STATE ===
function! game#core#init() abort
  let l:rooms = game#data#init_rooms()
  let l:story = game#story#bootstrap()

  let l:s = {
        \ 'view': 'game',
        \ 'player': {'name': 'Kamenal', 'class': 'Rogue/Ranger', 'level': 12, 'hp': 150, 'max_hp': 150, 'inv': ['Basic Dagger', 'Scout Gear'], 'spells': ['Ethereal Dagger Assault', 'Cloak of Shadows'], 'str': 5, 'agi': 8, 'arc': 4},
        \ 'loc': 'nexus',
        \ 'rng_seed': game#rng#default_seed(),
        \ 'surge': 0,
        \ 'stage': 'knowledge',
        \ 'threads': ['Find Missing Rangers'],
        \ 'scene': l:story.scene,
        \ 'quests': l:story.quests,
        \ 'flags': l:story.flags,
        \ 'progress': l:story.progress,
        \ 'rooms': l:rooms,
        \ 'log': [],
        \ 'hint': 'SYSTEM_INIT: Type "look" to scan your surroundings.',
        \ }
  let l:s = game#core#normalize(l:s)
  let l:s = game#story#record_scene(l:s, l:s.loc)
  let l:s = game#story#record_fact_for_thread(l:s, 'Find Missing Rangers', 'Kamenal begins in the Merchandise Store Room under orders to recover missing rangers.')
  return game#core#add_log(l:s, ['NEURAL_LINK_ESTABLISHED', 'SYSTEM_OVERRIDE: INITIATING RECONNAISSANCE PROTOCOL ᚠ', 'You materialize in the Merchandise Store Room.'])
endfunction

" === PURE LOGIC: COMMAND PROCESSING ===
function! game#core#process(state, input) abort
  return game#reducer#reduce(a:state, game#action#command(a:input))
endfunction

" === INTERNAL PURE HELPERS ===

function! game#core#add_log(state, msg) abort
  let l:next_state = copy(a:state)
  if type(a:msg) == v:t_list
    let l:next_state.log += a:msg
  else
    let l:next_state.log += [a:msg]
  endif
  if len(l:next_state.log) > 100
    let l:next_state.log = l:next_state.log[-100:]
  endif
  return l:next_state
endfunction

function! game#core#render(state) abort
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
  return l:header + l:state.log
endfunction

function! game#core#normalize(state) abort
  let l:next_state = deepcopy(a:state)
  let l:next_state = game#rng#hydrate(l:next_state)
  if !has_key(l:next_state, 'threads') || empty(l:next_state.threads)
    let l:next_state.threads = ['Find Missing Rangers']
  endif
  if !has_key(l:next_state, 'hint')
    let l:next_state.hint = 'SYSTEM_INIT: Type "look" to scan your surroundings.'
  endif
  let l:next_state = game#party#hydrate(l:next_state)
  let l:next_state = game#story#hydrate(l:next_state)
  return game#economy#hydrate(l:next_state)
endfunction
