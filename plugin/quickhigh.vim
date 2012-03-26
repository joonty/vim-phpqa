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

let s:num_signs = 0
let s:signName = ""

"
" the following lets user's define their own signs
"

let v:errmsg = ""
silent! sign list QuickHighMakeError
if "" != v:errmsg
    sign define QuickHighMakeError linehl=Error text=ER texthl=Error
endif

let v:errmsg = ""
silent! sign list QuickHighMakeWarning
if "" != v:errmsg
    sign define QuickHighMakeWarning linehl=WarningMsg text=WR texthl=WarningMsg
endif

let v:errmsg = ""
silent! sign list QuickHighGrep
if "" != v:errmsg
    sign define QuickHighGrep linehl=tag text=GR texthl=tag
endif

" hopefully helpful user mappings
if !exists("no_plugin_maps") && !exists("no_quickhigh_maps")
    if !hasmapto('<Plug>QuickHighToggle', 'n')
        nmap <unique> <Leader>qt  <Plug>QuickHighToggle
    endif
    nnoremap <unique> <script> <Plug>QuickHighToggle <SID>QuickHighToggle
    nnoremap <silent> <SID>QuickHighToggle :call <SID>ToggleSigns()<cr>

    if !hasmapto('<Plug>QuickHighAdd', 'n')
        nmap <unique> <Leader>qa  <Plug>QuickHighAdd
    endif
    nnoremap <unique> <script> <Plug>QuickHighAdd <SID>QuickHighAdd
    nnoremap <silent> <SID>QuickHighAdd :call <SID>Init("prompt")<cr>

    if !hasmapto('<Plug>QuickHighRemove', 'n')
        nmap <unique> <Leader>qr  <Plug>QuickHighRemove
    endif
    nnoremap <unique> <script> <Plug>QuickHighRemove <SID>QuickHighRemove
    nnoremap <silent> <SID>QuickHighRemove :call <SID>RemoveSigns("discard")<cr>
endif

" wrapper commands to make error highlighting easier
if !exists("no_plugin_cmds") && !exists("no_quickhigh_cmds")
    command -nargs=* -bar Make call QuickHigh:RemoveSigns("discard")
        \   | make <args>
        \   | call QuickHigh:Init("QuickHighMakeError")
    command -nargs=* -bar Grep exe 'call QuickHigh:RemoveSigns("discard")|vimgrep <args>'
        \   | call QuickHigh:Init("QuickHighGrep")
endif


"
" Description:
" This routine allows the user to remove all signs and then add them back
" (i.e. toggle the state).  This could be useful if they want to inspect a
" line with the original syntax highlighting.
"
function s:ToggleSigns()
    if "" == s:signName
        echohl ErrorMsg | echo "You must first run :Make or :Grep." | echohl None
        return
    endif

    if "" == s:error_list
        return
    endif

    if 0 == s:num_signs
        call s:AddSignsWrapper("all")
    else
        call QuickHigh:RemoveSigns("keep")
    endif
endfunction

"
" Description:
" This routine will get rid of all the signs in all open buffers.
"
function QuickHigh:RemoveSigns(augroup)
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
function QuickHigh:Init(sign)
    " else we need to add the error signs
    if 0 != s:num_signs
        echohl ErrorMsg | echo "There are still signs leftover.  Try removing first." | echohl None
        return
    endif

    let sign = a:sign

    while "QuickHighMakeError" != sign && "QuickHighGrep" != sign
        if "QuickHighGrep" == s:signName
            let default = "Grep"
        else
            let default = "Make"
        endif

        let sign = input("What quickfix mode are you using (Make or Grep)? ", default)
        let sign = tolower(sign)
        if "make" == sign
            let sign = "QuickHighMakeError"
        elseif "grep" == sign
            let sign = "QuickHighGrep"
        else
            echo " "
            echo "Acceptable input is 'Make' or 'Grep'"
        endif
    endwhile

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
" QuickHighMakeWarning:/path/main.c:75:
" QuickHighMakeWarning:/path/main.c:70:
" QuickHighMakeError:/path/blue.c:7:
"
function s:ParseClist()
    " reset the error list
    let s:error_list = ""

    let sign = "QuickHighGrep"
    if "QuickHighGrep" != s:signName
        let sign = ""
    endif

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

            if "QuickHighGrep" != sign
                let sign = s:GetSign(strpart(s:clist, lend, (partend - lend)))
            endif

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
    if exists("b:quickhigh_error_re") && -1 != match(a:line, b:quickhigh_error_re)
        let sign = "QuickHighMakeError"
    elseif exists("b:quickhigh_warning_re") && -1 != match(a:line, b:quickhigh_warning_re)
        let sign = "QuickHighMakeWarning"
    else
        let sign = "QuickHighMakeError"
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

    if "QuickHighGrep" == s:signName
        call s:AddSignsActual(a:which, "QuickHighGrep")

    " this is how we give preference to errors if a line has both warnings and errors.
    else
        call s:AddSignsActual(a:which, "QuickHighMakeWarning")
        call s:AddSignsActual(a:which, "QuickHighMakeError")
    endif
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
        " echo "perl start: " . strftime("%c")
        execute "perl &AddSignsActual('" . a:which . "', '" . a:sign . "')"
        " echo "perl end: " . strftime("%c")
        return
    endif

    let add_ok  = 0
    let cur_buf = bufname("%")

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

            if "all" == a:which
                let add_ok = 1
            else
                if cur_buf == bufname(file)
                    let add_ok = 1
                endif
            endif

            " only add signs for files that are loaded
            if add_ok && "" != bufname(file)
                " echo "sign place 4782 name=" . sign . " line=" . line . " file=" . file
                execute "sign place 4782 name=" . sign . " line=" . line . " file=" . file
                let s:num_signs = s:num_signs + 1
                call setbufvar(bufname(file), "quickhigh_plugin_processed", 1)
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

" vim: ts=4 sw=4 et sts=4
