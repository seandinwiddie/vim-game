function! QuadarTest_RunLoad() abort
  let l:original_home = $HOME
  let l:test_home = getcwd() . '/test/tmp-home'
  call delete(l:test_home, 'rf')
  call mkdir(l:test_home, 'p')

  try
    let $HOME = l:test_home
    let l:save_path = expand('~/.quadar_save.json')

    let l:no_save_state = game#player#cmd_load(game#core#init())
    call QuadarTest_AssertContains(l:no_save_state.log, 'LOG_ERR_CRITICAL: no_save_found :: No neural backup detected')

    call writefile(['{"player":'], l:save_path)
    let l:corrupted_state = game#player#cmd_load(game#core#init())
    call QuadarTest_AssertContains(l:corrupted_state.log, 'LOG_ERR_CRITICAL: save_corrupted :: Neural backup JSON malformed.')
    call QuadarTest_AssertContains(l:corrupted_state.log, 'DETAIL:')

    call writefile([json_encode({'player': {'name': 'Kamenal'}})], l:save_path)
    let l:outdated_state = game#player#cmd_load(game#core#init())
    call QuadarTest_AssertContains(l:outdated_state.log, 'LOG_ERR_CRITICAL: save_outdated :: Neural backup schema mismatch. Older saves need a migration step before loading.')
    call QuadarTest_AssertContains(l:outdated_state.log, 'DETAIL: Missing or invalid fields:')

    let l:saved_state = game#core#init()
    let l:saved_state.player.hp = 42
    let l:saved_state.guard = 7
    call writefile([json_encode(l:saved_state)], l:save_path)
    let l:loaded_state = game#player#cmd_load(game#core#init())
    call QuadarTest_AssertTrue(l:loaded_state.player.hp == 42, 'cmd_load should restore serialized player HP from a valid save.')
    call QuadarTest_AssertTrue(get(l:loaded_state, 'guard', 0) == 7, 'cmd_load should restore serialized guard from a valid save.')
    call QuadarTest_AssertContains(l:loaded_state.log, 'SYSTEM_LOG: State matrix restored from neural backup.')
  finally
    let $HOME = l:original_home
    call delete(l:test_home, 'rf')
  endtry
endfunction

call QuadarTest_Register('load', function('QuadarTest_RunLoad'))
