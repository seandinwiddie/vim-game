" autoload/game/story.vim - Story Facade

function! game#story#bootstrap() abort
  return game#story#state#bootstrap()
endfunction

function! game#story#hydrate(state) abort
  return game#story#state#hydrate(a:state)
endfunction

function! game#story#focus_label(state) abort
  return game#story#state#focus_label(a:state)
endfunction

function! game#story#scene_label(state) abort
  return game#story#state#scene_label(a:state)
endfunction

function! game#story#quest_summary(state) abort
  return game#story#state#quest_summary(a:state)
endfunction

function! game#story#notes_summary(state) abort
  return game#story#state#notes_summary(a:state)
endfunction

function! game#story#cmd_quests(state) abort
  return game#story#commands#cmd_quests(a:state)
endfunction

function! game#story#cmd_notes(state) abort
  return game#story#commands#cmd_notes(a:state)
endfunction

function! game#story#cmd_focus(state, focus_arg) abort
  return game#story#commands#cmd_focus(a:state, a:focus_arg)
endfunction

function! game#story#cmd_thread(state, subcmd, args) abort
  return game#story#ledger#cmd_thread(a:state, a:subcmd, a:args)
endfunction

function! game#story#cmd_scene(state) abort
  return game#story#scenes#cmd_scene(a:state)
endfunction

function! game#story#cmd_frame(state, thread_ref, stage_name) abort
  return game#story#setup#cmd_frame(a:state, a:thread_ref, a:stage_name)
endfunction

function! game#story#cmd_npc(state, subcmd, npc_name) abort
  return game#story#setup#cmd_npc(a:state, a:subcmd, a:npc_name)
endfunction

function! game#story#cmd_fade(state, summary) abort
  return game#story#scenes#cmd_fade(a:state, a:summary)
endfunction

function! game#story#cmd_aside(state, thread_ref, fact) abort
  return game#story#scenes#cmd_aside(a:state, a:thread_ref, a:fact)
endfunction

function! game#story#ensure_thread(state, thread_name) abort
  return game#story#threads#ensure_thread(a:state, a:thread_name)
endfunction

function! game#story#ensure_quest(state, quest) abort
  return game#story#records#ensure_quest(a:state, a:quest)
endfunction

function! game#story#enter_location(state, loc, discovered) abort
  return game#story#records#enter_location(a:state, a:loc, a:discovered)
endfunction

function! game#story#has_active_quest(state, quest_id) abort
  return game#story#records#has_active_quest(a:state, a:quest_id)
endfunction

function! game#story#advance_quest(state, quest_id, amount) abort
  return game#story#records#advance_quest(a:state, a:quest_id, a:amount)
endfunction

function! game#story#record_scene(state, loc) abort
  return game#story#records#record_scene(a:state, a:loc)
endfunction

function! game#story#record_fact(state, fact) abort
  return game#story#threads#record_fact(a:state, a:fact)
endfunction

function! game#story#record_fact_for_thread(state, thread_name, fact) abort
  return game#story#threads#record_fact_for_thread(a:state, a:thread_name, a:fact)
endfunction

function! game#story#record_npc(state, npc_name, scene_name) abort
  return game#story#records#record_npc(a:state, a:npc_name, a:scene_name)
endfunction
