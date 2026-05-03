set nocompatible
execute 'set runtimepath^=' . fnameescape(getcwd())

source test/support.vim
source test/architecture.vim
source test/economy.vim
source test/story.vim
source test/combat.vim
source test/oracle.vim
source test/climax.vim
source test/load.vim

call QuadarTest_ResetOutput()

let s:failures = []
for s:test in get(g:, 'quadar_test_cases', [])
  try
    call call(s:test.fn, [])
    call QuadarTest_Append('PASS: ' . s:test.name)
  catch
    let s:message = QuadarTest_FormatException(v:exception) . ' AT ' . v:throwpoint
    call add(s:failures, s:test.name . ' :: ' . s:message)
    call QuadarTest_Append('FAIL: ' . s:test.name . ' :: ' . s:message)
  endtry
endfor

if !empty(s:failures)
  call QuadarTest_Append(['--- FAILURES ---'] + map(copy(s:failures), '" - " . v:val'))
  execute 'cquit ' . len(s:failures)
endif

call QuadarTest_Append('--- ALL TESTS OK ---')
qa!
