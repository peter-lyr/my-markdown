fu! s:base()
  let s:date = strftime('%Y\%m\%d\')
  let s:lineNr = line('.')
  let s:bufAbspath = expand('%:p')
  call writefile([''], markdownImage#pipe(), 'b')
endfu

fu! s:waitBs64AndPasteBuf()
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

fu! markdownImageReduce#do()
  call <sid>base()
  let ss = matchlist(getline('.'), '!\[\(.\+\)\](\(.\+\))')
  try
    call writefile([ss[1] .'|' .ss[2]], markdownImage#bs64(), 'b')
    call ipython#runHide(
          \ '%run '
          \ .markdownUtils#fileAndParams(markdownImage#getusedfile('bs64ToJpg.py'),
          \ [
          \   markdownImage#bs64(),
          \   markdownImage#jpg(),
          \   markdownImage#pipe(),
          \ ]))
    call <sid>waitBs64AndPasteBuf()
  catch
  endtry
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
      norm vzf
    else
      ec content
    endif
    call powershell#hide()
  endif
endfu

fu! markdownImageReduce#reduceLevelDo(text)
  try
    let aa = split(trim(a:text), ' ')
    let s:scale = eval(aa[0]) / 100.0
    let s:level = eval(aa[1])
  catch
  endtry
  if s:scale < 0.01
    let s:scale = 0.01
  elseif s:scale >= 1
    let s:scale = 1
  endif
  if s:level < 2
    let s:level = 2
  elseif s:level > 31
    let s:level = 31
  endif
  ec string(s:scale) .', ' .string(s:level)
endfu

fu! s:do(text)
  let tmp = [printf('call markdownImageReduce#reduceLevelDo("%s")', a:text)]
  call setline('.', tmp)
  1000wincmd -
  2wincmd +
  norm zz
endfu
fu! markdownImageReduce#reduceLevel()
  call feedkeys(":\<c-f>")
  call timer_start(10, { -> <sid>do(
        \ join([string(float2nr(s:scale * 100)), string(s:level)], ' ')) })
endfu

fu! markdownImageReduce#showReduceLevel()
  echomsg '[0.01~1] [2~31] ' .string(s:scale) .' ' .string(s:level)
endfu

let s:scale = 0.61
let s:level = 2
