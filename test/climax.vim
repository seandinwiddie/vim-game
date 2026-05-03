function! QuadarTest_RunClimax() abort
  let l:state = QuadarTest_CampaignState()

  for l:climax_id in ['rescue-rangers', 'recover-lost-tomes', 'purify-altars']
    for l:i in range(len(l:state.quests))
      if get(l:state.quests[l:i], 'id', '') ==# l:climax_id
        let l:state.quests[l:i].status = 'complete'
        let l:state.quests[l:i].progress = l:state.quests[l:i].goal
      endif
    endfor
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
  let l:state.rng_seed = 2578
  let l:state = game#core#process(l:state, 'attack')
  let l:boss_room = l:state.rooms[l:state.loc]
  call QuadarTest_AssertTrue(!empty(l:boss_room.entities), 'After phase 1, the Abyssal Overfiend should still occupy the throne room.')
  call QuadarTest_AssertTrue(get(l:boss_room.entities[0], 'phases_done', 0) == 1, 'Phase 1 defeat should advance phases_done to 1.')

  let l:state = game#core#process(l:state, 'attack')
  call QuadarTest_AssertTrue(empty(l:state.rooms['abyssal_throne'].entities), 'Phase 2 defeat should remove the Overfiend from the throne room.')
  let l:state = game#core#process(l:state, 'interact Throne Sigil')
  call QuadarTest_AssertTrue(l:state.surge == 0, 'Defiling the Throne Sigil should reset the Surge Count.')
  call QuadarTest_AssertTrue(l:state.player.hp == l:state.player.max_hp, 'Defiling the Throne Sigil should fully restore HP through the shared heal helper.')

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
