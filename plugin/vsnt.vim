" =====================================
" Filename: plugin/vsnt.vim
" Author: hwblx
" License: MIT License
" Last Change: 2024/09/30
" =====================================

let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_vsnt')
  finish
elseif has('nvim')
  let version_info = execute('version')
  let version_line = split(version_info, "\n")[0]
  let version_number = split(version_line[-5:], '\.')
  if version_number[0] < 1 && (version_number[1] < 4
    \|| (version_number[1] == 4 && version_number[2] < 4))
    echo 'vsnt requires nvim version >= 0.4.4'
    finish
  endif
elseif v:version < 801
  echo 'vsnt requires vim version >= 8.01'
  finish 
else
  let g:loaded_vsnt = 1
endif

command! -nargs=* Snt call vsnt#vsnt_main(<f-args>)

func! vsnt#vsnt_main(...)
  if @% ==# ''
    if !exists('b:buffer_init') || b:buffer_init < 1
      if has('nvim') && filereadable(expand('~/.local/share/nvim/plugged/vsnt/autoload/vsnt.vim'))
        let @d = '~/.local/share/nvim/plugged/vsnt/data/vsnt.sqlite'
        :source ~/.local/share/nvim/plugged/vsnt/autoload/vsnt.vim
      elseif has('nvim') && filereadable(expand('~/.local/share/nvim/site/pack/plugins/start/vsnt/autoload/vsnt.vim'))
        let @d = '~/.local/share/nvim/site/pack/plugins/start/vsnt/data/vsnt.sqlite'
        :source ~/.local/share/nvim/site/pack/plugins/start/vsnt/autoload/vsnt.vim
      elseif has('nvim') && filereadable(expand('~/.local/share/nvim/site/pack/plugins/opt/vsnt/autoload/vsnt.vim'))
        let @d = '~/.local/share/nvim/site/pack/plugins/opt/vsnt/data/vsnt.sqlite'
        :source ~/.local/share/nvim/site/pack/plugins/start/vsnt/autoload/vsnt.vim
      elseif filereadable(expand('~/.vim/plugged/vsnt/autoload/vsnt.vim'))
        let @d = '~/.vim/plugged/vsnt/data/vsnt.sqlite'
        :source ~/.vim/plugged/vsnt/autoload/vsnt.vim
      elseif filereadable(expand('~/.vim/pack/plugins/start/vsnt/autoload/vsnt.vim'))
        let @d = '~/.vim/pack/plugins/start/vsnt/data/vsnt.sqlite'
        :source ~/.vim/pack/plugins/start/vsnt/autoload/vsnt.vim
      elseif filereadable(expand('~/.vim/pack/plugins/opt/vsnt/autoload/vsnt.vim'))
        let @d = '~/.vim/pack/plugins/opt/vsnt/data/vsnt.sqlite'
        :source ~/.vim/pack/plugins/opt/vsnt/autoload/vsnt.vim
      else
        :echo 'autoload/vsnt.vim not found'
        return
      endif
      let b:buffer_init = 1
    endif
  else
    echo 'vsnt only starts from a new buffer'
    return
  endif

  call call('Vsnt_ctrl', a:000)
endfunc

let &cpo = s:save_cpo
unlet s:save_cpo
