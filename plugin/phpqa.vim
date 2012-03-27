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

function! phpqa:RunAll() 
	if &filetype == 'php'
		" Check syntax valid before running others
		let retval=phpqa#PhpLint()
		if 0 == retval
			call phpqa#PhpQaTools(1,1)
		endif
	endif	
endf

" Run all tools automatically on write
autocmd BufWritePost * call phpqa:RunAll()

" Allow each command to be called individually
command Php call phpqa#PhpLint()
command Phpcs call phpqa#PhpQaTools(1,0)
command Phpmd call phpqa#PhpQaTools(0,1)
