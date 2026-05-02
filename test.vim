let s:state = game#core#init()

call writefile(['--- START TESTS ---'], 'test_output.txt')

let s:state = game#core#process(s:state, 'look')
let s:state = game#core#process(s:state, 'profile')
let s:state = game#core#process(s:state, 'rest')
let s:state = game#core#process(s:state, 'inventory')
let s:state = game#core#process(s:state, 'go north')
let s:state = game#core#process(s:state, 'attack')
let s:state = game#core#process(s:state, 'stage conflict')
let s:state = game#core#process(s:state, 'ask is this dangerous?')
let s:state = game#core#process(s:state, 'thread add Find the Truth')
let s:state = game#core#process(s:state, 'go east')

call writefile(game#core#render(s:state), 'test_output.txt', 'a')
