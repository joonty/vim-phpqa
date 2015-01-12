"-------------------------------------------------
" PHP QA tools for Vim                        {{{
"
" Description:
" Vim plugin that uses PHP qa tools and highlights the current file with
" syntax errors and coding standard violations.
"
" License:
"   MIT (https://raw.githubusercontent.com/joonty/vim-phpqa/master/LICENSE)
"
" Authors:
" Jon Cairns <jon@joncairns.com>
"
" }}}
"-------------------------------------------------

if exists("g:phpqa_check")
    finish
endif

if 0 == has("signs")
    echohl ErrorMsg | echo "I'm sorry, phpqa needs a vim with +signs." | echohl None
    finish
endif

let $CUR_DIRECTORY=expand("<sfile>:p:h")
source $CUR_DIRECTORY/python/codecoverage.vim

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
    let g:phpqa_codesniffer_args=""
endif

" PHPMD binary (mess detector)
if !exists("g:phpqa_messdetector_cmd")
    let g:phpqa_messdetector_cmd='phpmd'
endif

" Rule set built-in or XML file for mess detector, comma separated
if !exists("g:phpqa_messdetector_ruleset")
    let g:phpqa_messdetector_ruleset="codesize,unusedcode,naming"
endif

" Clover code coverage file
if !exists("g:phpqa_codecoverage_file")
    let g:phpqa_codecoverage_file = ""
endif

" Whether to automatically show code coverage on file load
if !exists("g:phpqa_codecoverage_autorun")
    let g:phpqa_codecoverage_autorun = 0
endif

" Whether to show signs for covered code (or only not covered)
" It may speed things up to turn this off
if !exists("g:phpqa_codecoverage_showcovered")
    let g:phpqa_codecoverage_showcovered = 1
endif

" Whether to show signs for covered code (or only not covered)
" It may speed things up to turn this off
if !exists("g:phpqa_codecoverage_regex")
    let g:phpqa_codecoverage_showcovered = 1
endif

" Whether to automatically run codesniffer when saving a file
if !exists("g:phpqa_codesniffer_autorun")
    let g:phpqa_codesniffer_autorun = 1
endif

" Whether to automatically run messdetector when saving a file
if !exists("g:phpqa_messdetector_autorun")
    let g:phpqa_messdetector_autorun = 1
endif

" Whether qa tools should run on buffer write
if !exists("g:phpqa_run_on_write")
    let g:phpqa_run_on_write = 1
endif

" Whether to open the location list automatically with CodeSniffer/Mess
" detector violations
if !exists("g:phpqa_open_loc")
    let g:phpqa_open_loc = 1
endif


" Run all QA tools
function! PhpqaRunAll()
    if &filetype == 'php'
        " Check syntax valid before running others
        let retval=Phpqa#PhpLint()
        if 0 == retval && 1 == g:phpqa_run_on_write
            call Phpqa#PhpQaTools(g:phpqa_codesniffer_autorun,g:phpqa_messdetector_autorun)
        endif
    endif
endf

" Run code coverage
function! PhpqaRunCodeCoverage()
    if &filetype == 'php'
        if "" != g:phpqa_codecoverage_file && 1 == g:phpqa_codecoverage_autorun
            call Phpqa#PhpCodeCoverage()
        endif
    endif
endf

if !hasmapto('<Plug>CodeCoverageToggle', 'n')
    nmap <unique> <Leader>qc  <Plug>CodeCoverageToggle
endif
nnoremap <unique> <script> <Plug>CodeCoverageToggle <SID>CodeCoverageToggle
nnoremap <silent> <SID>CodeCoverageToggle :call Phpqa#CodeCoverageToggle()<cr>

" Run all tools automatically on write and other events
if g:phpqa_run_on_write
    autocmd BufWritePost * call PhpqaRunAll()
    autocmd BufRead * call Phpqa#PhpLint()
    autocmd BufRead * call PhpqaRunCodeCoverage()
endif

" Allow each command to be called individually
command Php call Phpqa#PhpLint()
command Phpcs call Phpqa#PhpQaTools(1,0)
command Phpmd call Phpqa#PhpQaTools(0,1)
command Phpcc call Phpqa#PhpCodeCoverage()


if !hasmapto('<Plug>QAToolsToggle', 'n')
    nmap <unique> <Leader>qa  <Plug>QAToolsToggle
endif
nnoremap <unique> <script> <Plug>QAToolsToggle <SID>QAToolsToggle
nnoremap <silent> <SID>QAToolsToggle :call Phpqa#QAToolsToggle()<cr>

" Code sniffer sign config
let g:phpqa_codesniffer_append = "(PHP_CodeSniffer)"
let g:phpqa_codesniffer_type = "S"
sign define CodeSnifferError linehl=WarningMsg text=S>  texthl=WarningMsg

" Mess detector sign config
let g:phpqa_messdetector_append = "(PHPMD)"
let g:phpqa_messdetector_type = "M"
sign define MessDetectorError linehl=WarningMsg text=M>  texthl=WarningMsg

" PHP error sign config
let g:phpqa_php_append = "(PHP)"
let g:phpqa_php_type = "P"
sign define PhpError linehl=Error text=P> texthl=Error

" Generic error sign
sign define GenericError linehl=Error text=U> texthl=Error

" Code coverage sign config
sign define CodeCoverageCovered text=C>  texthl=Cursor
sign define CodeCoverageNotCovered text=C>  texthl=Error

let g:phpqa_sign_type_map = {'S':"CodeSnifferError",'M':"MessDetectorError",'P':"PhpError"}
