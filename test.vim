let s:state = game#core#init()

call writefile(['--- START TESTS ---'], 'test_output.txt')

let s:state.player.trade = 50
let s:state = game#core#process(s:state, 'shop')
let s:state = game#core#process(s:state, 'buy Dark Crystal Shielding')
let s:state = game#core#process(s:state, "buy Hunter's Mark")
let s:state = game#core#process(s:state, 'buy Zinc Weave Cloak')
call add(s:state.player.inv, 'Gibsonian Shard')
let s:state = game#core#process(s:state, 'sell Gibsonian Shard')
let s:state = game#core#process(s:state, 'quests')
let s:state = game#core#process(s:state, 'notes')
let s:state = game#core#process(s:state, 'look')
let s:state = game#core#process(s:state, 'interact Arcane Terminal')
let s:state = game#core#process(s:state, 'focus 2')
let s:state.rooms[s:state.loc].objects = [
      \ {'name': 'Bound Ranger', 'desc': 'A shackled recruit calls for extraction.', 'effect': 'rescue_ranger', 'quest_id': 'rescue-rangers'},
      \ {'name': 'Sealed Reliquary', 'desc': 'An archive reliquary full of return codices.', 'effect': 'recover_tome', 'quest_id': 'recover-lost-tomes'}
      \ ]
let s:state = game#core#process(s:state, 'interact Bound Ranger')
let s:state = game#core#process(s:state, 'interact Sealed Reliquary')
let s:state = game#core#process(s:state, 'quests')
let s:state = game#core#process(s:state, 'cast Dark Crystal Shielding')
let s:state = game#core#process(s:state, 'go north')
let s:state = game#core#process(s:state, "cast Hunter's Mark")
let s:state = game#core#process(s:state, 'cast Ethereal Dagger Assault')
let s:state = game#core#process(s:state, 'inventory')
let s:state = game#core#process(s:state, 'profile')
let s:state = game#core#process(s:state, 'notes')

call writefile(game#core#render(s:state), 'test_output.txt', 'a')
