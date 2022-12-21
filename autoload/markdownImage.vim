let s:temp = $HOMEDRIVE .$HOMEPATH .'\temps'

if !isdirectory(s:temp)
  call system(printf('mkdir %s', s:temp))
endif

let s:tempsub = s:temp .'\markdown-image'

if !isdirectory(s:tempsub)
  call system(printf('mkdir %s', s:tempsub))
endif

fu! markdownImage#bs64()
  return s:tempsub .'\bs64.md'
endfu

fu! markdownImage#jpg()
  return s:tempsub .'\tmp.jpg'
endfu

fu! markdownImage#pipe()
  return s:tempsub .'\pipe.txt'
endfu

fu! markdownImage#reducejpg()
  return s:tempsub .'\reduce.jpg'
endfu

fu! markdownImage#getusedfile(fname)
  return expand('$VIMRUNTIME') .'\pack\my-nvim\opt\my-files\markdown-image\' .a:fname
endfu

fu! s:escape(abspath)
  return substitute(a:abspath, '/', '\', 'g')
endfu

fu! markdownImage#go(abspath)
  let go = 0
  for tabIndex in range(1, tabpagenr('$'))
    let bufs = tabpagebuflist(tabIndex)
    for winIndex in range(len(bufs))
      let bufNr = bufs[winIndex]
      if nvim_buf_is_valid(bufNr)
        if s:escape(nvim_buf_get_name(bufNr)) == s:escape(a:abspath)
          call win_gotoid(win_getid(winIndex+1, tabIndex))
          let go = 1
          break
        endif
      endif
    endfor
  endfor
  return go
endfu

fu! markdownImage#do(a)
  exec printf("call %s()", s:dict[a:a])
endfu

fu! markdownImage#sel()
  if &ft != 'markdown'
    return
  endif
  call telescope_extension#sel('图片剪切板', sort(keys(s:dict)),
        \ "markdownImage#do"
        \ )
endfu

let s:dict = {
      \ "Bs64 Generate(default) & push": "markdownImageGet#push",
      \ "Bs64 Generate(default)": "markdownImageGet#justBs64",
      \ "Bs64 Generate(manual)": "markdownImageGet#justBs64Manual",
      \ "Bs64 Reduce Cur": "markdownImageReduce#do",
      \ "Image Repo Show": "markdownImageGet#imageRepoName",
      \ "PDF Delete": "markdownToHtmlPDF#deleteFileTypeOf",
      \ "PDF Generate": "markdownToHtmlPDF#md2HtmlPDF",
      \ "scale & level Modify": "markdownImageReduce#reduceLevel",
      \ "scale & level Show Image": "markdownImageGet#showReduceLevel",
      \ "scale & level Show Reduce": "markdownImageReduce#showReduceLevel",
      \ }
