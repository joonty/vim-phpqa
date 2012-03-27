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

if 0 == has("signs")
    echohl ErrorMsg | echo "I'm sorry, phpqa needs a vim with +signs." | echohl None
    finish
endif

if has("perl")
    source <sfile>:p:h/perl/quickhigh.vim
endif

if !hasmapto('<Plug>QuickHighToggle', 'n')
nmap <unique> <Leader>qa  <Plug>QuickHighToggle
endif
nnoremap <unique> <script> <Plug>QuickHighToggle <SID>QuickHighToggle
nnoremap <silent> <SID>QuickHighToggle :call phpqa#ToggleSigns()<cr>

" Most of quickhigh has now been added to the autoload file
"
let g:sign_codesniffererror = "(PHP_CodeSniffer)"
sign define CodeSnifferError linehl=WarningMsg text=C  texthl=WarningMsg
let g:sign_messdetectorerror = "(PHPMD)"
sign define MessDetectorError linehl=WarningMsg text=M  texthl=WarningMsg
let g:sign_phperror = "(PHP)"
sign define PhpError linehl=Error text=P texthl=Error
