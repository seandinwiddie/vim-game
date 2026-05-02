" autoload/game/data.vim - Room Data

function! game#data#init_rooms() abort
  return {
        \ 'nexus': {
        \   'name': 'ᚠ MERCHANDISE_STORE_ROOM ᚠ',
        \   'desc': "A bunker-like emporium, a maggot pile within the starry settlement of Quadar Tower. Shadows dance with the echoes of ancient electronic goth logic. You preside over this emporium, brokering eldritch artifacts.",
        \   'exits': {'north': 'hallway'},
        \   'entities': []
        \ },
        \ 'hallway': {
        \   'name': 'ᚢ UMBRAL_REACH_CORRIDOR ᚢ',
        \   'desc': "A narrow passage of obsidian stone, crystallized in extraterrestrial resonance. The air hums with chthonic frequencies pulsating from the core.",
        \   'exits': {'south': 'nexus', 'north': 'spire_base'},
        \   'entities': ['Ashwalker (Renegade Wanderer)']
        \ },
        \ 'spire_base': {
        \   'name': 'ᚦ BASTION_OF_THE_SPIRE ᚦ',
        \   'desc': "The indomitable tower stands as a testament to long-ago awakening. Colossal structure vibrating with low magic of corrupt watchers. Neon blurs in the Abyssal Murk.",
        \   'exits': {'south': 'hallway', 'east': 'marshes'},
        \   'entities': ['Obsidian Warden (Sentinel of Terror)']
        \ },
        \ 'marshes': {
        \   'name': 'ᚨ ETHEREAL_MARSHES ᚨ',
        \   'desc': "Once lush landscapes now enveloped by poisonous Abyssal Murk. Great furrowing depths of endless ooze and medieval torture.",
        \   'exits': {'west': 'spire_base', 'north': 'abyssal_void'},
        \   'entities': ['Ashwalker Junkie']
        \ },
        \ 'abyssal_void': {
        \   'name': 'ᛟ ABYSSAL_VOID ᛟ',
        \   'desc': "The void that invaded once-holy grounds. The sacredness of the Ethereal Towerlands has given way to the blackness of heavenly damnation.",
        \   'exits': {'south': 'marshes'},
        \   'entities': ['Doomguard (Armored Blood Knight)']
        \ }
        \ }
endfunction
