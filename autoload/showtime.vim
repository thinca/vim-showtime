function showtime#start(...) abort
  let file = a:0 && a:1 =~# '\S' ? a:1 : expand('%:p')
  try
    let data = showtime#load(file)
    call s:validate(data)
  catch /^showtime:/
    echohl ErrorMsg
    echomsg v:exception
    echohl None
    return
  endtry
  let page = 2 <= a:0 ? a:2 : 1
  call s:make_buffer(data, page)
endfunction

function showtime#resume() abort
  if exists('s:resume_info')
    call showtime#start(s:resume_info.filename, s:resume_info.page)
  else
    call showtime#start()
  endif
endfunction

function showtime#load(file) abort
  if !filereadable(a:file)
    throw "showtime: File can't read: " . a:file
  endif
  let source = showtime#source#markdown#load()
  let data = source.import(join(readfile(a:file), "\n"))
  let data.filename = a:file
  return data
endfunction

function showtime#action(action, ...) abort
  if !exists('b:showtime_session')
    return
  endif
  return call('s:action_' . a:action, [b:showtime_session] + a:000)
endfunction

function s:make_buffer(data, page) abort
  tabnew `='[showtime]'`
  silent execute 'tabmove' (tabpagenr() - 2)
  augroup plugin-showtime
    autocmd! TabLeave <buffer> ShowtimeEnd
  augroup END
  let b:showtime_session = {}
  let b:showtime_session.data = a:data
  let b:showtime_session.saved_state = s:save_state()
  set laststatus=0 showtabline=0 noshowcmd
  set showbreak= noshowmode noruler
  setlocal buftype=nofile readonly
  setlocal nonumber norelativenumber wrap nolist cmdheight=1
  setlocal nocursorline nocursorcolumn colorcolumn=
  " :silent is needed to avoid hit-enter-prompt.
  silent setlocal filetype=showtime

  call s:hide_cursor()
  call s:action_jump(b:showtime_session, a:page)
endfunction

function s:action_next(session, count) abort
  return s:action_jump(a:session, a:session.current_page + a:count)
endfunction
function s:action_prev(session, count) abort
  return s:action_jump(a:session, a:session.current_page - a:count)
endfunction
function s:action_first(session) abort
  return s:action_jump(a:session, 1)
endfunction
function s:action_last(session) abort
  return s:action_jump(a:session, len(a:session.data.pages))
endfunction
function s:action_jump(session, page) abort
  let data = a:session.data
  let last = len(data.pages)
  let page_nr = a:page <= 0 ? 1 :
  \          last < a:page ? last : a:page
  let page = data.pages[page_nr - 1]

  call showtime#renderer#clear()

  let cs = get(page.meta, 'colorscheme', get(data, 'colorscheme', ''))
  if cs !=# '' && cs !=# get(a:session, 'current_colorscheme', '')
    execute 'colorscheme' cs
    let a:session.current_colorscheme = cs
    let a:session.saved_state.cursor = s:current_cursor()
    call s:hide_cursor()
  endif

  if has('gui_running') && exists('+guifont')
    let font = get(page.meta, 'font', get(data, 'font', ''))
    if font !=# '' && font !=# get(a:session, 'current_font', '')
      let &guifont = font
      let a:session.current_font = font
      set lines=100 columns=500
    endif
  endif

  call showtime#renderer#render(page)

  if has_key(data, 'title')
    let &titlestring = printf('%s [%d/%d]', data.title, page_nr, last)
  endif
  let a:session.current_page = page_nr
endfunction
function s:action_quit(session) abort
  call s:restore_state(a:session.saved_state)
  let s:resume_info = {
  \   'filename': a:session.data.filename,
  \   'page': a:session.current_page,
  \ }
  tabclose
endfunction
function s:action_cursor(session) abort
  if !has_key(a:session, 'saved_state')
    return
  endif
  let state = a:session.saved_state
  if has_key(state, 'cursor')
    execute remove(state, 'cursor')
  else
    let state.cursor = s:current_cursor()
    call s:hide_cursor()
  endif
endfunction
function s:action_redraw(session) abort
  return s:action_jump(a:session, a:session.current_page)
endfunction

function s:save_state() abort
  let options = {}
  for option in [
  \   'showtabline', 'laststatus',
  \   'showcmd', 'showbreak', 'showmode', 'titlestring',
  \   'guifont', 'lines', 'columns', 'ruler',
  \ ]
    let options[option] = eval('&' . option)
  endfor
  return {
  \   'options': options,
  \   'cursor': s:current_cursor(),
  \   'background': &background,
  \   'colorscheme': get(g:, 'colors_name', ''),
  \ }
endfunction
function s:restore_state(state) abort
  for [option, value] in items(a:state.options)
    let optname = '&' . option
    if eval(optname) isnot value
      execute 'let' optname '= value'
    endif
  endfor
  if has_key(a:state, 'cursor')
    execute a:state.cursor
  endif
  let &background = a:state.background
  if has_key(a:state, 'colorscheme') &&
  \   a:state.colorscheme !=# '' &&
  \   a:state.colorscheme !=# get(g:, 'colors_name', '')
    execute 'colorscheme' a:state.colorscheme
  endif
endfunction


function s:current_cursor() abort
  redir => cursor
  silent! highlight Cursor
  redir END
  if cursor !~# 'xxx'
    return ''
  endif
  return 'highlight Cursor ' .
  \      substitute(matchstr(cursor, 'xxx\zs.*'), "\n", ' ', 'g')
endfunction
function s:hide_cursor() abort
  highlight Cursor ctermfg=NONE ctermbg=NONE guifg=NONE guibg=NONE
endfunction



function s:validate(data) abort
  " TODO
endfunction
