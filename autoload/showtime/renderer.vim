function! showtime#renderer#clear()
  silent % delete _
  silent put =repeat([''], winheight(0))
  syntax clear
endfunction

function! showtime#renderer#render(page)
  call showtime#renderer#clear()
  let width = winwidth(0)
  let buf_height = winheight(0)
  let height = buf_height + 1  " cmdline
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
    let middle = height / 2
    call setline(middle, s:line_centerize(a:page.title, width))
    let line = middle + 2
    let lines = s:render_segment(a:page.segments, {'line': line})
    call setline(line, s:block_centerize(lines, width))
    let bottom = line + len(lines) - 1
  elseif a:page.layout ==# 'header'
    let middle = (height + 1) / 2
    call setline(middle, s:line_centerize(a:page.title, width))
    let bottom = middle
  endif
  if bottom < buf_height
    silent execute (buf_height + 1) . ',$ delete _'
  endif
  1
  redraw
endfunction

function! s:height_middlize(max_height, body_height)
  return (a:max_height - a:body_height + 1) / 2
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
      let lines = []
      if !empty(block)
        let lines += ['']
      endif
      let lines += s:render_segment(seg, a:context)
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
  if ft ==# ''
    let contains = ''
  else
    unlet! b:current_syntax
    execute printf('syntax include @showtimeCode_%s syntax/%s.vim',
    \              ft, ft)
    let contains = printf(' contains=@showtimeCode_%s', ft)
  endif
  execute printf('syntax region showtimeCode '
  \ . 'start="\%%%dl" end="\%%%dl$"%s',
  \   a:context.line, a:context.line + a:context.height, contains)
endfunction
function! s:decorator.block(segment, context)
  highlight link showtimeBlock Constant
  execute printf('syntax region showtimeBlock '
  \ . 'start="\%%%dl" end="\%%%dl$"',
  \   a:context.line, a:context.line + a:context.height)
endfunction
