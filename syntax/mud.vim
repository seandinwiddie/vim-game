" syntax/mud.vim - Quadar MUD Syntax Highlighting
if exists("b:current_syntax")
  finish
endif

" Runes & Sigils
syntax match mudRune /[ᚠᚢᚦᚨᚱᚲᚷᚹ]/
highlight default link mudRune Special

" System Logs (Data fragments)
syntax match mudSystemLog /SYSTEM_OVERRIDE\|NEURAL_LINK_ESTABLISHED\|LOG_ERR_CRITICAL\|*** WELCOME TO QUA'DAR ***/
highlight default link mudSystemLog WarningMsg

" Room Headers & ASCII
syntax match mudHeader /== .* ==/
syntax match mudBanner /ᚠ .* ᚠ/
highlight default link mudHeader Title
highlight default link mudBanner String

" Commands & Prompts
syntax match mudPrompt /Command >/
highlight default link mudPrompt Question

" Loom of Fate Results
syntax match mudLoomResult /\[Loom of Fate: [0-9]*\]/
highlight default link mudLoomResult Comment

" Character Stats
syntax match mudStats /\[HP: [0-9]*\/[150]*\]/
highlight default link mudStats Directory

let b:current_syntax = "mud"
