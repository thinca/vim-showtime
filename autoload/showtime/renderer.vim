function showtime#renderer#clear() abort
  silent % delete _
  silent put =repeat([''], winheight(0))
  syntax clear
  call clearmatches()
endfunction

function showtime#renderer#render(page) abort
  call showtime#renderer#clear()
  let width = winwidth(0)
  let buf_height = winheight(0)
  let height = buf_height + 1  " cmdline
  if a:page.layout ==# 'body'
    let result = s:render_segment(a:page.segments)
    let lines = result.lines
    let lnum = s:height_middlize(height, len(lines))
    let left_pad = s:block_centerize(lines, width)
    call s:adjust_decorations(result.decorations, lnum - 1, left_pad)
    let decorations = result.decorations
    call setline(lnum, lines)
  elseif a:page.layout ==# 'page'
    let title_line = [a:page.title]
    call s:block_centerize(title_line, width)
    let lines = title_line + ['']
    let result = s:render_segment(a:page.segments)
    let left_pad = s:block_centerize(result.lines, width)
    call s:adjust_decorations(result.decorations, len(lines), left_pad)
    let lines += result.lines
    let decorations = result.decorations
    call setline(1, lines)
  elseif a:page.layout ==# 'title'
    let middle = height / 2
    let title_line = [a:page.title]
    call s:block_centerize(title_line, width)
    let lines = repeat([''], middle - 1) + title_line + repeat([''], 2)
    let result = s:render_segment(a:page.segments)
    let left_pad = s:block_centerize(result.lines, width)
    call s:adjust_decorations(result.decorations, len(lines), left_pad)
    let lines += result.lines
    let decorations = result.decorations
    call setline(1, lines)
  elseif a:page.layout ==# 'header'
    let middle = (height + 1) / 2
    let title_line = [a:page.title]
    call s:block_centerize(title_line, width)
    let lines = repeat([''], middle - 1) + title_line
    let decorations = []
    call setline(1, lines)
  endif
  call s:apply_decorations(decorations)
  call cursor(1, 1)
  redraw
endfunction

function s:height_middlize(max_height, body_height) abort
  return (a:max_height - a:body_height + 1) / 2
endfunction

function s:line_centerize(line, width) abort
  return s:centerize_padding(a:width, strwidth(a:line)) . a:line
endfunction

function s:block_centerize(lines, width) abort
  let left = s:centerize_padding(a:width, s:block_width(a:lines))
  call map(a:lines, 'left . v:val')
  return len(left)
endfunction

function s:centerize_padding(max_width, body_width) abort
  return repeat(' ', (a:max_width - a:body_width) / 2)
endfunction

function s:block_width(lines) abort
  return max(map(copy(a:lines), 'strwidth(v:val)'))
endfunction

function s:apply_decorations(decorations) abort
  for decoration in a:decorations
    if decoration.type ==# 'region'
      let contains = ''
      if has_key(decoration, 'contains')
        let contains = ' contains=' . decoration.contains
      endif
      execute printf(
      \   'syntax region %s start="\%%%dl" end="\%%%dl$"%s',
      \   decoration.group, decoration.start, decoration.end, contains)
    endif
    if decoration.type ==# 'position'
      call matchaddpos(decoration.group, [decoration.position], 100)
    endif
  endfor
endfunction

function s:adjust_decorations(decorations, line, col) abort
  for decoration in a:decorations
    if decoration.type ==# 'region'
      let decoration.start += a:line
      let decoration.end += a:line
    elseif decoration.type ==# 'position'
      let decoration.position[0] += a:line
      let decoration.position[1] += a:col
    endif
  endfor
endfunction

function s:render_segment(segment) abort
  let t = type(a:segment)
  if t == v:t_list
    let lines = []
    let decorations = []
    let prev_type = ''
    for seg in a:segment
      let result = s:render_segment(seg)
      if empty(result.lines)
        continue
      endif
      if result.type ==# 'block'
        if prev_type !=# ''
          let lines += ['']
        endif
        call s:adjust_decorations(result.decorations, len(lines), 0)
        let lines += result.lines
      elseif result.type ==# 'inline'
        if prev_type ==# 'block'
          let lines += ['', '']
        endif
        if empty(lines)
          let lines += ['']
        endif
        let decs = result.decorations
        call s:adjust_decorations(decs, len(lines) - 1, 0)
        call s:adjust_decorations(decs[0 : 0], 0, len(lines[-1]))
        let lines[-1] .= result.lines[0]
        let lines += result.lines[1 :]
      endif
      let decorations += result.decorations
      let prev_type = result.type
    endfor
    return {
    \   'lines': lines,
    \   'type': 'block',
    \   'decorations': decorations,
    \ }
  elseif t == v:t_dict
    let lines = split(a:segment.content, "\n")
    if has_key(a:segment, 'decorator')
      let dec = a:segment.decorator
      let result = s:decorator[dec](a:segment, lines)
    endif
    return {
    \   'lines': lines,
    \   'type': result.type,
    \   'decorations': result.decorations,
    \ }
  elseif t == v:t_string
    return {
    \   'lines': split(a:segment, "\n", 1),
    \   'type': 'inline',
    \   'decorations': [],
    \ }
  endif
  throw 'showtime: renderer: Not a segment: ' . string(a:segment)
endfunction

let s:decorator = {}
function s:decorator.code(segment, lines) abort
  let decoration = {
  \   'type': 'region',
  \   'group': 'showtimeBlock',
  \   'start': 1,
  \   'end': len(a:lines),
  \ }
  let ft = a:segment.param.filetype
  if ft !=# ''
    let contains = printf('@showtimeCode_%s', ft)
    unlet! b:current_syntax
    execute printf('syntax include %s syntax/%s.vim',
    \              contains, ft)
    let decoration.contains = contains
  endif
  let decorations = [decoration]
  return {
  \   'decorations': decorations,
  \   'type': 'block',
  \ }
endfunction
function s:decorator.block(segment, lines) abort
  highlight link showtimeBlock Constant
  let decorations = [{
  \   'type': 'region',
  \   'group': 'showtimeBlock',
  \   'start': 1,
  \   'end': len(a:lines),
  \ }]
  return {
  \   'decorations': decorations,
  \   'type': 'block',
  \ }
endfunction
function s:decorator.highlight(segment, lines) abort
  let param = a:segment.param
  if has_key(param, 'link')
    let link = param.link
    let group = 'showtime' . link
    execute printf('highlight link %s %s', group, link)
  else
    let group = ''
    let args = ''
    if has_key(param, 'attrs')
      let attr_list = join(param.attrs, ',')
      let group .= '_' . attr_list
      let args .=
      \   printf(' term=%s cterm=%s gui=%s', attr_list, attr_list, attr_list)
    endif
    if has_key(param, 'fg')
      let group .= '_fg_' . param.fg
      let args .= printf(' guifg=%s', param.fg)
    endif
    if has_key(param, 'bg')
      let group .= '_bg_' . param.bg
      let args .= printf(' guibg=%s', param.bg)
    endif
    if has_key(param, 'sp')
      let group .= '_sp_' . param.sp
      let args .= printf(' guisp=%s', param.sp)
    endif
    if group !=# ''
      let group = 'showtime' . group
      let highlight = printf('highlight %s %s', group, args)
      execute highlight
    endif
  endif

  let positions = map(copy(a:lines), { i, line -> [i + 1, 1, len(line)] })
  let decorations = map(positions, { i, pos ->
  \   {
  \     'type': 'position',
  \     'group': group,
  \     'position': pos,
  \   }
  \ })
  return {
  \   'decorations': decorations,
  \   'type': 'inline',
  \ }
endfunction
