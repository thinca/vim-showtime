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
  let page = 2 <= a:0 ? a:2 : 1
  let source = showtime#source#markdown#load()
  let data = source.import(join(readfile(file), "\n"))
  call s:validate(data)
  call s:make_buffer(data, page)
endfunction

function! showtime#action(action, ...)
  if !exists('b:showtime')
    return
  endif
  return call('s:action_' . a:action, [b:showtime] + a:000)
endfunction

function! s:make_buffer(data, page)
  tabnew `='[showtime]'`
  silent execute 'tabmove' (tabpagenr() - 2)
  augroup plugin-showtime
    autocmd! TabLeave <buffer> ShowtimeEnd
  augroup END
  let b:showtime = {}
  let b:showtime.data = a:data
  let b:showtime.option_save = {}
  for option in [
  \   'showtabline', 'laststatus',
  \   'showcmd', 'titlestring',
  \   'guifont', 'lines', 'columns',
  \ ]
    let b:showtime.option_save[option] = eval('&' . option)
  endfor
  set laststatus=0 showtabline=0 noshowcmd
  if has_key(a:data, 'font')
    let &guifont = a:data.font
  endif
  setlocal buftype=nofile readonly
  setlocal nonumber nowrap nolist cmdheight=1
  setlocal nocursorline nocursorcolumn colorcolumn=
  " :silent is needed to avoid hit-enter-prompt.
  silent setlocal filetype=showtime

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
  nnoremap <silent> <buffer> <Plug>(showtime-cursor)
  \                 :<C-u>call showtime#action('cursor')<CR>
  nnoremap <silent> <buffer> <Plug>(showtime-redraw)
  \                 :<C-u>call showtime#action('redraw')<CR>

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
  nmap <buffer> s <Plug>(showtime-cursor)
  nmap <buffer> <C-l> <Plug>(showtime-redraw)

  command! -buffer ShowtimeEnd call showtime#action('quit')
  let b:showtime.cursor = s:hide_cursor()
  call s:action_jump(b:showtime, a:page)
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
  if has_key(data, 'title')
    let &titlestring = printf('%s [%d/%d]', data.title, page, last)
  endif
  let a:session.current_page = page
endfunction
function! s:action_quit(session)
  for [option, value] in items(a:session.option_save)
    let optname = '&' . option
    if eval(optname) isnot value
      execute 'let' optname '= value'
    endif
  endfor
  if has_key(a:session, 'cursor')
    execute a:session.cursor
  endif
  tabclose
endfunction
function! s:action_cursor(session)
  if has_key(a:session, 'cursor')
    execute remove(a:session, 'cursor')
  else
    let a:session.cursor = s:hide_cursor()
  endif
endfunction
function! s:action_redraw(session)
  return s:action_jump(a:session, a:session.current_page)
endfunction


function! s:hide_cursor()
  redir => cursor
  silent! hi Cursor
  redir END
  highlight Cursor ctermfg=NONE ctermbg=NONE guifg=NONE guibg=NONE
  return 'highlight Cursor ' .
  \      substitute(matchstr(cursor, 'xxx\zs.*'), "\n", ' ', 'g')
endfunction

function! s:clear()
  silent % delete _
  silent put =repeat([''], winheight(0))
endfunction

function! s:render(page)
  call s:clear()
  syntax clear
  let width = winwidth(0)
  let height = winheight(0)
  if a:page.layout ==# 'page'
    call setline(1, s:line_centerize(a:page.title, width))
    let lines = s:render_segment(a:page.segments, {'line': 3})
    call setline(3, s:block_centerize(lines, width))
    let bottom = len(lines) + 2
  elseif a:page.layout ==# 'title'
    call setline(height / 2, s:line_centerize(a:page.title, width))
    let line = height / 2 + 2
    let lines = s:render_segment(a:page.segments, {'line': line})
    call setline(line, s:block_centerize(lines, width))
    let bottom = line + len(lines) - 1
  endif
  if bottom < height
    silent execute (height + 1) . ',$ delete _'
  endif
  1
  redraw
endfunction

function! s:line_centerize(line, width)
  return s:centerize_padding(a:width, strwidth(a:line)) . a:line
endfunction

function! s:block_centerize(lines, width)
  let left = s:centerize_padding(a:width, s:block_width(a:lines))
  return map(a:lines, 'left . v:val')
endfunction

function! s:centerize_padding(max_width, body_width)
  return repeat(' ', (a:max_width - a:body_width) / 2)
endfunction

function! s:block_width(lines)
  return max(map(copy(a:lines), 'strwidth(v:val)'))
endfunction

function! s:render_segment(segment, context)
  let t = type(a:segment)
  if t == type([])
    let block = []
    for seg in a:segment
      let lines = s:render_segment(seg, a:context) + ['']
      let block += lines
      let a:context.line += len(lines)
      unlet seg
    endfor
    return block
  elseif t == type({})
    let lines = split(a:segment.content, "\n")
    if has_key(a:segment, 'decorator')
      let dec = a:segment.decorator
      let a:context.height = len(lines)
      call s:decorator[dec](a:segment, a:context)
    endif
    return lines
  elseif t == type('')
    return split(a:segment, "\n")
  endif
  return []
endfunction

let s:decorator = {}
function! s:decorator.code(segment, context)
  let ft = a:segment.param.filetype
  unlet! b:current_syntax
  execute printf('syntax include @showtimeCode_%s syntax/%s.vim',
  \              ft, ft)
  execute printf('syntax region showtimeCode '
  \ . 'start="\%%%dl" end="\%%%dl" '
  \ . 'contains=@showtimeCode_%s',
  \   a:context.line, a:context.line + a:context.height, ft)
endfunction
function! s:decorator.block(segment, context)
  highlight link showtimeBlock Constant
  execute printf('syntax region showtimeBlock '
  \ . 'start="\%%%dl" end="\%%%dl"',
  \   a:context.line, a:context.line + a:context.height)
endfunction


function! s:validate(data)
  " TODO
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
