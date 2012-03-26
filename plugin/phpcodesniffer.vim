" phpcodesniffer.vim -- Revisar los estándares de programación con
" PhpCodeSniffer 
" @Author:      Eduardo Magrané , basado en phpchecksyntax de Thomas Link (samul@web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     31-Oct-2009.
" @Last Change: .
" @Revision:    0.2.21
" @todo Aceptar parámetro de standard que se desea

if exists("g:php_check_codesniffer")
	finish
endif

let g:php_check_codesniffer = 1

if !exists("g:php_check_codesniffer_cmd")
	let g:php_check_codesniffer_cmd='phpcs --standard=Cake --report=emacs'
endif

function! PhpCodeSniffer()
	if &filetype == 'php'
		call phpqa#RemoveSigns("discard")
		let l:phpcs_output=system(g:php_check_codesniffer_cmd." ".@%)
		let l:phpcs_list=split(l:phpcs_output, "\n")
		set errorformat=%f:%l:%c:\ %m
		cexpr l:phpcs_list
		cope
		call phpqa#Init("CodeSnifferError")
	endif
endf

noremap   :call PhpCodeSniffer()
inoremap   :call PhpCodeSniffer() 

autocmd BufWritePost *.php call PhpCodeSniffer()

sign define CodeSnifferError linehl=Error text=CS texthl=Error
