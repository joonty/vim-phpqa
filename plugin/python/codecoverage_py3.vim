function! AddCodeCoverageSigns(clover)
    if has('python3')
python3 << EOF
import lxml.etree
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
fileName = vim.eval('fnamemodify("'+buf+'","%")')

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
                doc = None
    except NameError:
        doc = None

    " t0 = time.time() "

    if doc is None:
        doc = lxml.etree.parse(clover)
        mtime = time.ctime(os.path.getmtime(clover))

    #ctxt = doc.xpathNewContext()
    #res = ctxt.xpathEval("//file[substring(@name, string-length(@name) - string-length('"+fileName+"') + 1)='"+fileName+"']/line[@type='stmt']")
    res = doc.xpath("//file[substring(@name, string-length(@name) - string-length('"+fileName+"') + 1)='"+fileName+"']/line[@type='stmt']")
    cur_signs = int(vim.eval('g:phpqa_num_cc_signs'))
    showcovered = int(vim.eval('g:phpqa_codecoverage_showcovered'))
    cmd_list = ''

    for node in res:
        lnum = node.attrib['num']
        cnt = int(node.attrib['count'])
        if showcovered == 0 and cnt > 0:
            continue
        cur_signs += 1
        sign = "CodeCoverageCovered" if cnt > 0 else "CodeCoverageNotCovered"
        cmd_list += 'exec "sign place 4783 name='+sign+' line='+lnum+' file='+fileName+'" | '

    vim.command(cmd_list)
    vim.command('let g:phpqa_num_cc_signs='+str(cur_signs))

except os.error:
    vim.command('echohl Error | echo "Missing or inaccessible code coverage file" | echohl None')
except Exception as e:
    vim.command('echohl Error | echo "An error has occured while parsing the code coverage file" | echohl None')

EOF
    else
        echohl Error | echo "Code coverage support for PHPQA requires Vim with Python3" | echohl None
    endif
endfunction
