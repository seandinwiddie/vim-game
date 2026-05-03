function! QuadarTest_RunOracle() abort
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
  let l:oracle_state.surge = 7
  let l:oracle_state.rng_seed = 245
  let l:oracle_state = game#core#process(l:oracle_state, 'ask does the tower yield?')
  call QuadarTest_AssertTrue(l:oracle_state.surge == 0, 'Deterministic oracle asks should apply the seeded modifier result.')
  call QuadarTest_AssertContains(l:oracle_state.log, '[Loom of Fate: 103] YES, AND UNEXPECTEDLY')
  call QuadarTest_AssertContains(l:oracle_state.log, 'UNEXPECTED MODIFIER: LIMELIT')
endfunction

call QuadarTest_Register('oracle', function('QuadarTest_RunOracle'))
