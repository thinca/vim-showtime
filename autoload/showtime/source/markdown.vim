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
  let pages = split(a:body, '\%(^\|\n\+\)\ze#\+\s*')
  let data = {'pages': []}
  if !empty(pages) && pages[0] !~# '^#'
    let header = remove(pages, 0)
    call extend(data, s:parse_header(header), 'keep')
  endif
  for page_data in pages
    let page = s:parse_page(page_data)
    if !has_key(data, 'title') && has_key(page, 'title')
      let data.title = page.title
    endif
    let data.pages += [page]
  endfor
  return data
endfunction

function! s:parse_header(header)
  " Temporary specs.
  let data = {}
  for attr in split(a:header, "\n")
    let [name, value] = matchlist(attr, '^\(\w*\)\s*\(.*\)$')[1 : 2]
    if name !=# ''
      let data[name] = value
    endif
  endfor
  return data
endfunction
function! s:parse_page(page)
  let [title, body] = matchlist(a:page, '\v^(.{-})%(\n|$)\n*(.*)$')[1 : 2]
  let level = len(matchstr(a:page, '^#*'))
  let title = matchstr(title, '^#*\s*\zs.*')
  let layout = title ==# '' ? 'body':
  \            body  ==# '' ? 'title':
  \                           'page'
  if level == 1
    let layout = 'title'
  endif
  " TODO: parse body
  return {
  \   'title': title,
  \   'body': body,
  \   'layout': layout,
  \   'segments': s:parse_body(body),
  \ }
endfunction
function! s:parse_body(body)
  let segments = []
  let body = a:body
  while body !=# ''
    if body =~# '^```'
      let [seg, body] = s:parse_code_block(body)
    elseif body =~# '^\%(    \|\t\)'
      let [seg, body] = s:parse_block(body)
    else
      let [seg, body] = matchlist(body, '\v^(.{-})%(\n\s*\n(.*)|$)')[1 : 2]
    endif
    let segments += [seg]
    unlet seg
  endwhile
  return segments
endfunction
function! s:parse_code_block(body)
  let [filetype, code, body] =
  \   matchlist(a:body, '\v^```\s*(\w*)\s*\n(.{-})\n```%(\n(.*))?')[1 : 3]
  return [{
  \   'decorator': 'code',
  \   'content': code,
  \   'param': {
  \     'filetype': filetype,
  \   },
  \ }, body]
endfunction
function! s:parse_block(body)
  let block = ''
  let body = a:body
  while body =~# '\v^%( {,4}\n|    |\t)'
    let [b, body] = matchlist(body, '\v^(.{-}%(\n|$))(.*)')[1 : 2]
    let block .= matchstr(b, '\v^%(\t| {,4})\zs.*')
  endwhile
  return [{
  \   'decorator': 'block',
  \   'content': matchstr(block, '^.\{-}\ze\n*$'),
  \ }, body]
endfunction

function! showtime#source#markdown#load()
  return s:source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
