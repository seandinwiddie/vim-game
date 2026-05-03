function! QuadarTest_RunOracle() abort
  let l:invalid_ask_action = game#action#command('ask')
  call QuadarTest_AssertTrue(get(l:invalid_ask_action, 'type', '') ==# 'system/invalidInput', 'ask without a question should be rejected at the action boundary.')
  call QuadarTest_AssertContains(game#core#process(game#core#init(), 'ask').log, "LOG_ERR: You must ask a question (e.g., 'ask is the door locked?').")

  let l:state = QuadarTest_CampaignState()
  let l:mod_state = deepcopy(l:state)
  let l:mod_state.surge = 7
  let l:mod_state.stage = 'knowledge'
  let l:mod_result = game#oracle#apply_modifier(l:mod_state, 'limelit')
  call QuadarTest_AssertTrue(l:mod_result.state.surge == 0, 'Limelit modifier should zero the Surge Count.')
  let l:mod_result = game#oracle#apply_modifier(l:mod_state, 'to endings')
  call QuadarTest_AssertTrue(l:mod_result.state.stage ==# 'endings', 'To Endings modifier should shift stage to endings.')

  let l:upstage_state = deepcopy(l:state)
  let l:upstage_state.surge = 1
  let l:mod_result = game#oracle#apply_modifier(l:upstage_state, 'upstaged')
  call QuadarTest_AssertTrue(l:mod_result.state.surge == 5, 'Upstaged modifier should bump Surge Count by 4.')

  let l:oracle_state = game#core#init()
  let l:before_surge = l:oracle_state.surge
  let l:oracle_state = game#core#process(l:oracle_state, 'ask does the tower yield?')
  call QuadarTest_AssertTrue(l:oracle_state.surge != l:before_surge || len(l:oracle_state.log) > 0, 'Oracle ask should mutate state or log.')
endfunction

call QuadarTest_Register('oracle', function('QuadarTest_RunOracle'))
