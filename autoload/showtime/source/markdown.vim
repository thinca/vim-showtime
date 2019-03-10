" Showtime by markdown!
" Version: 1.2
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:source = {
\   'accept': ['.md', '.mkd', '.markdown'],
\ }

function! s:source.import(content)
  let data = {'pages': []}
  let [header, rest] = s:parse_header(a:content)
  call extend(data, header, 'keep')
  while !empty(rest)
    let [page, rest] = s:parse_page(rest)
    if !has_key(data, 'title') && has_key(page, 'title')
      let data.title = page.title
    endif
    let data.pages += [page]
  endwhile
  return data
endfunction

function! s:parse_header(input)
  " Temporary specs.
  let rest = substitute(a:input, '^\s*', '', '')
  let data = {}
  let rest = s:parse_metadata(rest, data)
  return [data, matchstr(rest, '^\_s*\zs.*')]
endfunction
function! s:parse_page(input)
  let [level, title, rest] = s:parse_title(a:input)
  let [segments, rest, meta] = s:parse_body(rest)
  let layout = level ==  1     ? 'title':
  \            title ==# ''    ? 'body':
  \            empty(segments) ? 'header':
  \                              'page'
  return [{
  \   'title': title,
  \   'layout': layout,
  \   'meta': meta,
  \   'segments': segments,
  \ }, rest]
endfunction
function! s:parse_title(input)
  let br = "[^\r\n]"
  let pat = '^\(#\+\s*' . br . '*\)\n*\(.*\)$'
  let list = matchlist(a:input, pat)
  if empty(list)
    throw 'showtime: markdown: Parsing of the title failed: ' . a:input
  endif
  let [title, rest] = list[1 : 2]
  let level = len(matchstr(title, '^#*'))
  let title = matchstr(title, '^#*\s*\zs.\{-}\ze\s*$')
  return [level, title, rest]
endfunction
function! s:parse_body(input)
  let segments = []
  let rest = a:input
  let meta = {}
  while rest !=# ''
    if rest =~# '^#'
      let rest = matchstr(rest, '^\_s*\zs.*')
      break
    elseif rest =~# '^<!--!'
      let rest = s:parse_metadata(rest, meta)
      continue
    elseif rest =~# '^```'
      let [seg, rest] = s:parse_code_block(rest)
    elseif rest =~# '^\%(    \|\t\)'
      let [seg, rest] = s:parse_block(rest)
    else
      let [seg, rest] = s:parse_text(rest)
    endif
    let segments += [seg]
    unlet seg
  endwhile
  return [segments, rest, meta]
endfunction
function! s:parse_metadata(input, meta)
  let matched = matchlist(a:input, '^<!--!\(.\{-}\)\n\s*-->\_s*\(.*\)')
  if empty(matched)
    return a:input
  endif
  let [data, rest] = matched[1 : 2]
  sandbox let meta = eval(substitute(data, "\n", '', 'g'))
  call extend(a:meta, meta)
  return rest
endfunction
function! s:parse_code_block(input)
  let result = matchlist(a:input, '\v^```\s*(\w*)\s*\n(.{-})```%(\n(.*))?')
  if result == []
    throw 'showtime: markdown: Parsing of code block failed: ' . a:input
  endif
  let [filetype, code, body] = result[1 : 3]
  return [{
  \   'decorator': 'code',
  \   'content': code,
  \   'param': {
  \     'filetype': filetype,
  \   },
  \ }, body]
endfunction
function! s:parse_block(input)
  let block = ''
  let body = a:input
  while body =~# '\v^%( {,4}\n|    |\t)'
    let [b, body] = matchlist(body, '\v^(.{-}%(\n|$))(.*)')[1 : 2]
    let block .= matchstr(b, '\v^%(\t| {,4})\zs.*')
  endwhile
  return [{
  \   'decorator': 'block',
  \   'content': matchstr(block, '^.\{-}\ze\n*$'),
  \ }, body]
endfunction
function! s:parse_text(input)
  let seg = matchstr(a:input, '^.\{-}\ze\%(\n\n\|\n\s*#\|$\)')
  let rest = matchstr(a:input[len(seg) :], '^\n*\zs.*')
  let seg = substitute(seg, '<!--\_.\{-}-->', '', 'g')
  let seg = substitute(seg, '`\(.\{-}\)`', '\1', 'g')
  let seg = substitute(seg, '\[\(.\{-}\)\](.\{-})', '\1', 'g')
  return [seg, rest]
endfunction

function! showtime#source#markdown#load()
  return s:source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
