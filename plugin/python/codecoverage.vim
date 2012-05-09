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
    doc
    if doc != None:
        cmtime = time.ctime(os.path.getmtime(clover))
        if cmtime > mtime:
            doc.freeDoc()
            doc = None
except NameError:
    doc = None

if doc is None:
    doc = libxml2.parseFile(clover)
    mtime = time.ctime(os.path.getmtime(clover))
    
ctxt = doc.xpathNewContext()
res = ctxt.xpathEval("/coverage/project/file[@name='"+fileName+"']/line[@type='stmt']")

for node in res:
    ctxt.setContextNode(node)
    lnum = node.prop('num')
    cnt = int(node.prop('count'))
    sign = "CodeCoverageCovered" if cnt > 0 else "CodeCoverageNotCovered"
    vim.command('let g:phpqa_num_cc_signs = g:phpqa_num_cc_signs + 1')
    vim.command('sign place 4783 name='+sign+' line='+lnum+' file='+fileName)

ctxt.xpathFreeContext()

EOF
    else
        echohl Error | echo "Code coverage support for PHPQA requires Vim compiled with Python" | echohl None
    endif
endfunction
