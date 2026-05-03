" autoload/game/data.vim - Room Data

function! game#data#new_room(id, biome, display_name, desc, opts) abort
  let l:room = {
        \ 'id': a:id,
        \ 'biome': a:biome,
        \ 'display_name': a:display_name,
        \ 'desc': a:desc,
        \ 'exits': get(a:opts, 'exits', {}),
        \ 'services': get(a:opts, 'services', []),
        \ 'entities': get(a:opts, 'entities', []),
        \ 'objects': get(a:opts, 'objects', []),
        \ }
  if has_key(a:opts, 'difficulty')
    let l:room.difficulty = a:opts.difficulty
  endif
  return l:room
endfunction

function! game#data#init_rooms() abort
  return {
        \ 'nexus': game#data#new_room('nexus', 'urban', 'ᚠ MERCHANDISE_STORE_ROOM ᚠ',
        \   "A bunker-like emporium, a maggot pile within the starry settlement of Quadar Tower. Shadows dance with the echoes of ancient electronic goth logic. You preside over this emporium, brokering eldritch artifacts.",
        \   {'exits': {'north': 'hallway', 'west': 'unexplored'}, 'services': ['trade'], 'objects': [{'name': 'Arcane Terminal', 'desc': 'A flickering terminal detailing recent shipments, missing operatives, and scavenged codices.', 'effect': 'briefing'}]}
        \ ),
        \ 'hallway': game#data#new_room('hallway', 'corridor', 'ᚢ UMBRAL_REACH_CORRIDOR ᚢ',
        \   "A narrow passage of obsidian stone, crystallized in extraterrestrial resonance. The air hums with chthonic frequencies pulsating from the core.",
        \   {'exits': {'south': 'nexus', 'north': 'spire_base', 'east': 'unexplored'}, 'entities': [{'name': 'Ashwalker', 'str': 4, 'agi': 7, 'arc': 4}]}
        \ ),
        \ 'spire_base': game#data#new_room('spire_base', 'spire', 'ᚦ BASTION_OF_THE_SPIRE ᚦ',
        \   "The indomitable tower stands as a testament to long-ago awakening. Colossal structure vibrating with low magic of corrupt watchers. Neon blurs in the Abyssal Murk.",
        \   {'exits': {'south': 'hallway', 'east': 'marshes', 'west': 'unexplored', 'north': 'unexplored'}, 'entities': [{'name': 'Obsidian Warden', 'str': 7, 'agi': 2, 'arc': 6}], 'objects': [{'name': 'Chthonic Lever', 'desc': 'A heavy stone mechanism covered in sigils and linked to hidden passages in the tower shell.', 'effect': 'unlock_exit'}]}
        \ ),
        \ 'marshes': game#data#new_room('marshes', 'marsh', 'ᚨ ETHEREAL_MARSHES ᚨ',
        \   "Once lush landscapes now enveloped by poisonous Abyssal Murk. Great furrowing depths of endless ooze and medieval torture.",
        \   {'exits': {'west': 'spire_base', 'north': 'abyssal_void', 'east': 'unexplored', 'south': 'unexplored'}, 'entities': [{'name': 'Ashwalker Junkie', 'str': 4, 'agi': 7, 'arc': 4}]}
        \ ),
        \ 'abyssal_void': game#data#new_room('abyssal_void', 'void', 'ᛟ ABYSSAL_VOID ᛟ',
        \   "The void that invaded once-holy grounds. The sacredness of the Ethereal Towerlands has given way to the blackness of heavenly damnation.",
        \   {'exits': {'south': 'marshes', 'north': 'unexplored', 'east': 'unexplored', 'west': 'unexplored'}, 'entities': [{'name': 'Doomguard', 'str': 8, 'agi': 3, 'arc': 3}], 'objects': [{'name': 'Void Rift', 'desc': 'A swirling vortex of dark energy that warps time, tension, and direction.', 'effect': 'surge_rift'}]}
        \ )
        \ }
endfunction
