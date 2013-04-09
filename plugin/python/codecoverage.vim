function! AddCodeCoverageSigns(clover)
    if has('python')
python << EOF
import libxml2
import vim
import os.path
import time

global doc
global mtime

try:
    mtime
except NameError:
    mtime = 0

clover = vim.eval('a:clover')
buf = vim.eval('bufname("%")')
fileName = vim.eval('fnamemodify("'+buf+'",":p")')

"""
XML may already be parsed and held in memory
Check the file modification time, and only re-parse
if it's been modified.
"""
try:
    try:
        doc
        if doc != None:
            cmtime = time.ctime(os.path.getmtime(clover))
            if cmtime > mtime:
                doc.freeDoc()
                doc = None
    except NameError:
        doc = None

    " t0 = time.time() "

    if doc is None:
        doc = libxml2.parseFile(clover)
        mtime = time.ctime(os.path.getmtime(clover))

    ctxt = doc.xpathNewContext()
    res = ctxt.xpathEval("//file[@name='"+fileName+"']/line[@type='stmt']")
    cur_signs = int(vim.eval('g:phpqa_num_cc_signs'))
    showcovered = int(vim.eval('g:phpqa_codecoverage_showcovered'))
    cmd_list = ''

    for node in res:
        ctxt.setContextNode(node)
        lnum = node.prop('num')
        cnt = int(node.prop('count'))
        if showcovered == 0 and cnt > 0:
            continue
        cur_signs += 1
        sign = "CodeCoverageCovered" if cnt > 0 else "CodeCoverageNotCovered"
        cmd_list += 'exec "sign place 4783 name='+sign+' line='+lnum+' file='+fileName+'" | '

    vim.command(cmd_list)
    vim.command('let g:phpqa_num_cc_signs='+str(cur_signs))

    """
    t = time.time() - t0
    print "Completed in "+str(t)+" seconds"
    """

    ctxt.xpathFreeContext()

except os.error:
    vim.command('echohl Error | echo "Missing or inaccessible code coverage file" | echohl None')
except:
    vim.command('echohl Error | echo "An error has occured while parsing the code coverage file" | echohl None')

EOF
    else
        echohl Error | echo "Code coverage support for PHPQA requires Vim compiled with Python" | echohl None
    endif
endfunction
