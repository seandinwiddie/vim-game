let s:state = game#core#init()

call writefile(['--- START TESTS ---'], 'test_output.txt')

let s:state = game#core#process(s:state, 'look')
let s:state = game#core#process(s:state, 'interact Arcane Terminal') " Test interacting with object
let s:state = game#core#process(s:state, 'go north') " To Hallway
let s:state = game#core#process(s:state, 'cast Ethereal Dagger Assault') " Attack Ashwalker with spell
let s:state = game#core#process(s:state, 'inventory')
let s:state = game#core#process(s:state, 'use Pollen Vial') " Try to use an item

call writefile(game#core#render(s:state), 'test_output.txt', 'a')