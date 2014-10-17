" It's showtime!
" Version: 1.1
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

if exists('g:loaded_showtime')
  finish
endif
let g:loaded_showtime = 1

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=? -count=1 -bar -complete=file
\        ShowtimeStart call showtime#start(<q-args>, <count>)

command! -nargs=? -count=1 -bar -complete=file
\        ShowtimeResume call showtime#resume()

let &cpo = s:save_cpo
unlet s:save_cpo
