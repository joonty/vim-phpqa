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

if exists("g:phpqa_check")
	finish
endif

if 0 == has("signs")
    echohl ErrorMsg | echo "I'm sorry, phpqa needs a vim with +signs." | echohl None
    finish
endif

if has("perl")
    source <sfile>:p:h/perl/quickhigh.vim
endif

let g:phpqa_check = 1

" Give more feedback about commands
let g:phpqa_verbose = 0

" PHP binary
if !exists("g:phpqa_php_cmd")
	let g:phpqa_php_cmd='php'
endif

" PHPCS binary (PHP_CodeSniffer)
if !exists("g:phpqa_codesniffer_cmd")
	let g:phpqa_codesniffer_cmd='phpcs'
endif

" Arguments to pass to code sniffer, e.g standard name
if !exists("g:phpqa_codesniffer_args")
	let g:phpqa_codesniffer_args="--standard=PHPCS"
endif

" PHPMD binary (mess detector)
if !exists("g:phpqa_messdetector_cmd")
	let g:phpqa_messdetector_cmd='phpmd'
endif

" Rule set XML file for mess detector
if !exists("g:phpqa_messdetector_ruleset")
	let g:phpqa_messdetector_ruleset=""
endif

" Clover code coverage file
if !exists("g:phpqa_codecoverage_file") 
	let g:phpqa_codecoverage_file = ""
endif

" Whether to automatically show code coverage on file load
if !exists("g:phpqa_codecoverage_autorun")
	let g:phpqa_codecoverage_autorun = 0
endif

" Whether to automatically run codesniffer when saving a file
if !exists("g:phpqa_codesniffer_autorun")
	let g:phpqa_codesniffer_autorun = 1
endif

" Whether to automatically run messdetector when saving a file
if !exists("g:phpqa_messdetector_autorun")
	let g:phpqa_messdetector_autorun = 1
endif

" Run all QA tools
function! phpqa:RunAll() 
	if &filetype == 'php'
		" Check syntax valid before running others
		let retval=phpqa#PhpLint()
		if 0 == retval
			call phpqa#PhpQaTools(g:phpqa_codesniffer_autorun,g:phpqa_messdetector_autorun)
		endif
	endif	
endf

" Run code coverage
function! phpqa:RunCodeCoverage()
	if &filetype == 'php'
		if "" != g:phpqa_codecoverage_file && 1 == g:phpqa_codecoverage_autorun
			call phpqa#PhpCodeCoverage()
		endif
	endif
endf

if !hasmapto('<Plug>CodeCoverageToggle', 'n')
nmap <unique> <Leader>qc  <Plug>CodeCoverageToggle
endif
nnoremap <unique> <script> <Plug>CodeCoverageToggle <SID>CodeCoverageToggle
nnoremap <silent> <SID>CodeCoverageToggle :call phpqa#CodeCoverageToggle()<cr>

" Run all tools automatically on write
autocmd BufWritePost * call phpqa:RunAll()
autocmd BufRead * call phpqa:RunCodeCoverage()

" Allow each command to be called individually
command Php call phpqa#PhpLint()
command Phpcs call phpqa#PhpQaTools(1,0)
command Phpmd call phpqa#PhpQaTools(0,1)
command Phpcc call phpqa#PhpCodeCoverage()


if !hasmapto('<Plug>QuickHighToggle', 'n')
nmap <unique> <Leader>qa  <Plug>QuickHighToggle
endif
nnoremap <unique> <script> <Plug>QuickHighToggle <SID>QuickHighToggle
nnoremap <silent> <SID>QuickHighToggle :call phpqa#ToggleSigns()<cr>

" Most of quickhigh has now been added to the autoload file
"
let g:sign_codesniffererror = "(PHP_CodeSniffer)"
sign define CodeSnifferError linehl=WarningMsg text=S>  texthl=WarningMsg
let g:sign_messdetectorerror = "(PHPMD)"
sign define MessDetectorError linehl=WarningMsg text=M>  texthl=WarningMsg
let g:sign_phperror = "(PHP)"
sign define PhpError linehl=Error text=P> texthl=Error
sign define CodeCoverageCovered text=C>  texthl=Error
sign define CodeCoverageNotCovered text=C>  texthl=Cursor
