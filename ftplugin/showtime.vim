if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

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

nmap <buffer> <nowait> <Space> <Plug>(showtime-next)
nmap <buffer> <nowait> <CR> <Plug>(showtime-next)
nmap <buffer> <nowait> l <Plug>(showtime-next)
nmap <buffer> <nowait> > <Plug>(showtime-next)
nmap <buffer> <nowait> <BS> <Plug>(showtime-prev)
nmap <buffer> <nowait> h <Plug>(showtime-prev)
nmap <buffer> <nowait> < <Plug>(showtime-prev)
nmap <buffer> <nowait> 0 <Plug>(showtime-first)
nmap <buffer> <nowait> ^ <Plug>(showtime-first)
nmap <buffer> <nowait> $ <Plug>(showtime-last)
nmap <buffer> <nowait> # <Plug>(showtime-jump)
nmap <buffer> <nowait> go <Plug>(showtime-jump)
nmap <buffer> <nowait> q <Plug>(showtime-quit)
nmap <buffer> <nowait> s <Plug>(showtime-cursor)
nmap <buffer> <nowait> <C-l> <Plug>(showtime-redraw)

command! -buffer ShowtimeEnd call showtime#action('quit')
