" autoload/game/tuning.vim - Canonical gameplay tuning values

function! game#tuning#get(key) abort
  let l:value = s:values()
  for l:segment in split(a:key, '\.')
    if type(l:value) != v:t_dict || !has_key(l:value, l:segment)
      throw 'Unknown tuning key: ' . a:key
    endif
    let l:value = l:value[l:segment]
  endfor
  return s:copy_value(l:value)
endfunction

function! s:values() abort
  return {
        \ 'player': {
        \   'consumables': {
        \     'pollen_vial_heal': 50,
        \     'field_rations_heal': 30,
        \     'ranger_field_kit': {'heal': 60, 'guard': 6}
        \   },
        \   'rest': {'heal': 30, 'surge_gain': 5, 'spawn_threshold': 60}
        \ },
        \ 'combat': {
        \   'mark_bonus': 4,
        \   'attack': {
        \     'clear_margin': 5,
        \     'clear_damage': {'mod': 5, 'base': 1},
        \     'close_damage': {'mod': 10, 'base': 5},
        \     'defeat_margin': 5,
        \     'critical_damage': {'mod': 20, 'base': 15},
        \     'close_defeat_damage': {'mod': 15, 'base': 5}
        \   },
        \   'spells': {
        \     'dark_crystal': {'base_guard': 10},
        \     'dimensional_weave': {'base_guard': 14},
        \     'resurgence_ritual': {'base_heal': 35},
        \     'precision_shot': {'hit_threshold': 18, 'damage': {'mod': 8, 'base': 4}},
        \     'offensive': {'hit_threshold': 15, 'damage': {'mod': 10, 'base': 5}}
        \   }
        \ },
        \ 'oracle': {
        \   'surge_gain': 2,
        \   'stage_boundaries': {
        \     'knowledge': {'y_un': 96, 'y_but': 86, 'y_and': 81, 'y': 51, 'n': 21, 'n_and': 16, 'n_but': 6, 'n_un': 1},
        \     'conflict': {'y_un': 99, 'y_but': 95, 'y_and': 85, 'y': 51, 'n': 17, 'n_and': 7, 'n_but': 3, 'n_un': 1},
        \     'endings': {'y_un': 100, 'y_but': 99, 'y_and': 81, 'y': 51, 'n': 21, 'n_and': 3, 'n_but': 2, 'n_un': 1}
        \   },
        \   'modifiers': {'entering_red': {'surge_gain': 3}, 'upstaged': {'surge_gain': 4}}
        \ },
        \ 'enemies': {
        \   'boss': {'abyssal_overfiend': {'str': 14, 'agi': 6, 'arc': 12, 'phase_delta': {'str': 2, 'agi': 1, 'arc': 2}}}
        \ },
        \ 'procgen': {'friendly_spawn': {'ranger_threshold': 88, 'merchant_threshold': 78}}
        \ }
endfunction

function! s:copy_value(value) abort
  return type(a:value) == v:t_dict || type(a:value) == v:t_list ? deepcopy(a:value) : a:value
endfunction
