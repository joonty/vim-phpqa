" Description:
" Vim plugin that uses PHP qa tools and highlights the current file with
" syntax errors and coding standard violations.
"
" License:
"   GPL (http://www.gnu.org/licenses/gpl.txt)
"
" Authors:
" Jon Cairns <jon@joncairns.com>
"

" ------------------------------------------------------------------------------
" Exit when already loaded (or "compatible" mode set)
if exists("g:loaded_phpqa") || &cp
    finish
endif
let g:loaded_phpqa= 1
let s:keepcpo           = &cpo
set cpo&vim
let s:lineid = 9012
let s:numsigns = 0
let g:phpqa_num_cc_signs = 0

"=============================================================================
" PRIVATE FUNCTIONS {{{1

"
" Description:
" This function adds signs to the given buffer according to the contents of
" the error list.line.
"
function! s:AddSigns(buffer)
    for line in getloclist(0)
        if has_key(g:phpqa_sign_type_map,line.type)
            let l:name=g:phpqa_sign_type_map[line.type]
        else
            let l:name="GenericError"
        endif
        exec "sign place ".s:lineid." line=".line.lnum." name=".l:name." buffer=".a:buffer
        let s:numsigns = s:numsigns + 1
    endfor
endfunction

function! s:RemoveSigns()
    while s:numsigns > 0
        exec "sign unplace ".s:lineid
        let s:numsigns = s:numsigns - 1
    endwhile
endfunction

" Remove code coverage markers
function s:RemoveCodeCoverageSigns()
    while 0 != g:phpqa_num_cc_signs
        sign unplace 4783
        let g:phpqa_num_cc_signs = g:phpqa_num_cc_signs - 1
    endwhile
endfunction

" Combine error lists for codesniffer and messdetector
function s:CombineLists(phpcs_list,phpmd_list)

    if 0 != len(a:phpcs_list)
        let k = 0
        for val in a:phpcs_list
            let a:phpcs_list[k] = g:phpqa_codesniffer_type . " ". a:phpcs_list[k]." ".g:phpqa_codesniffer_append
            let k = k+1
        endfor
    endif
    if 0 != len(a:phpmd_list)
        let k = 0
        for val in a:phpmd_list
            let a:phpmd_list[k] = g:phpqa_messdetector_type." ".a:phpmd_list[k]." ".g:phpqa_messdetector_append
            let k = k+1
        endfor
    endif
    return a:phpcs_list + a:phpmd_list
endf
"1}}}
"=============================================================================

"=============================================================================
" GLOBAL FUNCTIONS {{{1

" Run the PHP linter to check for syntax errors
function! phpqa#PhpLint()
    if &filetype == "php"
        if 0 != len(g:phpqa_php_cmd)
            let l:bufNo = bufnr('%')
            call s:RemoveSigns()
            let l:php_output=system(g:phpqa_php_cmd." -l ".@%." 1>/dev/null")
            let l:php_list=split(l:php_output, "\n")

            if 0 != len(l:php_list) && match(l:php_list[0],"No syntax errors") == -1
                let l:php_list[0] = "P ".l:php_list[0]
                set errorformat=%t\ %m\ in\ %f\ on\ line\ %l
                lexpr l:php_list[0]
                call s:AddSigns(l:bufNo)
                lope
                return 1
            else
                if 1 == g:phpqa_verbose
                    echohl Error | echo "No syntax errors" | echohl None
                endif
                lgete []
                lcl
            endif
        elseif 1 == g:phpqa_verbose
            echohl Error | echo "PHP binary set to empty, not running lint" | echohl None
        endif
    endif
    return 0
endfunction

" Run PHP code sniffer.
function! phpqa#PhpCodeSniffer()
    if @% == ""
        echohl Error | echo "Invalid buffer (are you in the error window?)" |echohl None
        return []
    endif
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
    if @% == ""
        echohl Error | echo "Invalid buffer (are you in the error window?)" |echohl None
        return []
    endif
    " Run messdetector if the command hasn't been unset
    if 0 != len(g:phpqa_messdetector_cmd)
        let file_tmp = ""
        while 0 == len(g:phpqa_messdetector_ruleset)
            let file_tmp = input("Please specify a mess detector ruleset file, or built in rule: ",file_tmp)
            let g:phpqa_messdetector_ruleset = file_tmp
        endwhile
        let l:phpmd_output=system(g:phpqa_messdetector_cmd." ".@%." text ".g:phpqa_messdetector_ruleset)
        let l:phpmd_list=split(l:phpmd_output, "\n")
    else
        let l:phpmd_list = []
        echohl Error | echo "PHPMD binary set to empty, not running mess detector" | echohl None
    endif
    return l:phpmd_list
endf

" Run Code Sniffer and Mess Detector.
function! phpqa#PhpQaTools(runcs,runmd)
    let l:bufNo = bufnr('%')
    call s:RemoveSigns()

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
        set errorformat=%t\ %f:%l:%c:\ %m,%t\ %f:%l\	%m
        lgete error_list
        call s:AddSigns(l:bufNo)
        if g:phpqa_open_loc
            lope
        endif
    else
        lgete []
        lcl
    endif
endf

" Toggle the code coverage markers.
"
" If the command has been run, remove the signs. Otherwise run it with
" phpqa#PhpCodeCoverage()
function! phpqa#CodeCoverageToggle()
    if 0 != g:phpqa_num_cc_signs
        let g:phpqa_codecoverage_autorun = 0
        call s:RemoveCodeCoverageSigns()
    else
        let g:phpqa_codecoverage_autorun = 1
        call phpqa#PhpCodeCoverage()
    endif

endf

function! phpqa#QAToolsToggle()
    if g:phpqa_run_on_write == 1
        call s:RemoveSigns()
        let g:phpqa_run_on_write = 0
        echohl Error | echo "PHP QA tools won't run automatically on save" | echohl None
    else
        let g:phpqa_run_on_write = 1
        echohl Error | echo "PHP QA tools has been enabled" | echohl None
    endif
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
    call AddCodeCoverageSigns(g:phpqa_codecoverage_file)
endf
" }}}1
"=============================================================================
