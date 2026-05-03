function! QuadarTest_RunEconomy() abort
  let l:heal_state = game#core#init()
  let l:heal_state.player.hp = l:heal_state.player.max_hp - 5
  let l:heal_state = game#player#heal(l:heal_state, 20)
  call QuadarTest_AssertTrue(l:heal_state.player.hp == l:heal_state.player.max_hp, 'game#player#heal should clamp restored HP to max HP.')

  let l:match_exact = game#match#one(['Shadowstep Mastery', 'Shatterstrike Slam'], 'Shadowstep Mastery')
  call QuadarTest_AssertTrue(l:match_exact.found && l:match_exact.value ==# 'Shadowstep Mastery', 'Shared matcher should prefer exact matches.')
  let l:match_prefix = game#match#one(['Shadowstep Mastery', 'Shatterstrike Slam'], 'shatt')
  call QuadarTest_AssertTrue(l:match_prefix.found && l:match_prefix.value ==# 'Shatterstrike Slam', 'Shared matcher should allow unique prefixes.')
  let l:match_ambiguous = game#match#one(['Shadowstep Mastery', 'Shatterstrike Slam'], 'sh')
  call QuadarTest_AssertTrue(!l:match_ambiguous.found && l:match_ambiguous.ambiguous && len(l:match_ambiguous.matches) == 2, 'Shared matcher should surface ambiguous prefixes explicitly.')

  let l:buy_match_state = game#core#init()
  let l:buy_match_state.player.trade = 100
  let l:buy_match_state = game#core#process(l:buy_match_state, 'buy sh')
  call QuadarTest_AssertContains(l:buy_match_state.log, "TRADE_ERR: 'sh' matches multiple wares: Shatterstrike Slam, Shadowstep Mastery.")

  let l:use_match_state = game#core#init()
  let l:use_match_state.player.inv += ['Pollen Vial', 'Pollen Satchel']
  let l:use_match_state = game#player#cmd_use(l:use_match_state, 'pollen')
  call QuadarTest_AssertContains(l:use_match_state.log, "ITEM_ERR: 'pollen' matches multiple items: Pollen Vial, Pollen Satchel.")
endfunction

call QuadarTest_Register('economy', function('QuadarTest_RunEconomy'))
