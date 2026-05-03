function! QuadarTest_RunCombat() abort
  let l:invalid_cast_action = game#action#command('cast')
  call QuadarTest_AssertTrue(get(l:invalid_cast_action, 'type', '') ==# 'system/invalidInput', 'cast without a spell should be rejected at the action boundary.')
  call QuadarTest_AssertContains(game#core#process(game#core#init(), 'cast').log, "LOG_ERR: Specify a spell to cast (e.g. 'cast Ethereal Dagger Assault').")

  let l:state = QuadarTest_CampaignState()
  let l:catalog = game#enemies#catalog()
  call QuadarTest_AssertTrue(has_key(l:catalog, 'obsidian-warden'), 'Enemy catalog should expose canonical keyed entries.')
  call QuadarTest_AssertTrue(get(get(l:catalog['obsidian-warden'], 'stats', {}), 'str', 0) == 7, 'Enemy catalog should retain canonical stat blocks.')
  call QuadarTest_AssertTrue(len(get(get(l:catalog['abyssal-overfiend'], 'boss', {}), 'phases', [])) == 2, 'Enemy catalog should carry boss phase metadata.')
  call QuadarTest_AssertTrue(game#combat#spells#match_known(get(l:state.player, 'spells', []), 'dark crystal') ==# 'Dark Crystal Shielding', 'Spell matching should continue supporting unique prefixes.')
  call QuadarTest_AssertTrue(!empty(game#combat#spells#get('Precision Shot')), 'Spell registry should expose Precision Shot through the shared registry.')
  call QuadarTest_AssertTrue(len(game#enemies#pool(2)) == 5, 'Enemy rank pools should stay centrally defined by difficulty tier.')
  call QuadarTest_AssertTrue(get(game#enemies#pool(4)[0], 'name', '') ==# 'Storm Titan', 'Enemy rank pools should preserve their canonical spawn order for deterministic room generation.')
  let l:oracle_pool = game#enemies#select(['Ashwalker', 'Voidwraith', 'Doomguard', 'Twilight Weaver'])
  call QuadarTest_AssertTrue(len(l:oracle_pool) == 4 && get(l:oracle_pool[3], 'name', '') ==# 'Twilight Weaver', 'Canonical enemy selection should preserve requested spawn subsets in order.')
  call QuadarTest_AssertTrue(get(game#enemies#archetype('Sentinel of Terror'), 'signature', '') ==# 'Dark Crystal Shielding', 'Enemy archetype lookup should still support alias names through the shared matcher.')
  let l:boss = game#enemies#build_boss('Abyssal Overfiend')
  call QuadarTest_AssertTrue(get(l:boss, 'is_boss', 0) == 1 && get(l:boss, 'phase_label', '') ==# 'Voidmaw Form', 'Boss construction should now derive its opening phase from the enemy catalog.')

  let l:cast_match_state = game#core#init()
  let l:cast_match_state.player.spells += ['Shatterstrike Slam', 'Shadowstep Mastery']
  let l:cast_match_state.rooms[l:cast_match_state.loc].entities = [{'name': 'Spell Dummy', 'str': 5, 'agi': 5, 'arc': 5}]
  let l:cast_match_state = game#combat#cmd_cast(l:cast_match_state, 'sh')
  call QuadarTest_AssertContains(l:cast_match_state.log, "SPELL_ERR: 'sh' matches multiple known spells: Shatterstrike Slam, Shadowstep Mastery.")

  let l:attack_win_state = game#core#init()
  let l:attack_win_state.rooms[l:attack_win_state.loc] = {
        \ 'name': 'ᚲ COMBAT_TEST ᚲ',
        \ 'desc': 'A deterministic combat proving ground.',
        \ 'exits': {},
        \ 'entities': [{'name': 'Test Sentinel', 'str': 7, 'agi': 7, 'arc': 7}],
        \ 'objects': [],
        \ 'services': []
        \ }
  let l:attack_seed = l:attack_win_state.rng_seed
  let l:attack_win_state = game#combat#cmd_attack(l:attack_win_state, {'rolls': {'player': 20, 'enemy': 1}, 'seed': 11})
  call QuadarTest_AssertTrue(empty(l:attack_win_state.rooms[l:attack_win_state.loc].entities), 'Injected attack rolls should allow direct tests to force a combat win.')
  call QuadarTest_AssertTrue(l:attack_win_state.rng_seed == l:attack_seed, 'Injected attack rolls should bypass RNG advancement.')
  call QuadarTest_AssertContains(l:attack_win_state.log, 'PLAYER: Roll[d20]=20')
  call QuadarTest_AssertContains(l:attack_win_state.log, 'ENEMY : Roll[d20]=1')

  let l:attack_loss_state = game#core#init()
  let l:attack_loss_state.rooms[l:attack_loss_state.loc] = {
        \ 'name': 'ᚲ COMBAT_TEST ᚲ',
        \ 'desc': 'A deterministic combat proving ground.',
        \ 'exits': {},
        \ 'entities': [{'name': 'Test Juggernaut', 'str': 9, 'agi': 9, 'arc': 9}],
        \ 'objects': [],
        \ 'services': []
        \ }
  let l:attack_loss_state = game#combat#cmd_attack(l:attack_loss_state, {'rolls': {'player': 1, 'enemy': 20}, 'seed': 17})
  call QuadarTest_AssertTrue(len(l:attack_loss_state.rooms[l:attack_loss_state.loc].entities) == 1, 'Injected attack rolls should allow direct tests to force a combat loss.')
  call QuadarTest_AssertContains(l:attack_loss_state.log, 'CRITICAL FAILURE: The Test Juggernaut retaliates with lethal force!')

  let l:cast_hit_state = game#core#init()
  let l:cast_hit_state.player.spells += ['Explosive Barrage']
  let l:cast_hit_state.rooms[l:cast_hit_state.loc] = {
        \ 'name': 'ᚲ SPELL_TEST ᚲ',
        \ 'desc': 'A deterministic spell proving ground.',
        \ 'exits': {},
        \ 'entities': [{'name': 'Spell Dummy', 'str': 5, 'agi': 5, 'arc': 5}],
        \ 'objects': [],
        \ 'services': []
        \ }
  let l:cast_seed = l:cast_hit_state.rng_seed
  let l:cast_hit_state = game#combat#cmd_cast(l:cast_hit_state, 'Explosive Barrage', {'rolls': {'player': 20}, 'seed': 13})
  call QuadarTest_AssertTrue(empty(l:cast_hit_state.rooms[l:cast_hit_state.loc].entities), 'Injected cast rolls should allow direct tests to force a spell hit.')
  call QuadarTest_AssertTrue(l:cast_hit_state.rng_seed == l:cast_seed, 'Injected cast rolls should bypass RNG advancement.')
  call QuadarTest_AssertContains(l:cast_hit_state.log, 'RANGED_ROLL: 28')

  let l:cast_fail_state = game#core#init()
  let l:cast_fail_state.player.spells += ['Explosive Barrage']
  let l:cast_fail_state.rooms[l:cast_fail_state.loc] = {
        \ 'name': 'ᚲ SPELL_TEST ᚲ',
        \ 'desc': 'A deterministic spell proving ground.',
        \ 'exits': {},
        \ 'entities': [{'name': 'Spell Dummy', 'str': 5, 'agi': 5, 'arc': 5}],
        \ 'objects': [],
        \ 'services': []
        \ }
  let l:cast_fail_state = game#combat#cmd_cast(l:cast_fail_state, 'Explosive Barrage', {'rolls': {'player': 1}, 'seed': 19})
  call QuadarTest_AssertTrue(len(l:cast_fail_state.rooms[l:cast_fail_state.loc].entities) == 1, 'Injected cast rolls should allow direct tests to force a spell miss.')
  call QuadarTest_AssertContains(l:cast_fail_state.log, 'RESISTED: The Spell Dummy deflects the magic and counterattacks!')

  let l:flavor = game#enemies#flavor_lines('Obsidian Warden')
  call QuadarTest_AssertTrue(!empty(l:flavor), 'Combat flavor lookup should return signature data for Obsidian Warden.')

  let l:counter_state = deepcopy(l:state)
  let l:counter_state.player.str = 1
  let l:counter_state.player.agi = 1
  let l:counter_state.player.arc = 1
  let l:counter_state.player.hp = 200
  let l:counter_state.mark = 'Ashwalker'
  let l:counter_state.rooms[l:counter_state.loc] = {
        \ 'name': 'ᚲ MARSH_TEST ᚲ',
        \ 'desc': 'Test marsh.',
        \ 'exits': {},
        \ 'entities': [{'name': 'Ashwalker', 'str': 99, 'agi': 99, 'arc': 99}],
        \ 'objects': [],
        \ 'services': []
        \ }
  let l:counter_state = game#core#process(l:counter_state, 'attack')
  call QuadarTest_AssertTrue(empty(get(l:counter_state, 'mark', '')), 'Ashwalker counter-signature should strip Hunter''s Mark on a duel loss.')
  call QuadarTest_Append(['--- COMBAT OK ---'] + l:flavor)
endfunction

call QuadarTest_Register('combat', function('QuadarTest_RunCombat'))
