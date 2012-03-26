" Description:
" Vim plugin for highlighting errors that have been defined from
" ':clist'.
"
" Version:
"   $Revision: 2.00 $
"   $Date: 20012/03/26 01:34:59 $
"
" Authors:
" Brian Medley <freesoftware@4321.tv> (Original)
" Jon Cairns <jon@joncairns.com>
"
" Modifications:
" Made some functions global to allow calling from other scripts.
"


if 0 == has("signs")
    echohl ErrorMsg | echo "I'm sorry, phpqa needs a vim with +signs." | echohl None
    finish
endif

if has("perl")
    source <sfile>:p:h/perl/quickhigh.vim
endif

if !exists("no_plugin_maps") && !exists("no_quickhigh_maps")
    if !hasmapto('<Plug>QuickHighToggle', 'n')
        nmap <unique> <Leader>qa  <Plug>QuickHighToggle
    endif
    nnoremap <unique> <script> <Plug>QuickHighToggle <SID>QuickHighToggle
    nnoremap <silent> <SID>QuickHighToggle :call phpqa#ToggleSigns()<cr>
endif

" Most of quickhigh has now been added to the autoload file
"
let g:sign_codesniffererror = "(PHP_CodeSniffer)"
sign define CodeSnifferError linehl=WarningMsg text=C  texthl=WarningMsg
let g:sign_messdetectorerror = "(PHPMD)"
sign define MessDetectorError linehl=WarningMsg text=M  texthl=WarningMsg
let g:sign_phperror = "(PHP)"
sign define PhpError linehl=Error text=P texthl=Error
