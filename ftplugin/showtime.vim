" FileType plugin for showtime
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

let s:save_cpo = &cpo
set cpo&vim

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

let &cpo = s:save_cpo
unlet s:save_cpo
