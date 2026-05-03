function! QuadarTest_RunClimax() abort
  let l:state = QuadarTest_CampaignState()
  let l:boss_seed = game#enemies#build_boss('Abyssal Overfiend')
  let l:boss_tuning = game#tuning#get('enemies.boss.abyssal_overfiend')

  for l:climax_id in ['rescue-rangers', 'recover-lost-tomes', 'purify-altars']
    let l:status_result = game#quest#set_status(l:state, l:climax_id, 'complete')
    let l:state = l:status_result.state
  endfor

  let l:state.loc = 'nexus'
  let l:state.rooms.nexus.objects = [{'name': 'Arcane Terminal', 'desc': 'A flickering terminal.', 'effect': 'briefing'}]
  let l:state.flags.terminal_briefed = 1
  let l:state = game#core#process(l:state, 'interact Arcane Terminal')
  call QuadarTest_AssertTrue(get(l:state.flags, 'climax_unveiled', 0) == 1, 'Re-examining the terminal with all three quests done should unveil the climax.')

  let l:nexus_objects = l:state.rooms.nexus.objects
  let l:has_sigil = 0
  for l:obj in l:nexus_objects
    if get(l:obj, 'effect', '') ==# 'descend_throne'
      let l:has_sigil = 1
    endif
  endfor
  call QuadarTest_AssertTrue(l:has_sigil, 'Climax unveil should spawn an Abyssal Sigil interactable in the Merchandise Store Room.')

  let l:state = game#core#process(l:state, 'interact Abyssal Sigil')
  call QuadarTest_AssertTrue(l:state.loc ==# 'abyssal_throne', 'Abyssal Sigil should descend the player onto the Abyssal Throne.')

  " Combat is now non-deterministic.
  " To verify boss flow, we will loop until defeated or just verify it can be engaged.
  " But for a test, we want to see phase shifts.
  " Since we can't inject rolls, we give player god stats to 'force' a win eventually.
  let l:state.player.str = 500
  let l:state.player.agi = 500
  let l:state.player.arc = 500
  let l:state.player.hp = 9999
  let l:state.player.max_hp = 9999

  let l:max_attempts = 10
  while !empty(l:state.rooms['abyssal_throne'].entities) && l:max_attempts > 0
    let l:state = game#core#process(l:state, 'attack')
    let l:max_attempts -= 1
  endwhile

  call QuadarTest_AssertTrue(empty(l:state.rooms['abyssal_throne'].entities), 'With god stats, the Overfiend should eventually be defeated.')

  let l:state = game#core#process(l:state, 'interact Throne Sigil')
  call QuadarTest_AssertTrue(l:state.surge == 0, 'Defiling the Throne Sigil should reset the Surge Count.')
  call QuadarTest_AssertTrue(l:state.player.hp == l:state.player.max_hp, 'Defiling the Throne Sigil should fully restore HP.')

  let l:climax_quest = {}
  for l:quest in l:state.quests
    if get(l:quest, 'id', '') ==# 'confront-overfiend'
      let l:climax_quest = l:quest
      break
    endif
  endfor
  call QuadarTest_AssertTrue(get(l:climax_quest, 'status', '') ==# 'complete', 'Boss defeat should complete the confront-overfiend quest.')
  call QuadarTest_AssertTrue(index(l:state.player.inv, 'Voidmaw Sigil') != -1, 'Climax quest should award the Voidmaw Sigil reward.')
  call QuadarTest_AssertTrue(index(l:state.player.spells, 'Stellar Burst Barrage') != -1, 'Climax quest should award the Stellar Burst Barrage reward spell.')
  call QuadarTest_Append('--- CLIMAX OK ---')
endfunction

call QuadarTest_Register('climax', function('QuadarTest_RunClimax'))
