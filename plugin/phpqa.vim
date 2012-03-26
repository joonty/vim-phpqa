" phpqa.vim -- 
" Run PHP analysis tools on the current file, including PHP lint, Code sniffer
" and mess detector.
" @Author:      Jon Cairns <jon@joncairns.com>
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     26-March-2012.
" @Revision:    0.1
"
if exists("g:phpqa_check")
	finish
endif

let g:phpqa_check = 1

if !exists("g:phpqa_codesniffer_cmd")
	let g:phpqa_codesniffer_cmd='phpcs --standard=Cake --report=emacs'
endif

if !exists("g:phpqa_messdetector_cmd")
	let g:phpqa_messdetector_cmd='phpmd'
endif

function! phpqa:RunCommands() 
	if &filetype == 'php'
		let retval=phpqa#PhpLint()
		if 0 == retval
			call phpqa#PhpCodeSniffer()
		endif
	endif	
endf

"autocmd BufWritePost *.php call PhpCodeSniffer()
autocmd BufWritePost * call phpqa:RunCommands()
