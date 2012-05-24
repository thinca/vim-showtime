" Showtime by markdown!
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:source = {
\   'accept': ['.md', '.mkd', '.markdown'],
\ }

function! s:source.import(body)
  let pages = split(a:body, '\%(^\|\n\)\ze#\+\s*')
  let data = {'pages': []}
  for page in pages
    let [title, body] = matchlist(page, '\v^(.{-})%(\n|$)(.*)$')[1 : 2]
    let level = len(matchstr(page, '^#*'))
    let title = matchstr(title, '^#*\s*\zs.*')
    if level == 1
      let data.title = title
    endif
    " TODO: parse body
    let data.pages += [{
    \   'title': title,
    \   'body': body,
    \ }]
  endfor
  return data
endfunction

function! showtime#source#markdown#load()
  return s:source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
