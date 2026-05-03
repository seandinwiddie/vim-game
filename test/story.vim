function! QuadarTest_RunStory() abort
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

  let l:rendered = game#core#render(l:state)
  let l:framework_view = game#core#render(game#core#process(l:state, 'framework'))
  let l:meeting_view = game#core#render(game#core#process(l:state, 'minds'))
  let l:party_view = game#core#render(game#core#process(l:state, 'party'))
  call QuadarTest_AssertContains(l:rendered, 'Arc: CH1 CLIMAX')
  call QuadarTest_AssertContains(l:rendered, 'Accord: 1 focus / 1 banned / 1 assumptions')
  call QuadarTest_AssertContains(l:rendered, 'Party: 1 active / 0 faded / 0 elsewhere | Group: +3')
  call QuadarTest_AssertContains(l:framework_view, '--- VIGNETTE FRAMEWORK ---')
  call QuadarTest_AssertContains(l:framework_view, 'Hook: meet the architect behind the disappearances')
  call QuadarTest_AssertContains(l:meeting_view, '--- MEETING OF MINDS ---')
  call QuadarTest_AssertContains(l:meeting_view, 'Focus Themes: survivor rescue and uncanny revelation')
  call QuadarTest_AssertContains(l:party_view, '--- PARTY TACTICS ---')
  call QuadarTest_AssertContains(l:party_view, 'Ranger Operative [ACTIVE]')
  call QuadarTest_AssertContains(l:rendered, '| NPCs: iron broker')
  call QuadarTest_AssertContains(l:rendered, '| arc: CH1')
  call QuadarTest_AssertContains(l:rendered, 'Banned Themes: gratuitous cruelty toward rescued rangers')
  call QuadarTest_AssertContains(l:rendered, '  NPCs: Bound Ranger')
  call QuadarTest_Append(l:meeting_view + [''] + l:party_view + [''] + l:framework_view + [''] + l:rendered)

  let l:party_match_state = game#core#init()
  let l:party_match_state = game#party#add_companion(l:party_match_state, game#party#create('Ranger Halver', 5, 5, 3))
  let l:party_match_state = game#party#add_companion(l:party_match_state, game#party#create('Ranger Harlan', 5, 5, 3))
  let l:party_match_state = game#core#process(l:party_match_state, 'party fade ranger h')
  call QuadarTest_AssertContains(l:party_match_state.log, 'LOG_ERR: Companion reference "ranger h" matches multiple companions: Ranger Halver, Ranger Harlan.')

  let l:interact_match_state = game#core#init()
  let l:interact_match_state.rooms[l:interact_match_state.loc].objects = [
        \ {'name': 'Veiled Gate', 'desc': 'A gate.', 'effect': 'portal_jump'},
        \ {'name': 'Veiled Gate Console', 'desc': 'A console.', 'effect': 'unlock_exit'}
        \ ]
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
      if l:fact =~# '^Montage carry'
        let l:found_montage_fact = 1
      endif
    endfor
  endfor
  call QuadarTest_AssertTrue(l:found_montage_fact == 1, 'Montage should append a Montage carry fact to thread cards.')

  let l:recruit_state = deepcopy(l:state)
  let l:recruit_state.rooms['test_recruit'] = {
        \ 'name': 'ᚲ ETHEREAL_MARSHLANDS ᚲ',
        \ 'desc': 'Murky marshes filled with strangers.',
        \ 'exits': {'north': l:recruit_state.loc},
        \ 'entities': [],
        \ 'services': [],
        \ 'objects': [{'name': 'Stranded Ranger', 'desc': 'A fellow recon operative.', 'effect': 'recruit_ranger'}]
        \ }
  let l:recruit_state.rooms[l:recruit_state.loc].exits['south'] = 'test_recruit'
  let l:before_companions = len(get(l:recruit_state.player, 'companions', []))
  let l:recruit_state = game#core#process(l:recruit_state, 'go south')
  let l:recruit_state = game#core#process(l:recruit_state, 'interact Stranded Ranger')
  let l:after_companions = len(get(l:recruit_state.player, 'companions', []))
  call QuadarTest_AssertTrue(l:after_companions == l:before_companions + 1, 'Recruiting a Stranded Ranger should add a new companion to the party.')
endfunction

call QuadarTest_Register('story', function('QuadarTest_RunStory'))
