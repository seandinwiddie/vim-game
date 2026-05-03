" autoload/game/story/cards.vim - Story Card Constructors

function! game#story#cards#new_notes() abort
  return {'scene_cards': [], 'thread_cards': [], 'npc_cards': []}
endfunction

function! game#story#cards#new_scene(loc, title, stage, focus, framework_phase, framework_chapter) abort
  return {
        \ 'loc': a:loc,
        \ 'title': a:title,
        \ 'visits': 0,
        \ 'stage': a:stage,
        \ 'focus': a:focus,
        \ 'framework_phase': a:framework_phase,
        \ 'framework_chapter': a:framework_chapter,
        \ 'closings': [],
        \ 'openings': [],
        \ 'npcs': []
        \ }
endfunction

function! game#story#cards#normalize_scene(card, defaults) abort
  let l:card = deepcopy(a:card)
  let l:defaults = deepcopy(a:defaults)
  let l:normalized = game#story#cards#new_scene(
        \ get(l:card, 'loc', get(l:defaults, 'loc', '')),
        \ get(l:card, 'title', get(l:defaults, 'title', '')),
        \ get(l:card, 'stage', get(l:defaults, 'stage', 'knowledge')),
        \ get(l:card, 'focus', get(l:defaults, 'focus', '')),
        \ get(l:card, 'framework_phase', get(l:defaults, 'framework_phase', 'exposition')),
        \ get(l:card, 'framework_chapter', get(l:defaults, 'framework_chapter', 1))
        \ )
  let l:normalized.visits = get(l:card, 'visits', get(l:defaults, 'visits', 0))
  let l:normalized.closings = deepcopy(get(l:card, 'closings', get(l:defaults, 'closings', [])))
  let l:normalized.openings = deepcopy(get(l:card, 'openings', get(l:defaults, 'openings', [])))
  let l:normalized.npcs = deepcopy(get(l:card, 'npcs', get(l:defaults, 'npcs', [])))
  return l:normalized
endfunction

function! game#story#cards#new_thread(name, stage) abort
  return {
        \ 'name': a:name,
        \ 'stage': a:stage,
        \ 'scenes': [],
        \ 'npcs': [],
        \ 'facts': [],
        \ 'status': 'open',
        \ 'aliases': [],
        \ 'split_from': '',
        \ 'split_into': [],
        \ 'replaced_from': '',
        \ 'replaced_by': ''
        \ }
endfunction

function! game#story#cards#normalize_thread(card, stage) abort
  let l:card = deepcopy(a:card)
  let l:normalized = game#story#cards#new_thread(get(l:card, 'name', ''), get(l:card, 'stage', a:stage))
  let l:normalized.scenes = deepcopy(get(l:card, 'scenes', []))
  let l:normalized.npcs = deepcopy(get(l:card, 'npcs', []))
  let l:normalized.facts = deepcopy(get(l:card, 'facts', []))
  let l:normalized.status = get(l:card, 'status', 'open')
  let l:normalized.aliases = deepcopy(get(l:card, 'aliases', []))
  let l:normalized.split_from = get(l:card, 'split_from', '')
  let l:normalized.split_into = deepcopy(get(l:card, 'split_into', []))
  let l:normalized.replaced_from = get(l:card, 'replaced_from', '')
  let l:normalized.replaced_by = get(l:card, 'replaced_by', '')
  return l:normalized
endfunction

function! game#story#cards#new_npc(name, ...) abort
  let l:scenes = []
  if a:0 > 0
    if type(a:1) == v:t_list
      let l:scenes = deepcopy(a:1)
    elseif !empty(a:1)
      let l:scenes = [a:1]
    endif
  endif
  return {'name': a:name, 'scenes': l:scenes}
endfunction

function! game#story#cards#normalize_npc(card) abort
  return game#story#cards#new_npc(get(a:card, 'name', ''), get(a:card, 'scenes', []))
endfunction
