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
  let b:showtime.saved_state = s:save_state()
  set laststatus=0 showtabline=0 noshowcmd
  if has_key(a:data, 'font')
    let &guifont = a:data.font
  endif
  setlocal buftype=nofile readonly
  setlocal nonumber nowrap nolist cmdheight=1
  setlocal nocursorline nocursorcolumn colorcolumn=
  " :silent is needed to avoid hit-enter-prompt.
  silent setlocal filetype=showtime

  call s:hide_cursor()
  if get(a:data, 'colorscheme', '') !=# ''
    execute 'colorscheme' a:data.colorscheme
  endif
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
  call s:restore_state(a:session.saved_state)
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

function! s:save_state()
  let options = {}
  for option in [
  \   'showtabline', 'laststatus',
  \   'showcmd', 'titlestring',
  \   'guifont', 'lines', 'columns',
  \ ]
    let options[option] = eval('&' . option)
  endfor
  return {
  \   'options': options,
  \   'cursor': s:current_cursor(),
  \   'colorscheme': g:colors_name,
  \ }
endfunction
function! s:restore_state(state)
  for [option, value] in items(a:state.options)
    let optname = '&' . option
    if eval(optname) isnot value
      execute 'let' optname '= value'
    endif
  endfor
  if has_key(a:state, 'cursor')
    execute a:state.cursor
  endif
  if has_key(a:state, 'colorscheme') && a:state.colorscheme !=# g:colors_name
    execute 'colorscheme' a:state.colorscheme
  endif
endfunction


function! s:current_cursor()
  redir => cursor
  silent! hi Cursor
  redir END
  return 'highlight Cursor ' .
  \      substitute(matchstr(cursor, 'xxx\zs.*'), "\n", ' ', 'g')
endfunction
function! s:hide_cursor()
  highlight Cursor ctermfg=NONE ctermbg=NONE guifg=NONE guibg=NONE
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
  if a:page.layout ==# 'body'
    let lines = s:render_segment(a:page.segments, {'line': 1})
    let line = s:height_middlize(height, len(lines))
    call setline(line, s:block_centerize(lines, width))
    let bottom = line + len(lines)
  elseif a:page.layout ==# 'page'
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

function! s:height_middlize(max_height, body_height)
  return (a:max_height - a:body_height) / 2
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
