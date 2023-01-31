fu! s:getfile(fname)
  return expand('$VIMRUNTIME') .'\pack\my-nvim\opt\my-files\markdown-tohtmlpdf\' .a:fname
endfu

fu! markdownToHtmlPDF#md2HtmlPDF()
  if &filetype == 'markdown'
    let cur_p = expand("%:p")
    call ipython#runHide(
          \ 'cd ' .expand("%:p:h")
          \ )
    call ipython#runHide(
          \ '%run '
          \ .markdownUtils#fileAndParams(s:getfile('main.py'),
          \ [cur_p,
          \  s:getfile('hl.css'),
          \  s:getfile('extra.css'),
          \  s:getfile('rd.js'),
          \  s:getfile('requirements.txt'),
          \ ]))
  endif
endfu

fu! markdownToHtmlPDF#deleteFileTypeOf(file_types=['html', 'pdf', 'docx'])
  let folder_path = expand("%:p:h")
  let file_types = a:file_types
  python3 << EOF
import os
import vim
folder_path = vim.eval('folder_path')
file_types = vim.eval('file_types')
for f in os.listdir(folder_path):
  f = os.path.join(folder_path, f)
  if os.path.isfile(f) and any([file_type in f.split('.')[-1] for file_type in file_types]):
    os.remove(f)
    print(f)
EOF
endfu
