" It's showtime!
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

function! showtime#start(...)
  let file = a:0 && a:1 =~# '\S' ? a:1 : expand('%:p')
  if !filereadable(file)
    throw "showtime: File can't read: " . file
  endif
  let source = showtime#source#markdown#load()
  let data = source.import(join(readfile(file), "\n"))
  call s:validate(data)
  call s:make_buffer(data)
endfunction

function! showtime#action(action, ...)
  if !exists('b:showtime')
    return
  endif
  return call('s:action_' . a:action, [b:showtime] + a:000)
endfunction

function! s:make_buffer(data)
  tabnew `='[showtime]'`
  let b:showtime = {}
  let b:showtime.data = a:data
  let b:showtime.option_save = {
  \   'showtabline': &showtabline,
  \   'laststatus': &laststatus,
  \ }
  set laststatus=0 showtabline=0
  if has_key(a:data, 'title')
    let b:showtime.option_save.titlestring = &titlestring
    let &titlestring = a:data.title
  endif
  setlocal buftype=nofile readonly
  setlocal nowrap nolist cmdheight=1 nocursorline nocursorcolumn
  setlocal filetype=showtime

  nnoremap <silent> <buffer> <Plug>(showtime-next)
  \                 :<C-u>call showtime#action('next', v:count1)<CR>
  nnoremap <silent> <buffer> <Plug>(showtime-prev)
  \                 :<C-u>call showtime#action('prev', v:count1)<CR>
  nnoremap <silent> <buffer> <Plug>(showtime-first)
  \                 :<C-u>call showtime#action('first')<CR>
  nnoremap <silent> <buffer> <Plug>(showtime-last)
  \                 :<C-u>call showtime#action('last')<CR>
  nnoremap <silent> <buffer> <Plug>(showtime-jump)
  \                 :<C-u>call showtime#action('jump', v:count)<CR>
  nnoremap <silent> <buffer> <Plug>(showtime-quit)
  \                 :<C-u>call showtime#action('quit')<CR>

  nmap <buffer> <Space> <Plug>(showtime-next)
  nmap <buffer> <CR> <Plug>(showtime-next)
  nmap <buffer> l <Plug>(showtime-next)
  nmap <buffer> > <Plug>(showtime-next)
  nmap <buffer> <BS> <Plug>(showtime-prev)
  nmap <buffer> h <Plug>(showtime-prev)
  nmap <buffer> < <Plug>(showtime-prev)
  nmap <buffer> 0 <Plug>(showtime-first)
  nmap <buffer> ^ <Plug>(showtime-first)
  nmap <buffer> $ <Plug>(showtime-last)
  nmap <buffer> # <Plug>(showtime-jump)
  nmap <buffer> go <Plug>(showtime-jump)
  nmap <buffer> q <Plug>(showtime-quit)

  command! -buffer ShowtimeEnd call showtime#action('quit')
  let b:showtime.cursor = s:hide_cursor()
  call s:action_jump(b:showtime, 1)
endfunction

function! s:action_next(session, count)
  return s:action_jump(a:session, a:session.current_page + a:count)
endfunction
function! s:action_prev(session, count)
  return s:action_jump(a:session, a:session.current_page - a:count)
endfunction
function! s:action_first(session)
  return s:action_jump(a:session, 1)
endfunction
function! s:action_last(session)
  return s:action_jump(a:session, len(a:session.data.pages))
endfunction
function! s:action_jump(session, page)
  let data = a:session.data
  let last = len(data.pages)
  let page = a:page <= 0 ? 1 :
  \          last < a:page ? last : a:page
  call s:render(data.pages[page - 1])
  let a:session.current_page = page
endfunction
function! s:action_quit(session)
  for [option, value] in items(a:session.option_save)
    execute 'let &' . option . ' = value'
  endfor
  execute a:session.cursor
  tabclose
endfunction


function! s:hide_cursor()
  redir => cursor
  silent! hi Cursor
  redir END
  let cursor = 'highlight Cursor ' .
  \            substitute(matchstr(cursor, 'xxx\zs.*'), "\n", ' ', 'g')
  highlight Cursor ctermfg=NONE ctermbg=NONE guifg=NONE guibg=NONE
  return cursor
endfunction

function! s:clear()
  silent % delete _
  silent put =repeat([''], winheight(0))
endfunction

function! s:render(page)
  call s:clear()
  call setline(1, a:page.title)
  call setline(3, split(a:page.body, "\n"))
  1
endfunction

function! s:validate(data)
  " TODO
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
