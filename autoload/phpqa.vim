" Description:
" Vim plugin that uses PHP qa tools and highlights the current file with
" syntax errors and coding standard violations.
"
" License:
"   GPL (http://www.gnu.org/licenses/gpl.txt)
"
" Authors:
" Jon Cairns <jon@joncairns.com>
" Brian Medley <freesoftware@4321.tv> (Author of quickhigh)
"
" Changes:
" QuickHigh has been modified substantially to allow for integration with
" tools other than grep and make. The majority of the code has been moved to
" autoload/phpqa.vim
"

" ------------------------------------------------------------------------------
" Exit when already loaded (or "compatible" mode set)
if exists("g:loaded_phpqa") || &cp
	finish
endif
let g:loaded_phpqa= 1
let s:keepcpo           = &cpo
set cpo&vim


let s:num_signs = 0
let s:signName = ""

"=============================================================================
" GLOBAL FUNCTIONS {{{1

"
" Description:
" This routine allows the user to remove all signs and then add them back
" (i.e. toggle the state).  This could be useful if they want to inspect a
" line with the original syntax highlighting.
"
fun! phpqa#ToggleSigns()
	if "" == s:signName
		echohl ErrorMsg | echo "No QA tools have been run" | echohl None
		return
	endif

	if "" == s:error_list
		return
	endif

	if 0 == s:num_signs
		call s:AddSignsWrapper("all")
	else
		call phpqa#RemoveSigns("keep")
	endif
endfunction

"
" Description:
" This routine will get rid of all the signs in all open buffers.
"
fun! phpqa#RemoveSigns(augroup)
	while 0 != s:num_signs
		sign unplace 4782
		let s:num_signs = s:num_signs - 1
	endwhile

	let last_buffer = bufnr("$")
	let buf = 1
	while last_buffer >= buf
		call setbufvar(buf, "quickhigh_plugin_processed", 0)

		let buf = buf + 1
	endwhile

	if "discard" == a:augroup
		call s:RemoveAutoGroup()
		let s:error_list = ""
		if has("perl")
			perl "our %error_hash = ();"
		endif
	endif

	return
endfunction

"
" Description:
" This routine should be called after a make or grep.  (Like in the :Make and
" :Grep provided commands).
"
" It takes care of parsing the clist from vim, adding signs to all open
" buffers, and setting up autocmds.  The autocmds are used to add signs to new
" files once they're opened (e.g. if the user does a 'grep' and then does a
" :cn into a file not already open).
"
function phpqa#Init(sign)
	" else we need to add the error signs
	if 0 != s:num_signs
		echohl ErrorMsg | echo "There are still signs leftover.  Try removing first." | echohl None
		return
	endif

	let sign = a:sign

	let s:signName = sign

	" don't add anything if there's nothing to add
	if -1 == s:MakeErrorList()
		echohl ErrorMsg | echo "No errors." | echohl None
		return
	endif

	call s:AddSignsWrapper("all")
	call s:SetupAutogroup()
endfunction

"
" Description:
" This routine will get the clist and then parse that into a error list.
"
" The retrieval and parsing of the clist are separate for easier debugging.
"
function s:MakeErrorList()
	if -1 == s:GetClist()
		return -1
	endif
	" for debugging:
	" let s:clist = system("cat quickhigh.clist.file")

	return s:ParseClist()
endfunction

"
" Description:
" This routine retrieves the clist from vim.
"
function s:GetClist()
	let ABackup = @a
	let v:errmsg = ""

	" echo "redir start: " . strftime("%c")
	redir @a
	silent! clist
	redir END
	" echo "redir end: " . strftime("%c")

	let errmsg = v:errmsg
	let s:clist = @a
	let @a = ABackup

	if "" != errmsg
		if -1 != match(errmsg, '^E\d\+ No Errors')
			echohl ErrorMsg | echo errmsg | echohl None
		endif

		return -1
	endif

	return 1
endfunction

"
" Description:
" This routine initializes the error list.  The error list is basically the
" the clist in a more managable form.
"
" example clist:
"
" 3 main.c:75: warning: passing arg 3 of ...blah...
" 4 main.c:70: warning: it is tuesday this will fail
" 7 blue.c:7: programer is stupid
"
" would turn into (assuming the user setup their re's):
"
function s:ParseClist()
	" reset the error list
	let s:error_list = ""

	let sign = s:signName

	if has("perl")
		execute "perl &ParseClist(" . sign . ")"
	else

		let errorend = strlen(s:clist) - 1
		let partend = -1
		while (1)
			let partstart = partend + 1
			let partend = match(s:clist, "\n\\|$", partstart + 1)
			" echo strpart(s:clist, partstart, (partend - partstart))

			let fstart = match(s:clist, '\h', partstart)   " skip the error number
			let fend   = match(s:clist, ':',  fstart)
			let lstart = fend + 1
			let lend   = match(s:clist, ':', lstart)

			" echo "fstart: " . fstart
			" echo "fend: " . fend
			" echo "lstart: " . lstart
			" echo "lend: " . lend

			" check if done processing
			if -1 == fstart || -1 == fend || -1 == lstart || -1 == lend
				break
			endif

			" check if we got an invalid line
			if fstart >= partend || fend >= partend || lstart >= partend || lend >= partend
				continue
			endif

			let file = fnamemodify(strpart(s:clist, fstart, (fend-fstart)), ':p')
			let line = strpart(s:clist, lstart, (lend - lstart))
			let line = substitute(line, '\(\d*\).*', '\1', '')

			" echo "file: " . file
			" echo "line: " . line

			let sign = s:GetSign(strpart(s:clist, lend, (partend - lend)))

			let s:error_list = s:error_list . sign . "¬" . file . "¬" . line . "¬"
		endwhile
	endif

	" try and conserve memory
	let s:clist = ""
	if "" == s:error_list
		return -1
	else
		return 1
	endif
endfunction

"
" Description:
" This routine tries to figure out what sign goes on a particular line.  It is
" a separate function so perl can call it.
"
function s:GetSign(line)
	if exists("g:sign_phperror") && -1 != match(a:line, g:sign_phperror)
		let sign = "PhpError"
	elseif exists("g:sign_codesniffererror") && -1 != match(a:line, g:sign_codesniffererror)
		let sign = "CodeSnifferError"
	elseif exists("g:sign_messdetectorerror") && -1 != match(a:line, g:sign_messdetectorerror)
		let sign = "MessDetectorError"
	else
		let sign = s:signName
	endif
	return sign
endfunction

"
" Description:
" This routine is called when the user wants to add signs in their files.  It
" will add signs in all buffers or just the current buffer.
"
function s:AddSignsWrapper(which)
	let cur_buf = bufname("%")

	" in case we're called in the error list window or something
	if "" == cur_buf && "current" == a:which
		return
	endif

	if exists("b:quickhigh_plugin_processed")
		if 1 == b:quickhigh_plugin_processed
			return
		endif
	endif

	call s:AddSignsActual(a:which, "PhpError")
	call s:AddSignsActual(a:which, "CodeSnifferError")
	call s:AddSignsActual(a:which, "MessDetectorError")
endfunction

"
" Description:
" This routine does the actual work of parsing the error list and adding signs
" (if appropriate).
"
" 4782 is a just a random number so we won't clash with anyone else's id
"
function s:AddSignsActual(which, sign)
	if has("perl")
		execute "perl &AddSignsActual('" . a:which . "', '" . a:sign . "')"
		return
	endif

	let add_ok  = 0
	let cur_buf = bufname("") 

	" sign1:file1:line1:sign2:file2:line2:
	let pos = 0
	while (1)
		let send = match(s:error_list, '¬', pos)
		if -1 == send
			break
		endif
		let sign = strpart(s:error_list, pos, (send - pos))

		if a:sign == sign
			let pos  = send + 1
			let fend = match(s:error_list, '¬', pos)
			let file = strpart(s:error_list, pos, (fend - pos))

			let pos  = fend + 1
			let lend = match(s:error_list, '¬', pos)
			let line = strpart(s:error_list, pos, (lend - pos))
			let pos  = lend + 1

			let add_ok = 1

			if "all" == a:which
				let add_ok = 1
			else
			endif

			" only add signs for files that are loaded
			if add_ok
				" echo "sign place 4782 name=" . sign . " line=" . line . " file=" . file
				exe ":sign place 4782 name=" . sign . " line=" . line . " file=\".expand(\"%:p\")"
				let s:num_signs = s:num_signs + 1
				"call setbufvar(bufname(file), "quickhigh_plugin_processed", 1)
			endif

		else
			let pos  = match(s:error_list, '¬', send + 1) " skip file
			let pos  = match(s:error_list, '¬', pos + 1)  " skip line
			let pos  = pos + 1
		endif
	endwhile
endfunction

"
" Description:
" These routines manipulate the autocmds used to add signs into files that are
" newly opened.
"
function s:SetupAutogroup()
	augroup QuickHigh
		autocmd BufReadPost * call s:AddSignsWrapper("current")
	augroup END
endfunction

function s:RemoveAutoGroup()
	augroup QuickHigh
		autocmd!
	augroup END

	augroup! QuickHigh
endfunction

if exists("quickhigh_plugin_debug")
	function QuickhighDebug()
		redir > quickhigh.clist.file
		silent! clist
		redir END

		redir > quickhigh.vars
		let out = "b:quickhigh_warning_re = "
		if exists("b:quickhigh_warning_re")
			silent! echo out . b:quickhigh_warning_re
		else
			silent! echo out . "NOT DEFINED"
		endif

		let out = "b:quickhigh_error_re = "
		if exists("b:quickhigh_error_re")
			silent! echo out . b:quickhigh_error_re
		else
			silent! echo out . "NOT DEFINED"
		endif

		silent! echo "s:signName = " . s:signName
		redir END
	endfunction
endif

" Run the PHP linter to check for syntax errors
function! phpqa#PhpLint()
	if 0 != len(g:phpqa_php_cmd)
		call phpqa#RemoveSigns("discard")
		let l:php_output=system(g:phpqa_php_cmd." -l ".@%." 1>/dev/null")
		let l:php_list=split(l:php_output, "\n")
		if 0 != len(l:php_list)
			let l:php_list[0] = "(PHP) ".l:php_list[0]
			set errorformat=%m\ in\ %f\ on\ line\ %l
			cexpr l:php_list[0]
			cope
			call phpqa#Init("PhpError")
			return 1
		else
			if 1 == g:phpqa_verbose
				echohl Error | echo "No syntax errors" | echohl None
			endif
		endif
	elseif 1 == g:phpqa_verbose
		echohl Error | echo "PHP binary set to empty, not running lint" | echohl None
	endif
	return 0
endf

" Run PHP code sniffer.
function! phpqa#PhpCodeSniffer()
	" Run codesniffer if the command hasn't been unset
	if 0 != len(g:phpqa_codesniffer_cmd)
		let l:phpcs_output=system(g:phpqa_codesniffer_cmd." ".g:phpqa_codesniffer_args." --report=emacs ".@%)
		let l:phpcs_list=split(l:phpcs_output, "\n")
	else
		let l:phpcs_list = []
		if 1 == g:phpqa_verbose
			echohl Error | echo "PHPCS binary set to empty, not running codesniffer" | echohl None
		endif
	endif
	return l:phpcs_list
endf

" Run mess detector.
"
" The user is required to specify a ruleset XML file if they haven't already.
function! phpqa#PhpMessDetector()
	" Run messdetector if the command hasn't been unset
	if 0 != len(g:phpqa_messdetector_cmd)
		let file_tmp = ""
		while 0 == len(g:phpqa_messdetector_ruleset)
			let file_tmp = expand(resolve(input("Please specify a mess detector ruleset XML file: ",file_tmp,"file")))
			if filereadable(file_tmp)
				let g:phpqa_messdetector_ruleset = file_tmp
			else
				echohl Error |echo "Not a valid or readable file"|echohl None
			endif
		endwhile
		let l:phpmd_output=system(g:phpqa_messdetector_cmd." ".@%." text ".g:phpqa_messdetector_ruleset)
		let l:phpmd_list=split(l:phpmd_output, "\n")
	else
		let l:phpmd_list = []
		if 1 == g:phpqa_verbose
			echohl Error | echo "PHPMD binary set to empty, not running mess detector" | echohl None
		endif
	endif
	return l:phpmd_list
endf

" Combine error lists for codesniffer and messdetector
function s:CombineLists(phpcs_list,phpmd_list)

	if 0 != len(a:phpcs_list)
		let k = 0
		for val in a:phpcs_list
			let a:phpcs_list[k] = a:phpcs_list[k]." (PHP_CodeSniffer)"
			let k = k+1
		endfor
	endif
	if 0 != len(a:phpmd_list)
		let k = 0
		for val in a:phpmd_list
			let a:phpmd_list[k] = a:phpmd_list[k]." (PHPMD)"
			let k = k+1
		endfor
	endif
	return a:phpcs_list + a:phpmd_list
endf

" Run Code Sniffer and Mess Detector.
function! phpqa#PhpQaTools(runcs,runmd)
	call phpqa#RemoveSigns("discard")

	if 1 == a:runcs
		let l:phpcs_list=phpqa#PhpCodeSniffer()
	else
		let l:phpcs_list = []
	endif

	if 1 == a:runmd
		let l:phpmd_list = phpqa#PhpMessDetector()
	else
		let l:phpmd_list = []
	endif

	let error_list=s:CombineLists(l:phpcs_list,l:phpmd_list)
	if 0 != len(error_list)
		set errorformat=%f:%l:%c:\ %m,%f:%l\	%m
		cgete error_list 
		cope
		call phpqa#Init("CodeSnifferError")
	endif
endf
let s:num_cc_signs = 0

" Toggle the code coverage markers.
"
" If the command has been run, remove the signs. Otherwise run it with
" phpqa#PhpCodeCoverage()
function! phpqa#CodeCoverageToggle()
	if 0 != s:num_cc_signs
		let g:phpqa_codecoverage_autorun = 0
		call s:RemoveCodeCoverageSigns()
	else
		let g:phpqa_codecoverage_autorun = 1
		call phpqa#PhpCodeCoverage()
	endif
	
endf

" Remove code coverage markers
function s:RemoveCodeCoverageSigns()
	while 0 != s:num_cc_signs
		sign unplace 4783
		let s:num_cc_signs = s:num_cc_signs - 1
	endwhile
endf

" Run code coverage, and ask the user for the coverage file if not specified
function! phpqa#PhpCodeCoverage()
	call s:RemoveCodeCoverageSigns()

	let file_tmp = ""
	while 0 == len(g:phpqa_codecoverage_file)
		let file_tmp = resolve(expand(input("Please specify a clover code coverage XML file: ",file_tmp,"file")))
		if filereadable(file_tmp)
			let g:phpqa_codecoverage_file = file_tmp
		else
			echohl Error |echo "Not a valid or readable file"|echohl None
		endif
	endwhile
	execute "perl &AddCodeCoverageSigns('".g:phpqa_codecoverage_file."')"
endf
" }}}1
"=============================================================================
