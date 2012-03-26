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
    echohl ErrorMsg | echo "I'm sorry, quickhigh needs a vim with +signs." | echohl None
    finish
endif

if has("perl")
    source <sfile>:p:h/perl/quickhigh.vim
endif

"
" hopefully helpful user mappings
if !exists("no_plugin_maps") && !exists("no_quickhigh_maps")
    if !hasmapto('<Plug>QuickHighToggle', 'n')
        nmap <unique> <Leader>qt  <Plug>QuickHighToggle
    endif
    nnoremap <unique> <script> <Plug>QuickHighToggle <SID>QuickHighToggle
    nnoremap <silent> <SID>QuickHighToggle :call phpqa#ToggleSigns()<cr>

    if !hasmapto('<Plug>QuickHighAdd', 'n')
        nmap <unique> <Leader>qa  <Plug>QuickHighAdd
    endif
    nnoremap <unique> <script> <Plug>QuickHighAdd <SID>QuickHighAdd
    nnoremap <silent> <SID>QuickHighAdd :call phpqa#Init("prompt")<cr>

    if !hasmapto('<Plug>QuickHighRemove', 'n')
        nmap <unique> <Leader>qr  <Plug>QuickHighRemove
    endif
    nnoremap <unique> <script> <Plug>QuickHighRemove <SID>QuickHighRemove
    nnoremap <silent> <SID>QuickHighRemove :call phpqa#RemoveSigns("discard")<cr>
endif

" wrapper commands to make error highlighting easier
if !exists("no_plugin_cmds") && !exists("no_quickhigh_cmds")
    command -nargs=* -bar Make call phpqa#RemoveSigns("discard")
        \   | make <args>
        \   | call phpqa#Init("QuickHighMakeError")
    command -nargs=* -bar Grep exe 'call phpqa#RemoveSigns("discard")|vimgrep <args>'
        \   | call phpqa#Init("QuickHighGrep")
endif

" Most of quickhigh has now been added to the autoload file
