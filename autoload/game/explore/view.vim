" autoload/game/explore/view.vim - Exploration Rendering

function! game#explore#view#cmd_look(state) abort
  let l:room = a:state.rooms[a:state.loc]
  let l:next_state = copy(a:state)
  let l:next_state.hint = 'DIRECTIVE: Use "go [dir]" to explore, "interact [object]" to manipulate the scene, or "ask" the oracle.'
  let l:lines = [
        \ '---',
        \ l:room.name,
        \ l:room.desc
        \ ]

  if has_key(l:room, 'objects') && !empty(l:room.objects)
    call add(l:lines, 'INTERACTIVE OBJECTS:')
    for l:obj in l:room.objects
      let l:obj_name = type(l:obj) == v:t_dict ? get(l:obj, 'name', 'Unknown Object') : l:obj
      call add(l:lines, '  > ' . s:object_marker(a:state, l:obj) . ' ' . l:obj_name)
    endfor
  endif

  if has_key(l:room, 'services') && !empty(l:room.services)
    call add(l:lines, 'SERVICES: ' . join(l:room.services, ', '))
  endif

  if !empty(l:room.entities)
    call add(l:lines, 'DETECTED ENTITIES:')
    for l:ent in l:room.entities
      let l:ent_name = type(l:ent) == v:t_dict ? get(l:ent, 'name', 'Unknown Entity') : l:ent
      let l:next_state = game#story#record_npc(l:next_state, l:ent_name, l:room.name)
      call add(l:lines, '  > [!!] ' . l:ent_name)
    endfor
    let l:next_state.hint = 'DIRECTIVE: Hostiles detected! Type "attack" to engage!'
  endif

  call add(l:lines, 'ᚱ ENTRANCES: ' . join(keys(l:room.exits), ', '))
  call add(l:lines, '[Threat Tier: ' . get(l:room, 'difficulty', 1) . ' | HP: ' . a:state.player.hp . '/' . a:state.player.max_hp . ']')
  call add(l:lines, '--')
  return game#core#add_log(l:next_state, l:lines)
endfunction

function! s:object_marker(state, obj) abort
  let l:marker = '[?]'
  if type(a:obj) == v:t_dict && has_key(a:obj, 'quest_id') && game#story#has_active_quest(a:state, a:obj.quest_id)
    let l:marker = '[*]'
  elseif type(a:obj) == v:t_dict && get(a:obj, 'effect', '') ==# 'briefing'
    let l:marker = '[!]'
  endif
  return l:marker
endfunction
