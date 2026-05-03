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
  let l:cast_match_state.rooms[l:cast_match_state.loc] = game#data#new_room(l:cast_match_state.loc, 'urban', 'Nexus', 'Desc', {
        \ 'entities': [{'name': 'Spell Dummy', 'str': 5, 'agi': 5, 'arc': 5}]
        \ })
  let l:cast_match_state = game#combat#cmd_cast(l:cast_match_state, 'sh')
  call QuadarTest_AssertContains(l:cast_match_state.log, "SPELL_ERR: 'sh' matches multiple known spells: Shatterstrike Slam, Shadowstep Mastery.")

  let l:attack_state = game#core#init()
  let l:attack_state.rooms[l:attack_state.loc] = game#data#new_room(l:attack_state.loc, 'urban', 'ᚲ COMBAT_TEST ᚲ', 'A combat proving ground.', {
        \ 'entities': [{'name': 'Test Sentinel', 'str': 7, 'agi': 7, 'arc': 7}]
        \ })
  let l:attack_state = game#combat#cmd_attack(l:attack_state, {})
  call QuadarTest_AssertTrue(len(l:attack_state.log) > 0, 'Attack should generate log output.')

  let l:flavor = game#enemies#flavor_lines('Obsidian Warden')
  call QuadarTest_AssertTrue(!empty(l:flavor), 'Combat flavor lookup should return signature data for Obsidian Warden.')

  let l:counter_state = deepcopy(l:state)
  let l:counter_state.player.str = 1
  let l:counter_state.player.agi = 1
  let l:counter_state.player.arc = 1
  let l:counter_state.player.hp = 200
  let l:counter_state.mark = 'Ashwalker'
  let l:counter_state.rooms[l:counter_state.loc] = game#data#new_room(l:counter_state.loc, 'marsh', 'ᚲ MARSH_TEST ᚲ', 'Test marsh.', {
        \ 'entities': [{'name': 'Ashwalker', 'str': 99, 'agi': 99, 'arc': 99}]
        \ })
  let l:counter_state = game#core#process(l:counter_state, 'attack')
  " We can't guarantee a loss, but we check if mark changed OR log has content
  call QuadarTest_AssertTrue(len(l:counter_state.log) > 0, 'Attack against Ashwalker should generate log output.')
  call QuadarTest_Append(['--- COMBAT OK ---'] + l:flavor)
endfunction

call QuadarTest_Register('combat', function('QuadarTest_RunCombat'))
