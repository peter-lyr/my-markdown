fu! markdownUtils#fileAndParams(fname, params)
  let params = a:params
  if type(a:params) == v:t_string
    let params = [params]
  elseif type(a:params) == v:t_list
  else
    return
  endif
  let param = ''
  for p in params
    let param .= ' "'
    let param .= substitute(p, '"', '_', 'g')
    let param .= '"'
  endfor
  return a:fname .' ' .param
endfu

fu! markdownUtils#systemCd(absfolder)
  if !isdirectory(a:absfolder)
    return ''
  endif
  return a:absfolder[0] .': && cd ' .a:absfolder
endfu
