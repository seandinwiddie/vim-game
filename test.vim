let s:state = game#core#init()

call writefile(['--- START TESTS ---'], 'test_output.txt')

let s:state = game#core#process(s:state, 'look')
let s:state = game#core#process(s:state, 'go west') " Nexus west is unexplored -> procedural!
let s:state = game#core#process(s:state, 'look')
let s:state = game#core#process(s:state, 'go east') " Return to Nexus
let s:state = game#core#process(s:state, 'go north') " To Hallway
let s:state = game#core#process(s:state, 'attack') " Attack Ashwalker (dictionary with stats)

call writefile(game#core#render(s:state), 'test_output.txt', 'a')