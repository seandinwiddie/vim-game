" autoload/game/data.vim - Room Data

function! game#data#init_rooms() abort
  return {
        \ 'nexus': {
        \   'name': 'ᚠ MERCHANDISE_STORE_ROOM ᚠ',
        \   'desc': "A bunker-like emporium, a maggot pile within the starry settlement of Quadar Tower. Shadows dance with the echoes of ancient electronic goth logic. You preside over this emporium, brokering eldritch artifacts.",
        \   'exits': {'north': 'hallway', 'west': 'unexplored'},
        \   'services': ['trade'],
        \   'entities': [],
        \   'objects': [{'name': 'Arcane Terminal', 'desc': 'A flickering terminal detailing recent shipments, missing operatives, and scavenged codices.', 'effect': 'briefing'}]
        \ },
        \ 'hallway': {
        \   'name': 'ᚢ UMBRAL_REACH_CORRIDOR ᚢ',
        \   'desc': "A narrow passage of obsidian stone, crystallized in extraterrestrial resonance. The air hums with chthonic frequencies pulsating from the core.",
        \   'exits': {'south': 'nexus', 'north': 'spire_base', 'east': 'unexplored'},
        \   'services': [],
        \   'entities': [{'name': 'Ashwalker', 'str': 4, 'agi': 7, 'arc': 4}],
        \   'objects': []
        \ },
        \ 'spire_base': {
        \   'name': 'ᚦ BASTION_OF_THE_SPIRE ᚦ',
        \   'desc': "The indomitable tower stands as a testament to long-ago awakening. Colossal structure vibrating with low magic of corrupt watchers. Neon blurs in the Abyssal Murk.",
        \   'exits': {'south': 'hallway', 'east': 'marshes', 'west': 'unexplored', 'north': 'unexplored'},
        \   'services': [],
        \   'entities': [{'name': 'Obsidian Warden', 'str': 7, 'agi': 2, 'arc': 6}],
        \   'objects': [{'name': 'Chthonic Lever', 'desc': 'A heavy stone mechanism covered in sigils and linked to hidden passages in the tower shell.', 'effect': 'unlock_exit'}]
        \ },
        \ 'marshes': {
        \   'name': 'ᚨ ETHEREAL_MARSHES ᚨ',
        \   'desc': "Once lush landscapes now enveloped by poisonous Abyssal Murk. Great furrowing depths of endless ooze and medieval torture.",
        \   'exits': {'west': 'spire_base', 'north': 'abyssal_void', 'east': 'unexplored', 'south': 'unexplored'},
        \   'services': [],
        \   'entities': [{'name': 'Ashwalker Junkie', 'str': 4, 'agi': 7, 'arc': 4}],
        \   'objects': []
        \ },
        \ 'abyssal_void': {
        \   'name': 'ᛟ ABYSSAL_VOID ᛟ',
        \   'desc': "The void that invaded once-holy grounds. The sacredness of the Ethereal Towerlands has given way to the blackness of heavenly damnation.",
        \   'exits': {'south': 'marshes', 'north': 'unexplored', 'east': 'unexplored', 'west': 'unexplored'},
        \   'services': [],
        \   'entities': [{'name': 'Doomguard', 'str': 8, 'agi': 3, 'arc': 3}],
        \   'objects': [{'name': 'Void Rift', 'desc': 'A swirling vortex of dark energy that warps time, tension, and direction.', 'effect': 'surge_rift'}]
        \ }
        \ }
endfunction
