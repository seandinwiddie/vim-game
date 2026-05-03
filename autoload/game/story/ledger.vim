" autoload/game/story/ledger.vim - Thread Command Surface and Ledger Views

function! game#story#ledger#cmd_thread(state, subcmd, args) abort
  let l:subcmd = empty(a:subcmd) ? 'list' : a:subcmd

  if l:subcmd ==# 'list'
    let l:next_state = a:state
    let l:next_state.hint = 'DIRECTIVE: Use thread mod/split/replace after a fade-out to keep the fallout ledger current.'
    return game#core#add_log(l:next_state, game#story#ledger#lines(l:next_state))
  elseif l:subcmd ==# 'add'
    let l:next_state = game#story#threads#ensure_thread(a:state, a:args)
    let l:next_state = game#story#threads#record_fact_for_thread(l:next_state, a:args, 'Thread opened for future investigation.')
    let l:next_state.hint = 'DIRECTIVE: Thread added. Use frame or focus to bring it on stage.'
    return game#core#add_log(l:next_state, 'THREAD ADDED: ' . a:args)
  endif

  let l:parsed = s:parse_thread_target(a:args)
  if l:parsed.idx < 1
    return game#core#add_log(a:state, 'LOG_ERR: Use a valid thread index.')
  endif

  if l:subcmd ==# 'rm' || l:subcmd ==# 'del'
    let l:result = game#story#threads#resolve_thread(a:state, l:parsed.idx)
    if has_key(l:result, 'error')
      return game#core#add_log(a:state, l:result.error)
    endif
    let l:result.state.hint = 'DIRECTIVE: Thread resolved. Review the ledger before opening the next scene.'
    return game#core#add_log(l:result.state, 'THREAD RESOLVED: ' . l:result.old_name)
  elseif l:subcmd ==# 'mod' || l:subcmd ==# 'rename'
    let l:result = game#story#threads#rename_thread(a:state, l:parsed.idx, l:parsed.name)
    if has_key(l:result, 'error')
      return game#core#add_log(a:state, l:result.error)
    endif
    let l:result.state.hint = 'DIRECTIVE: Thread modified. Confirm the new wording still matches the scene fallout.'
    return game#core#add_log(l:result.state, 'THREAD MODIFIED: ' . l:result.old_name . ' -> ' . l:result.new_name)
  elseif l:subcmd ==# 'split'
    let l:result = game#story#threads#split_thread(a:state, l:parsed.idx, l:parsed.name)
    if has_key(l:result, 'error')
      return game#core#add_log(a:state, l:result.error)
    endif
    let l:result.state.hint = 'DIRECTIVE: Split thread recorded. Decide whether the next frame follows the old or new thread.'
    return game#core#add_log(l:result.state, 'THREAD SPLIT: ' . l:result.old_name . ' -> ' . l:result.new_name)
  elseif l:subcmd ==# 'replace'
    let l:result = game#story#threads#replace_thread(a:state, l:parsed.idx, l:parsed.name)
    if has_key(l:result, 'error')
      return game#core#add_log(a:state, l:result.error)
    endif
    let l:result.state.hint = 'DIRECTIVE: Replacement thread active. Reframe the next scene if the fallout changed direction.'
    return game#core#add_log(l:result.state, 'THREAD REPLACED: ' . l:result.old_name . ' -> ' . l:result.new_name)
  endif

  return game#core#add_log(a:state, 'LOG_ERR: Thread command supports list, add, rm, mod, split, or replace.')
endfunction

function! game#story#ledger#lines(state) abort
  let l:lines = ['--- THREAD LEDGER ---']
  let l:active = get(a:state, 'threads', [])
  let l:idx = 1

  for l:thread_name in l:active
    let l:card = game#story#threads#get_thread_card(get(get(a:state, 'notes', {}), 'thread_cards', []), l:thread_name)
    if empty(l:card)
      let l:card = game#story#threads#default_card(l:thread_name, a:state.stage)
    else
      let l:card = game#story#threads#normalize_card(l:card, a:state.stage)
    endif
    call add(l:lines, ' ' . l:idx . '. ' . l:card.name . ' [' . toupper(get(l:card, 'status', 'open')) . ']' . s:lineage_label(l:card) . s:npc_label(l:card))
    let l:idx += 1
  endfor

  for l:card in get(get(a:state, 'notes', {}), 'thread_cards', [])
    let l:card = game#story#threads#normalize_card(l:card, a:state.stage)
    if index(l:active, l:card.name) != -1
      continue
    endif
    call add(l:lines, ' - ' . l:card.name . ' [' . toupper(get(l:card, 'status', 'open')) . ']' . s:lineage_label(l:card) . s:npc_label(l:card))
  endfor

  call add(l:lines, '---------------------')
  return l:lines
endfunction

function! s:parse_thread_target(args) abort
  let l:parts = split(a:args)
  return {'idx': str2nr(get(l:parts, 0, '')), 'name': join(l:parts[1:], ' ')}
endfunction

function! s:lineage_label(card) abort
  let l:parts = []
  if !empty(get(a:card, 'replaced_from', ''))
    call add(l:parts, 'replaces: ' . a:card.replaced_from)
  endif
  if !empty(get(a:card, 'replaced_by', ''))
    call add(l:parts, 'replaced by: ' . a:card.replaced_by)
  endif
  if !empty(get(a:card, 'split_from', ''))
    call add(l:parts, 'split from: ' . a:card.split_from)
  endif
  if !empty(get(a:card, 'split_into', []))
    call add(l:parts, 'splits: ' . join(a:card.split_into, ', '))
  endif
  if !empty(get(a:card, 'aliases', []))
    call add(l:parts, 'aliases: ' . join(a:card.aliases, ', '))
  endif
  return empty(l:parts) ? '' : ' | ' . join(l:parts, ' | ')
endfunction

function! s:npc_label(card) abort
  let l:npcs = get(a:card, 'npcs', [])
  return empty(l:npcs) ? '' : ' | NPCs: ' . join(l:npcs, ', ')
endfunction
