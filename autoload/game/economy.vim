" autoload/game/economy.vim - Merchant economy and wares

function! game#economy#hydrate(state) abort
  let l:next_state = deepcopy(a:state)

  if !has_key(l:next_state, 'guard')
    let l:next_state.guard = 0
  endif
  if !has_key(l:next_state, 'mark')
    let l:next_state.mark = ''
  endif
  if !has_key(l:next_state.player, 'trade')
    let l:next_state.player.trade = 12
  endif
  if !has_key(l:next_state.player, 'upgrades')
    let l:next_state.player.upgrades = []
  endif

  return l:next_state
endfunction

function! game#economy#has_trade_access(state) abort
  let l:room = get(get(a:state, 'rooms', {}), get(a:state, 'loc', ''), {})
  return has_key(l:room, 'services') && index(l:room.services, 'trade') != -1
endfunction

function! game#economy#status_label(state) abort
  let l:mark = empty(get(a:state, 'mark', '')) ? 'none' : a:state.mark
  return 'Trade Cache: ' . get(a:state.player, 'trade', 0) . ' | Guard: ' . get(a:state, 'guard', 0) . ' | Mark: ' . l:mark
endfunction

function! game#economy#cmd_shop(state) abort
  if !game#economy#has_trade_access(a:state)
    return game#core#add_log(a:state, 'TRADE_ERR: No merchant channel is available in this location.')
  endif

  let l:next_state = deepcopy(a:state)
  let l:next_state.hint = 'DIRECTIVE: Use "buy [ware]" or "sell [relic]" while linked to the merchandise room.'
  let l:lines = [
        \ '--- MERCHANT LEDGER ---',
        \ game#economy#status_label(l:next_state)
        \ ]

  for l:ware in s:catalog()
    let l:status = s:ware_status(l:next_state, l:ware)
    call add(l:lines, '[' . l:ware.kind . '] ' . l:ware.name . ' :: ' . l:ware.price . ' trade :: ' . l:status)
    call add(l:lines, '  > ' . l:ware.desc)
  endfor

  call add(l:lines, '-----------------------')
  return game#core#add_log(l:next_state, l:lines)
endfunction

function! game#economy#cmd_buy(state, item_name) abort
  if !game#economy#has_trade_access(a:state)
    return game#core#add_log(a:state, 'TRADE_ERR: Buying is only possible from the Merchandise Store Room.')
  endif
  if empty(a:item_name)
    return game#core#add_log(a:state, 'TRADE_ERR: Use "buy [ware]" to acquire an item, spell, or upgrade.')
  endif

  let l:ware = s:find_ware(a:item_name)
  if empty(l:ware)
    return game#core#add_log(a:state, "TRADE_ERR: Unknown ware '" . a:item_name . "'.")
  endif
  if s:is_owned(a:state, l:ware)
    return game#core#add_log(a:state, 'TRADE_ERR: ' . l:ware.name . ' is already integrated into your loadout.')
  endif
  if get(a:state.player, 'trade', 0) < l:ware.price
    return game#core#add_log(a:state, 'TRADE_ERR: Insufficient trade cache for ' . l:ware.name . '.')
  endif

  let l:next_state = deepcopy(a:state)
  let l:next_state.player.trade -= l:ware.price
  let l:log_lines = ['TRANSACTION: Acquired ' . l:ware.name . ' for ' . l:ware.price . ' trade.']

  if l:ware.kind ==# 'spell'
    call add(l:next_state.player.spells, l:ware.name)
    call add(l:log_lines, 'SPELL UPLOADED: ' . l:ware.name)
  elseif l:ware.kind ==# 'upgrade'
    call add(l:next_state.player.upgrades, l:ware.name)
    if l:ware.id ==# 'zinc-weave-cloak'
      let l:next_state.player.agi += 1
      call add(l:log_lines, 'UPGRADE INSTALLED: AGI +1')
    elseif l:ware.id ==# 'obsidian-edge'
      let l:next_state.player.str += 1
      call add(l:log_lines, 'UPGRADE INSTALLED: STR +1')
    elseif l:ware.id ==# 'signal-booster-rig'
      let l:next_state.player.max_hp += 20
      let l:next_state.player.hp = min([l:next_state.player.max_hp, l:next_state.player.hp + 20])
      call add(l:log_lines, 'UPGRADE INSTALLED: MAX HP +20')
    endif
  else
    call add(l:next_state.player.inv, l:ware.name)
    call add(l:log_lines, 'WARE STORED: ' . l:ware.name)
  endif

  let l:next_state.hint = 'DIRECTIVE: Trade complete. Review the ledger or return to the field.'
  call add(l:log_lines, game#economy#status_label(l:next_state))
  return game#core#add_log(l:next_state, l:log_lines)
endfunction

function! game#economy#cmd_sell(state, item_name) abort
  if !game#economy#has_trade_access(a:state)
    return game#core#add_log(a:state, 'TRADE_ERR: Selling is only possible from the Merchandise Store Room.')
  endif
  if empty(a:item_name)
    return game#core#add_log(a:state, 'TRADE_ERR: Use "sell [relic]" to liquidate scavenged wares.')
  endif

  let l:idx = s:inventory_index(a:state.player.inv, a:item_name)
  if l:idx == -1
    return game#core#add_log(a:state, "TRADE_ERR: '" . a:item_name . "' is not in your inventory.")
  endif

  let l:item = a:state.player.inv[l:idx]
  if s:is_protected_item(l:item)
    return game#core#add_log(a:state, 'TRADE_ERR: ' . l:item . ' is locked to mission-critical use and cannot be sold.')
  endif

  let l:value = game#economy#item_value(l:item)
  if l:value <= 0
    return game#core#add_log(a:state, 'TRADE_ERR: The merchant has no market for ' . l:item . '.')
  endif

  let l:next_state = deepcopy(a:state)
  call remove(l:next_state.player.inv, l:idx)
  let l:next_state.player.trade += l:value
  let l:next_state.hint = 'DIRECTIVE: Trade cache replenished.'

  return game#core#add_log(l:next_state, [
        \ 'TRANSACTION: Sold ' . l:item . ' for ' . l:value . ' trade.',
        \ game#economy#status_label(l:next_state)
        \ ])
endfunction

function! game#economy#reward_trade(state, amount, reason) abort
  let l:next_state = deepcopy(a:state)
  let l:next_state.player.trade += a:amount
  return {
        \ 'state': l:next_state,
        \ 'log': ['SALVAGE BANKED: +' . a:amount . ' trade from ' . a:reason . '.']
        \ }
endfunction

function! game#economy#item_value(item_name) abort
  let l:values = {
        \ 'Gibsonian Shard': 7,
        \ 'Eldritch Medallion': 10,
        \ 'Zinc Plating': 6,
        \ 'Obsidian Fragment': 8,
        \ 'Abyssal Ash': 9,
        \ 'Corrupt Watcher Core': 12,
        \ 'Pollen Vial': 5,
        \ 'Field Rations': 3
        \ }
  return get(l:values, a:item_name, 0)
endfunction

function! s:catalog() abort
  return [
        \ {'id': 'field-rations', 'name': 'Field Rations', 'kind': 'item', 'price': 6, 'desc': 'Compact rations and synth-booze for quick recovery in the field.'},
        \ {'id': 'pollen-vial', 'name': 'Pollen Vial', 'kind': 'item', 'price': 8, 'desc': 'A volatile restorative harvested from the marshlands.'},
        \ {'id': 'dark-crystal-shielding', 'name': 'Dark Crystal Shielding', 'kind': 'spell', 'price': 14, 'desc': 'A defensive grimoire that raises a crystalline ward around the neural link.'},
        \ {'id': 'precision-shot', 'name': 'Precision Shot', 'kind': 'spell', 'price': 12, 'desc': 'A targeted ranged technique keyed to the ranger''s agility.'},
        \ {'id': 'hunters-mark', 'name': "Hunter's Mark", 'kind': 'spell', 'price': 12, 'desc': 'Locks a hostile into the tactical lattice for the next strike.'},
        \ {'id': 'zinc-weave-cloak', 'name': 'Zinc Weave Cloak', 'kind': 'upgrade', 'price': 18, 'desc': 'Reactive scout gear that sharpens your evasive edge.'},
        \ {'id': 'obsidian-edge', 'name': 'Obsidian Edge', 'kind': 'upgrade', 'price': 18, 'desc': 'A serrated weapons retrofit that adds brutal striking power.'},
        \ {'id': 'signal-booster-rig', 'name': 'Signal Booster Rig', 'kind': 'upgrade', 'price': 20, 'desc': 'An uplink rig that strengthens your vital envelope and field resilience.'}
        \ ]
endfunction

function! s:find_ware(item_name) abort
  let l:needle = tolower(a:item_name)
  for l:ware in s:catalog()
    if tolower(l:ware.name) ==# l:needle || tolower(l:ware.name) =~# '^' . l:needle
      return l:ware
    endif
  endfor
  return {}
endfunction

function! s:ware_status(state, ware) abort
  if s:is_owned(a:state, a:ware)
    return 'integrated'
  endif
  if get(a:state.player, 'trade', 0) >= a:ware.price
    return 'available'
  endif
  return 'insufficient trade'
endfunction

function! s:is_owned(state, ware) abort
  if a:ware.kind ==# 'spell'
    return index(get(a:state.player, 'spells', []), a:ware.name) != -1
  endif
  if a:ware.kind ==# 'upgrade'
    return index(get(a:state.player, 'upgrades', []), a:ware.name) != -1
  endif
  return 0
endfunction

function! s:inventory_index(inv, item_name) abort
  let l:needle = tolower(a:item_name)
  for l:i in range(len(a:inv))
    if tolower(a:inv[l:i]) ==# l:needle || tolower(a:inv[l:i]) =~# '^' . l:needle
      return l:i
    endif
  endfor
  return -1
endfunction

function! s:is_protected_item(item_name) abort
  return index(['Basic Dagger', 'Scout Gear', 'Ranger Signal Token', 'Lost Tomes', 'Signal Codex', 'Ranger Field Kit'], a:item_name) != -1
endfunction
