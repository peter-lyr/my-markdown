let s:repoName = 'mediaFirst'
fu! markdownImageGet#imageRepoName(print=1)
  if a:print
    echomsg s:repoName
  endif
  return s:repoName
endfu

fu! s:base()
  let s:date = strftime('%Y\%m\%d\')
  let s:lineNr = line('.')
  let s:bufAbspath = expand('%:p')
  call writefile([''], markdownImage#pipe(), 'b')
endfu

fu! markdownImageGet#scales(A,L,P)
  let ret = []
  for i in s:scales
    let ret += [string(float2nr(i*100))]
  endfor
  return ret
endfun

fu! markdownImageGet#levels(A,L,P)
  let ret = []
  for i in s:levels
    let ret += [string(i)]
  endfor
  return ret
endfun

fu! s:waitBs64AndPasteBuf(default)
  if a:default
    let scale = s:scaleDefault
    let level = s:levelDefault
  else
    let scale = input(printf('尺寸1~100，默认%s: ', float2nr(s:scaleDefault*100)),
          \ string(float2nr(s:scale*100)), 'customlist,markdownImageGet#scales')
    if len(scale) == 0
      return
    endif
    try
      let scale = eval(scale) / 100.0
      if scale < 0.01
        let scale = 0.01
      elseif scale > 1.0
        let scale = 1.0
      endif
      if scale != s:scale
        let s:scales += [scale]
      endif
      let s:scale = scale
    catch
      echomsg '输入非数字："' .scale .'"'
      return
    endtry
    let level = input(printf('级别2~31，2最高，建议8或18，默认%s: ', s:levelDefault),
          \ string(s:level), 'customlist,markdownImageGet#levels')
    if len(level) == 0
      return
    endif
    try
      let level = float2nr(eval(level))
      if level < 2
        let level = 2
      elseif level > 31
        let level = 31
      endif
      if level != s:level
        let s:levels += [level]
      endif
      let s:level = level
    catch
      echomsg '输入非数字："' .level .'"'
      return
    endtry
  endif
  call ipython#runHide('%run '
        \ .markdownUtils#fileAndParams(markdownImage#getusedfile('reduceImageToBs64.py'),
        \ [
        \   markdownImage#pipe(),
        \   markdownImage#reducejpg(),
        \   markdownImage#bs64(),
        \   string(s:scale),
        \   string(s:level),
        \ ]))
  let s:waitBs64Timer = timer_start(10, { -> <sid>pasteBs64ToBuf(
        \ s:bufAbspath, markdownImage#bs64(), markdownImage#pipe()) }, {'repeat' : -1})
endfu

fu! markdownImageGet#homeReposFolder()
  return $HOMEDRIVE .$HOMEPATH .'\repos'
endfu

fu! markdownImageGet#touchRepoDateFolder(repoNameInRepos, subDir)
  let date = strftime('%Y\%m\%d\')
  if !isdirectory(markdownImageGet#homeReposFolder() .'\' .a:repoNameInRepos)
    call system(markdownUtils#systemCd(markdownImageGet#homeReposFolder())
          \ .' && git clone https://gitee.com/peter-lyr/'
          \ .a:repoNameInRepos)
  endif
  let abspath = markdownImageGet#homeReposFolder() .'\' .a:repoNameInRepos .'\' .a:subDir .'\'
  if !isdirectory(abspath)
    call system('mkdir ' .abspath)
  endif
  let abspath = abspath .date
  if !isdirectory(abspath)
    call system('mkdir ' .abspath)
  endif
  return abspath
endfu

fu! markdownImageGet#pushPng(repoName, subDir, default=1)
  call <sid>base()
  let pushAbspath = markdownImageGet#touchRepoDateFolder(a:repoName, a:subDir)
  call powershell#runShow(
        \ markdownUtils#fileAndParams(markdownImage#getusedfile('clipboardImagePushPng.ps1'),
        \ [
        \   pushAbspath,
        \   markdownImage#pipe(),
        \ ]))
  call <sid>waitBs64AndPasteBuf(a:default)
endfu

fu! markdownImageGet#pushJpg(repoName, subDir, default=1)
  call <sid>base()
  let pushAbspath = markdownImageGet#touchRepoDateFolder(a:repoName, a:subDir)
  call powershell#runShow(
        \ markdownUtils#fileAndParams(markdownImage#getusedfile('clipboardImagePushJpg.ps1'),
        \ [
        \   pushAbspath,
        \   markdownImage#pipe(),
        \ ]))
  call <sid>waitBs64AndPasteBuf(a:default)
endfu

fu! markdownImageGet#justBs64(default=1)
  call <sid>base()
  call powershell#runHide(
        \ markdownUtils#fileAndParams(markdownImage#getusedfile('clipboardImageJustBs64.ps1'),
        \ [
        \   markdownImage#jpg(),
        \   markdownImage#pipe(),
        \ ]))
  call <sid>waitBs64AndPasteBuf(a:default)
endfu

fu! s:pasteBs64ToBuf(bufAbspath, bs64Abspath, pipeAbspath)
  let content = readfile(a:pipeAbspath)
  let content = join(content, '\n')
  if match(content, 'SUCCESS') != -1 || match(content, 'FAIL') != -1
    call writefile([''], a:pipeAbspath, 'b')
    call timer_stop(s:waitBs64Timer)
    if match(content, 'SUCCESS') != -1
      let imageName = split(content, '|')[-1]
      if !markdownImage#go(a:bufAbspath)
        new
        exec 'e ' .a:bufAbspath
      endif
      let content = readfile(a:bs64Abspath)[0]
      call setline(s:lineNr, '![' .s:date .imageName .'](' .content .')')
      exec "norm " .string(s:lineNr) .'gg'
      " norm vzf
    else
      ec content
    endif
    call powershell#hide()
  endif
endfu

fu! markdownImageGet#showReduceLevel()
  echomsg '[0.01~1.0] [2~31] ' .string(s:scale) .' ' .string(s:level)
endfu

fu! markdownImageGet#justBs64Manual()
  call markdownImageGet#justBs64(0)
endfu

let s:scaleDefault = 1.0
let s:levelDefault = 8
if !exists('s:scale')
  let s:scale = 1.0
endif
if !exists('s:level')
  let s:level = 8
endif
if !exists('s:scales')
  let s:scales = [s:scale]
endif
if !exists('s:levels')
  let s:levels = [s:level]
endif

fu! markdownImageGet#pushdo(a)
  let [q, dir] = split(a:a, '::')
  if q == 'jpg'
    call markdownImageGet#pushJpg(markdownImageGet#imageRepoName(0), dir)
  else
    call markdownImageGet#pushPng(markdownImageGet#imageRepoName(0), dir)
  endif
endfu
fu! markdownImageGet#push()
  call telescope_extension#sel(
        \ '图片提交到仓库' .markdownImageGet#imageRepoName(0),
        \ s:pushList,
        \ 'markdownImageGet#pushdo',
        \ )
endfu
let s:pushList = [
      \ 'jpg::work',
      \ 'png::work',
      \ 'jpg::thought',
      \ 'png::thought',
      \ ]
