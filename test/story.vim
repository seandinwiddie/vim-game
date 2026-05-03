function! QuadarTest_RunStory() abort
  let l:help_action = game#action#command('help')
  call QuadarTest_AssertTrue(get(l:help_action, 'type', '') ==# 'system/helpRequested', 'help should produce a typed help action.')
  let l:commands_action = game#action#command('commands')
  call QuadarTest_AssertTrue(get(l:commands_action, 'type', '') ==# 'system/helpRequested', 'commands should alias the help action.')
  let l:undo_action = game#action#command('undo')
  call QuadarTest_AssertTrue(get(l:undo_action, 'type', '') ==# 'system/undoRequested', 'undo should produce a typed undo action.')
  let l:undo_alias_action = game#action#command('u')
  call QuadarTest_AssertTrue(get(l:undo_alias_action, 'type', '') ==# 'system/undoRequested', 'u should alias the undo action.')
  let l:invalid_focus_action = game#action#command('focus')
  call QuadarTest_AssertTrue(get(l:invalid_focus_action, 'type', '') ==# 'system/invalidInput', 'focus without a thread ref should be rejected at the action boundary.')
  let l:invalid_frame_action = game#action#command('frame 1')
  call QuadarTest_AssertTrue(get(l:invalid_frame_action, 'type', '') ==# 'system/invalidInput', 'frame without both thread and stage should be rejected at the action boundary.')
  let l:invalid_framework_action = game#action#command('framework theme')
  call QuadarTest_AssertTrue(get(l:invalid_framework_action, 'type', '') ==# 'system/invalidInput', 'framework theme without text should be rejected at the action boundary.')
  let l:invalid_meeting_action = game#action#command('minds note')
  call QuadarTest_AssertTrue(get(l:invalid_meeting_action, 'type', '') ==# 'system/invalidInput', 'minds note without text should be rejected at the action boundary.')
  let l:invalid_party_action = game#action#command('party send ranger operative')
  call QuadarTest_AssertTrue(get(l:invalid_party_action, 'type', '') ==# 'system/invalidInput', 'party send without a thread number should be rejected at the action boundary.')
  let l:invalid_aside_action = game#action#command('aside 1')
  call QuadarTest_AssertTrue(get(l:invalid_aside_action, 'type', '') ==# 'system/invalidInput', 'aside without a fact should be rejected at the action boundary.')

  let l:state = QuadarTest_CampaignState()
  let l:find_thread = game#story#threads#get_thread_card(l:state.notes.thread_cards, 'Find Missing Rangers')
  let l:decode_thread = game#story#threads#get_thread_card(l:state.notes.thread_cards, 'decode the return codex relay')
  let l:ranger_companion = get(get(l:state, 'player', {}), 'companions', [])[0]

  call QuadarTest_AssertTrue(index(get(get(l:state, 'meeting', {}), 'focuses', []), 'survivor rescue and uncanny revelation') != -1, 'Meeting of Minds should retain focus themes in state.')
  call QuadarTest_AssertTrue(index(get(get(l:state, 'meeting', {}), 'banned', []), 'gratuitous cruelty toward rescued rangers') != -1, 'Meeting of Minds should retain banned themes in state.')
  call QuadarTest_AssertTrue(index(get(get(l:state, 'meeting', {}), 'assumptions', []), 'defeats should become costly consequences instead of abrupt death') != -1, 'Meeting of Minds should retain assumptions in state.')
  call QuadarTest_AssertTrue(index(get(l:find_thread, 'npcs', []), 'iron broker') != -1, 'Iron Broker should be linked to the main thread card.')
  call QuadarTest_AssertTrue(index(get(l:find_thread, 'npcs', []), 'Bound Ranger') != -1, 'Bound Ranger should be linked to the rescue thread card.')
  call QuadarTest_AssertTrue(index(get(l:find_thread, 'npcs', []), 'Ranger Operative') != -1, 'Active companions should be linked into thread bookkeeping.')
  call QuadarTest_AssertTrue(index(get(l:decode_thread, 'npcs', []), 'Bound Ranger') != -1, 'Replacement threads should inherit linked NPCs.')
  call QuadarTest_AssertTrue(get(l:ranger_companion, 'status', '') ==# 'active', 'Rallied companions should end in active scene state.')
  call QuadarTest_AssertTrue(game#party#group_bonus(l:state) == 3, 'Only active companions should contribute to Group Dynamics.')
  call QuadarTest_AssertTrue(get(get(l:state, 'framework', {}), 'phase', '') ==# 'climax', 'Framework phase should be explicitly movable through the vignette arc.')
  call QuadarTest_AssertTrue(get(get(l:state, 'framework', {}), 'theme', '') ==# 'learn why the tower is hollowing out recruits', 'Framework theme should persist in story state.')
  call QuadarTest_AssertTrue(get(get(l:state, 'framework', {}), 'hook', '') ==# 'meet the architect behind the disappearances', 'Framework hook should persist in story state.')
  call QuadarTest_AssertTrue(get(game#story#records#get_scene_card(l:state.notes.scene_cards, 'nexus'), 'framework_phase', '') ==# 'rising', 'Scene cards should preserve the framework phase active when they were reviewed.')
  call QuadarTest_AssertTrue(!empty(get(get(l:state.rooms, 'test_portal', {}).objects[0], 'target_room', '')), 'Portal gates should bind to a generated destination.')
  call QuadarTest_AssertTrue(l:state.loc ==# l:state.rooms['test_portal'].objects[0].target_room, 'Portal traversal should move the player into the bound destination room.')
  call QuadarTest_AssertTrue(get(get(l:state.rooms[l:state.loc], 'objects', [])[0], 'target_room', '') ==# 'test_portal', 'Generated portal rooms should preserve a return gate back to the source room.')

  let l:travel_action = game#action#command('go north')
  call QuadarTest_AssertTrue(get(l:travel_action, 'type', '') ==# 'explore/travelRequested', 'go north should produce a travel action.')
  call QuadarTest_AssertTrue(get(get(l:travel_action, 'payload', {}), 'dir', '') ==# 'north', 'travel action should capture the normalized direction.')

  let l:meeting_action = game#action#command('minds ban gratuitous cruelty toward rescued rangers')
  call QuadarTest_AssertTrue(get(l:meeting_action, 'type', '') ==# 'story/meetingRequested', 'Meeting of Minds commands should produce story meeting actions.')
  call QuadarTest_AssertTrue(get(get(l:meeting_action, 'payload', {}), 'subcmd', '') ==# 'ban', 'Meeting of Minds actions should capture the requested subcommand.')

  let l:trimmed_meeting = game#core#process(l:state, 'minds rm note 1')
  call QuadarTest_AssertTrue(empty(get(get(l:trimmed_meeting, 'meeting', {}), 'assumptions', [])), 'Meeting of Minds should support removing stored assumptions.')
  call QuadarTest_AssertContains(game#core#process(game#core#init(), 'framework theme').log, 'LOG_ERR: Use "framework theme [subject]" to set the vignette theme.')
  call QuadarTest_AssertContains(game#core#process(game#core#init(), 'party send ranger operative').log, 'LOG_ERR: Use "party send [name] [thread#]" to send a companion elsewhere on another thread.')

  let l:party_action = game#action#command('party send ranger operative 1')
  call QuadarTest_AssertTrue(get(l:party_action, 'type', '') ==# 'party/commandRequested', 'party commands should produce party actions.')
  call QuadarTest_AssertTrue(get(get(l:party_action, 'payload', {}), 'subcmd', '') ==# 'send', 'party action should capture the requested party subcommand.')

  let l:faded_state = game#core#process(l:state, 'party fade ranger operative')
  call QuadarTest_AssertTrue(game#party#group_bonus(l:faded_state) == 0, 'Faded companions should stop contributing to Group Dynamics.')

  let l:store = game#store#create(game#core#init())
  call QuadarTest_ResetStoreNotifications()
  let l:sub_id = game#store#subscribe(l:store, function('QuadarTest_CountStateChange'))
  call game#store#dispatch_batch(l:store, [game#action#command('look'), game#action#command('profile')])
  call QuadarTest_AssertTrue(QuadarTest_StoreNotifications() == 1, 'dispatch_batch should notify subscribers once.')
  call QuadarTest_AssertContains(game#core#render(game#store#get_state(l:store)), '--- PLAYER PROFILE ---')
  call game#store#unsubscribe(l:store, l:sub_id)

  let l:undo_store = game#store#create(game#core#init())
  let l:undo_start = game#core#render(game#store#get_state(l:undo_store))
  call game#store#dispatch_input(l:undo_store, 'help')
  call QuadarTest_AssertContains(game#core#render(game#store#get_state(l:undo_store)), '--- COMMAND REFERENCE ---')
  call game#store#dispatch_input(l:undo_store, 'undo')
  call QuadarTest_AssertTrue(join(game#core#render(game#store#get_state(l:undo_store)), "\n") ==# join(l:undo_start, "\n"), 'Undo should restore the previous rendered state exactly.')
  call game#store#dispatch_input(l:undo_store, 'undo')
  call QuadarTest_AssertContains(game#core#render(game#store#get_state(l:undo_store)), 'LOG_ERR: No earlier turn is available to undo.')

  let l:batch_undo_store = game#store#create(game#core#init())
  let l:batch_start = game#core#render(game#store#get_state(l:batch_undo_store))
  call game#store#dispatch_batch(l:batch_undo_store, [game#action#command('look'), game#action#command('profile')])
  call game#store#dispatch_input(l:batch_undo_store, 'undo')
  call QuadarTest_AssertTrue(join(game#core#render(game#store#get_state(l:batch_undo_store)), "\n") ==# join(l:batch_start, "\n"), 'Undo should treat a batched dispatch as one reversible turn.')

  let l:render_cursor_state = game#core#init()
  let l:first_render = game#core#render(l:render_cursor_state)
  call QuadarTest_AssertContains(l:first_render, 'NEURAL_LINK_ESTABLISHED')
  let l:render_cursor_state = game#core#mark_rendered(l:render_cursor_state)
  let l:second_render = game#core#render(l:render_cursor_state)
  call QuadarTest_AssertTrue(stridx(join(l:second_render, "\n"), 'NEURAL_LINK_ESTABLISHED') == -1, 'Render cursor should suppress already rendered log lines.')
  let l:render_cursor_state = game#core#process(l:render_cursor_state, 'help')
  let l:delta_render = game#core#render(l:render_cursor_state)
  call QuadarTest_AssertContains(l:delta_render, '--- COMMAND REFERENCE ---')
  call QuadarTest_AssertTrue(stridx(join(l:delta_render, "\n"), 'NEURAL_LINK_ESTABLISHED') == -1, 'Incremental renders should only include unread log lines.')
  let l:rebuilt_render = game#core#render(game#core#reset_render_cursor(l:render_cursor_state))
  call QuadarTest_AssertContains(l:rebuilt_render, 'NEURAL_LINK_ESTABLISHED')

  let l:help_state = game#core#process(game#core#init(), 'help')
  call QuadarTest_AssertTrue(get(l:help_state, 'hint', '') ==# 'DIRECTIVE: Use "help" any time to review the command surface.', 'help should update the hint toward the command reference.')

  let l:legacy_note_state = game#core#init()
  let l:legacy_note_state.notes = {
        \ 'scene_cards': [{'loc': 'nexus', 'title': 'ᚠ MERCHANDISE_STORE_ROOM ᚠ'}],
        \ 'thread_cards': [{'name': 'Find Missing Rangers'}],
        \ 'npc_cards': [{'name': 'Iron Broker'}]
        \ }
  let l:legacy_note_state = game#story#hydrate(l:legacy_note_state)
  let l:legacy_scene_card = game#story#records#get_scene_card(l:legacy_note_state.notes.scene_cards, 'nexus')
  let l:legacy_thread_card = game#story#threads#get_thread_card(l:legacy_note_state.notes.thread_cards, 'Find Missing Rangers')
  let l:legacy_npc_card = l:legacy_note_state.notes.npc_cards[0]
  call QuadarTest_AssertTrue(type(get(l:legacy_scene_card, 'closings', 0)) == v:t_list, 'Legacy scene cards should hydrate missing closings through the shared scene-card constructor.')
  call QuadarTest_AssertTrue(type(get(l:legacy_scene_card, 'openings', 0)) == v:t_list, 'Legacy scene cards should hydrate missing openings through the shared scene-card constructor.')
  call QuadarTest_AssertTrue(type(get(l:legacy_scene_card, 'npcs', 0)) == v:t_list, 'Legacy scene cards should hydrate missing NPC lists through the shared scene-card constructor.')
  call QuadarTest_AssertTrue(get(l:legacy_scene_card, 'framework_phase', '') ==# 'exposition', 'Legacy scene cards should hydrate missing framework phase through the shared scene-card constructor.')
  call QuadarTest_AssertTrue(get(l:legacy_scene_card, 'framework_chapter', 0) == 1, 'Legacy scene cards should hydrate missing framework chapter through the shared scene-card constructor.')
  call QuadarTest_AssertTrue(type(get(l:legacy_thread_card, 'aliases', 0)) == v:t_list, 'Legacy thread cards should hydrate lineage arrays through the shared thread-card constructor.')
  call QuadarTest_AssertTrue(type(get(l:legacy_thread_card, 'split_into', 0)) == v:t_list, 'Legacy thread cards should hydrate split tracking through the shared thread-card constructor.')
  call QuadarTest_AssertTrue(type(get(l:legacy_npc_card, 'scenes', 0)) == v:t_list, 'Legacy NPC cards should hydrate scene lists through the shared NPC-card constructor.')

  let l:quest_state = game#core#init()
  let l:quest_state.quests = [{'id': 'test-quest', 'title': 'Test Quest', 'thread': 'Find Missing Rangers', 'objective': 'Verify the lifecycle hook.', 'goal': 1, 'reward_item': 'Quest Sigil', 'reward_spell': 'Quest Burst'}]
  let l:quest_state = game#story#hydrate(l:quest_state)
  let l:quest_progress = game#quest#advance(l:quest_state, 'test-quest', 1)
  let l:completed_quest = game#quest#get(l:quest_progress.state, 'test-quest')
  call QuadarTest_AssertTrue(get(l:completed_quest, 'status', '') ==# 'complete', 'Quest lifecycle should mark a quest complete when progress reaches its goal.')
  call QuadarTest_AssertTrue(index(get(get(l:quest_progress.state, 'player', {}), 'inv', []), 'Quest Sigil') != -1, 'Quest lifecycle completion should deliver reward items via the completion listener.')
  call QuadarTest_AssertTrue(index(get(get(l:quest_progress.state, 'player', {}), 'spells', []), 'Quest Burst') != -1, 'Quest lifecycle completion should deliver reward spells via the completion listener.')
  call QuadarTest_AssertContains(l:quest_progress.log, 'OBJECTIVE COMPLETE: Test Quest')
  call QuadarTest_AssertContains(l:quest_progress.log, 'REWARD ITEM: Quest Sigil')
  call QuadarTest_AssertContains(l:quest_progress.log, 'REWARD SPELL: Quest Burst')
  let l:quest_cached = game#quest#advance(l:quest_progress.state, 'test-quest', 1)
  call QuadarTest_AssertContains(l:quest_cached.log, 'OBJECTIVE CACHE: Test Quest already complete.')
  let l:replaced_quest_state = game#core#init()
  let l:replaced_quest_state = game#story#hydrate(l:replaced_quest_state)
  let l:replaced_result = game#quest#set_status(l:replaced_quest_state, 'rescue-rangers', 'replaced')
  call QuadarTest_AssertTrue(get(game#quest#get(l:replaced_result.state, 'rescue-rangers'), 'status', '') ==# 'replaced', 'Quest lifecycle should support explicit replaced transitions.')
  call QuadarTest_AssertTrue(game#quest#has_active(l:replaced_result.state, 'rescue-rangers') == 0, 'Replaced quests should no longer count as active.')

  let l:party_match_state = game#core#init()
  let l:party_match_state = game#party#add_companion(l:party_match_state, game#party#create('Ranger Halver', 5, 5, 3))
  let l:party_match_state = game#party#add_companion(l:party_match_state, game#party#create('Ranger Harlan', 5, 5, 3))
  let l:party_match_state = game#core#process(l:party_match_state, 'party fade ranger h')
  call QuadarTest_AssertContains(l:party_match_state.log, 'LOG_ERR: Companion reference "ranger h" matches multiple companions: Ranger Halver, Ranger Harlan.')

  let l:interact_match_state = game#core#init()
  let l:interact_match_state.rooms[l:interact_match_state.loc] = game#data#new_room(l:interact_match_state.loc, 'urban', 'Nexus', 'Desc', {
        \ 'objects': [
        \   {'name': 'Veiled Gate', 'desc': 'A gate.', 'effect': 'portal_jump'},
        \   {'name': 'Veiled Gate Console', 'desc': 'A console.', 'effect': 'unlock_exit'}
        \ ]
        \ })
  let l:interact_match_state = game#core#process(l:interact_match_state, 'interact veiled g')
  call QuadarTest_AssertContains(l:interact_match_state.log, "LOG_ERR: 'veiled g' matches multiple objects here: Veiled Gate, Veiled Gate Console.")

  let l:montage_state = deepcopy(l:state)
  let l:montage_state.surge = 6
  let l:before_scene_idx = get(l:montage_state.scene, 'index', 1)
  let l:montage_state = game#core#process(l:montage_state, 'montage close out the rangers'' extraction across multiple corridors')
  call QuadarTest_AssertTrue(l:montage_state.surge == 0, 'Montage should reset the Surge Count.')
  call QuadarTest_AssertTrue(get(l:montage_state.scene, 'index', 1) == l:before_scene_idx + 1, 'Montage should advance the scene index by 1.')
  let l:found_montage_fact = 0
  for l:card in l:montage_state.notes.thread_cards
    for l:fact in get(l:card, 'facts', [])
      if type(l:fact) == v:t_dict && get(l:fact, 'kind', '') ==# 'montage carry'
        let l:found_montage_fact = 1
      endif
    endfor
  endfor
  call QuadarTest_AssertTrue(l:found_montage_fact == 1, 'Montage should append a Montage carry fact to thread cards.')

  let l:recruit_state = deepcopy(l:state)
  let l:recruit_state.rooms['test_recruit'] = game#data#new_room('test_recruit', 'marsh', 'ᚲ ETHEREAL_MARSHLANDS ᚲ', 'Murky marshes filled with strangers.', {
        \ 'exits': {'north': l:recruit_state.loc},
        \ 'objects': [{'name': 'Stranded Ranger', 'desc': 'A fellow recon operative.', 'effect': 'recruit_ranger'}]
        \ })
  let l:recruit_state.rooms[l:recruit_state.loc].exits['south'] = 'test_recruit'
  let l:before_companions = len(get(l:recruit_state.player, 'companions', []))
  let l:recruit_state = game#core#process(l:recruit_state, 'go south')
  let l:recruit_state = game#core#process(l:recruit_state, 'interact Stranded Ranger')
  let l:after_companions = len(get(l:recruit_state.player, 'companions', []))
  call QuadarTest_AssertTrue(l:after_companions == l:before_companions + 1, 'Recruiting a Stranded Ranger should add a new companion to the party.')
endfunction

call QuadarTest_Register('story', function('QuadarTest_RunStory'))
