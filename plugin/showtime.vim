if exists('g:loaded_showtime')
  finish
endif
let g:loaded_showtime = 1

command! -nargs=? -count=1 -bar -complete=file
\        ShowtimeStart call showtime#start(<q-args>, <count>)

command! -nargs=? -count=1 -bar -complete=file
\        ShowtimeResume call showtime#resume()
