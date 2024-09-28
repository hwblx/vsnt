" =====================================
" Filename: autoload/vsnt.vim
" Author: hwblx
" License: MIT License
" Last Change: 2024/09/27
" =====================================

let s:save_cpo = &cpo
set cpo&vim

let b:vsnt_database = ''
let b:vsnt_table = 'vsnt_snippets'
let b:vsnt_higroup = 'Underlined'

let b:databases = []
let b:tables = ['vsnt_snippets', 'vsnt_peers', 'vsnt_defaults']
let b:tables = []
let b:template = ['_Title', '_Description', '_Tags', '_References', '_Code']
let b:id = 0

let b:mode = 'E'
let b:view = {'E':'', 'S':'', 'R':''}
let b:message = ''

func! s:query_database(sql, mode)
   let $vsnt_sql = a:sql
   let result = systemlist('sqlite3 -' . a:mode . ' ' . expand(b:vsnt_database) . ' "$vsnt_sql"')
   return result
endfunc

func! s:change_table(table)
  if a:table ==# '*' 
    "show all tables
    call s:init_tables()
    :5,$d
    for i in range(len(b:tables))
      call setline(5+i, i+1 . '. ' . b:tables[i])   
    endfor
  elseif len(a:table) > 0
    "select table and change b:template based on its sql schema
    let t = str2nr(a:table) > 0 && str2nr(a:table) <= len(b:tables) 
         \? b:tables[str2nr(a:table)-1] 
         \: a:table
    let result = s:query_database('.schema ' . t, 'list')

    if exists('result[0]') && matchstrpos(result[0], 'CREATE TABLE ' . t)[1] == 0
      let b:vsnt_table = t
      let b:template = []
      let columns = split(result[0], ',')[1:]

      for i in range(len(columns))
        let c = trim(substitute(columns[i],'text.*','',''))
        call add(b:template, c)
      endfor
      call s:edit_new()
    else
      :silent! 4,$d
      call setline(3, b:mode . ': table not found')
    endif
  endif
endfunc

func! s:init_tables()
  let result = s:query_database('.tables' , 'line')
  
  if exists('result[0]') && matchstrpos(result[0], 'Error')[1] < 0
    let b:tables = len(result) > 0
              \? split(trim(result[0]), '\s\+')
              \: [] 
  endif
endfunc

func! s:create_table(table)
  if index(b:tables, a:table) < 0
    if match(getline(5), '^<\w\+>') == 0
      "<word> at line 5, col 1 defines a valid template
      let matches=[]
      :1
      "read all column names 
      while search('^<\w\+>\s*$', 'W')
        call add(matches, substitute(substitute(getline('.'), '<', '_', 'g'), '>\s*', '', 'g'))
      endwhile

      "create new table
      let columns = join(matches, ' text, ')
      let q = 'CREATE TABLE ' . a:table . ' (id INTEGER PRIMARY KEY, ' . columns . ' text);'

      let result = s:query_database(q, 'list')

      if exists('result[0]') && matchstrpos(result[0], 'Error')[1] >= 0
        call setline(3, b:mode . ': ' . result[0])
      else
        call add(b:tables, a:table)
        call s:change_table(a:table)
      endif
    else
      call setline(3, b:mode . ': not a valid template')
    endif
  else
    call setline(3, b:mode . ': this table exists already: ' . a:table)
  endif
endfunc

func! s:change_database(db) 
   if a:db ==# '*'   
    "show all databases
    :5,$d
    for i in range(len(b:databases))
      call setline(5+i, i+1 . '. ' . b:databases[i])   
    endfor

  else
    "select database
    let b = str2nr(a:db) > 0 && str2nr(a:db) <= len(b:databases) 
         \? b:databases[str2nr(a:db)-1] 
         \: a:db
   
    if filereadable(glob(b)) 
      let prev_db = b:vsnt_database
      let b:vsnt_database = b
    
      let result = s:query_database('.dbinfo', 'line')

      if match(result, 'Error') >= 0
        let b:vsnt_database = prev_db
        call setline(3, b:mode . ': ' . result[0])
      else
        if index(b:databases, b) < 0
          call add(b:databases, b)
        endif 
        call s:init_tables()
        if len(b:tables) > 0
          call s:change_table(b:tables[0])
          :1,4d
          call s:set_header()
        else
          let b:vsnt_table = ''
          let b:template = []
          call s:edit_new()
        endif
      endif
      "call setline(3, b:mode . ': ')
    else
      call setline(3, b:mode . ': file not found  ' . b)
    endif
  endif 
endfunc

func! s:create_database(path)
  let prev_db = b:vsnt_database
  let b:vsnt_database = expand(a:path)
  
  let result = s:query_database('.dbinfo', 'line')
  let b:vsnt_database = prev_db
    
  if match(result, 'Error') >= 0 
    call setline(3, b:mode . ': ' . result[0])
  else
    call add(b:databases, expand(a:path))
    call s:change_database('*')
    call setline(3, b:mode . ': ')
  endif
endfunc

func! s:write_note(id)
  let lines = [['', line('$')+1, '']]
  :$

  for i in range(len(b:template)-1, 0, -1)
    let item = search('^<' . b:template[i][1:] . '>', 'bc')

    if item > 0
      call insert(lines, [b:template[i], item, ''])
      if lines[0][1] < lines[1][1]
        let lines[0][2] = join(getline(lines[0][1]+1, lines[1][1]-1), "\n")
        let lines[0][2] = substitute(lines[0][2], '"', '""', 'g')
      else
        call setline(3, b:mode . ': ' . 'not a valid note')
        return
      endif
    else
      call setline(3, b:mode . ': ' . 'not a valid note')
      return
    endif
  endfor
  let lines = lines[:-2]

  if a:id < 1
    let cls = map(copy(lines), {_, val -> val[0]})
    let cls = '(' . join(cls, ',') . ')'
    let vls = map(copy(lines), {_, val -> val[2]})
    let vls = '("' . join(vls, '","') . '")'

    let q = 'insert into ' . b:vsnt_table . cls . ' values' . vls . ';'
  else
    let cvs = ''
    for l in lines
      let cvs = cvs . l[0] . '="' . l[2] . '",'
    endfor

    let q = 'update ' . b:vsnt_table . ' set ' . cvs[:-2] . ' WHERE id=' . a:id . ';'
  endif

  let result = s:query_database(q, 'list')

  if exists('result[0]') && matchstrpos(result[0], 'Error')[1] >= 0
    call setline(3, b:mode . ': ' . result[0])
  else
    if a:id < 1
      let m = 'inserted "' . trim(lines[0][2][:10]) . ' ..."'
    else
      let m = 'set id=' . a:id . ' to "' . trim(lines[0][2][:10]) . ' ..."'
    endif
   call setline(3, b:mode . ': ' . m)
  endif
endfunc

func! s:delete_note(id)
  let q = 'delete FROM ' . b:vsnt_table . ' WHERE id=' . a:id . ';'

  let result = s:query_database(q, 'line')

  if exists('result[0]') && matchstrpos(result[0], 'Error')[1] >= 0
    call setline(3, b:mode . ': ' . result[0])
  else
    call call('s:search_note', [a:id])
  endif
endfunc

func! s:edit_new()
  "edit a clean template 
  let b:mode = 'E'
  :1,$d
  
  if len(b:template) > 0
    for i in reverse(copy(b:template))
      call append(0, ['<' . i[1:] . '>', '', ''])
    endfor
  else
    call append(0, ['<Title>', '', '<>', '', '<>'])
    let b:message = 'Create a new template ("E: ct <name>")'
  endif
  
  call s:set_header()
endfunc

func! s:edit_note()
  "edit the last note read
  let b:mode = 'E'
  :1

  for i in b:template
    call setline(search(i[1:]), '<' . i[1:] . '>')
  endfor

  call setline(3, b:mode . ': ' . b:id)
endfunc

func! s:read_note(id)
  if len(b:vsnt_table) <= 0
    call setline(3, b:mode . ': No table selected, have you created one?')
    return
  endif
  
  let b:mode = 'R'
  let columns = join(b:template, ',')

  let q = 'SELECT '   . columns     . ' ' .
         \'FROM '     . b:vsnt_table . ' ' .
         \'WHERE id=' . a:id        . ';'

  let result = s:query_database(q, 'line')

  if exists('result[0]') && matchstrpos(result[0], 'Error')[1] >= 0
    call setline(3, b:mode . ': ' . result[0])
  else
    :1,$d
    call append(0, result)

    for t in b:template
      let sub = 'silent! %s/^\s*' . t . ' = ' . '/' . t[1:] . '\r/e'
      execute sub
    endfor

    let b:id = a:id
    let b:message = b:id
    call s:set_header()
  endif 
endfunc

func! s:search_note(...)
  if len(b:vsnt_table) <= 0
    call setline(3, b:mode . ': No table selected, have you created one?')
    return
  endif

  let b:mode =  'S'
  let condition = ''
  let andor = (index(a:000, 'or', 0, 1) >= 0)? ' or ' : ' and '

  if a:000[0] ==# '#'
    "read all #tags 
    let q = 'SELECT '        . b:template[2] . ' ' .
           \'FROM '          . b:vsnt_table   . ' ' .
           \'ORDER BY '      . b:template[2] . ';'

  elseif a:000[0] ==# '*'
    "show all table entries
    let q = 'SELECT id,'     . b:template[0] . ' ' .
           \'FROM '          . b:vsnt_table   . ' ' .
           \'WHERE id>0'     .                 ';'

  elseif str2nr(a:000[0]) > 0
    "show all table entries with id > number
    let q = 'SELECT id,'     . b:template[0] . ' ' .
           \'FROM '          . b:vsnt_table   . ' ' .
           \'WHERE id >= '   . a:000[0]      . ';'
  
  else
    for i in a:000
      if(i ==? 'or' || i ==? 'and' || i ==? '')
        continue
      endif

      let condition = condition . ((strlen(condition) > 0)? andor :'')
      let col = i[0] ==# '#' && index(b:template, '_Tags') >= 0 
             \? '_Tags'
             \: b:template[0]
      let condition = condition . col . ' like "%' . i . '%"'
    endfor

    if condition !=# ''
      let q = 'SELECT id,'   . b:template[0] . ' ' .
             \'FROM '        . b:vsnt_table   . ' ' .
             \'WHERE '       . condition     . ';'

    else
      return
    endif
  endif

  "echo(q)
  let result = s:query_database(q, 'column')

  if exists('result[0]') && matchstrpos(result[0], 'Error')[1] >= 0
    call setline(3, b:mode . ': ' . result[0])
    return
  else
    :1,$d
    call append(0, result)
  endif

  if a:000[0] ==# '#'
    let stags = uniq(sort(split(join(getline(1,'$')),'\s\+')))
    :1,$d

    for i in range(0,len(stags)-1)
      if i%5 == 0 && i > 0
        call append('.', [''])
        :+1
      endif
      call setline('.', getline('.') . stags[i] . ' ')
    endfor
  endif

  :noh
  silent %g/^\s*$/d
  let b:message = join(a:000, ' ')
  call s:set_header()
endfunc

func! s:hilight_match(word, start)
  if a:start >= 0 
    silent! execute(':' . a:start) 
  endif
  let l = search(a:word, 'c', line('$'))

  if l > 0
    let column = col('.')
    silent! call matchadd(b:vsnt_higroup , '\%' . l . 'l\%' . column . 'c' . a:word, 10)
  endif
endfunc

func! s:hilight_items()
  let cur = getcurpos()
  call clearmatches()
  
  if match(getline(5), 'Invocation') == 0 
    for i in ['Invocation like', 'All modes (E:, S:, R:)', 'E:dit', 'S:earch', 'R:ead']
      call s:hilight_match(i, 0)
    endfor
  elseif b:mode ==# 'E' || b:mode ==# 'R' 
    for i in b:template
      call s:hilight_match(i[1:], 0)
    endfor
  endif

  call cursor(cur[1],cur[2])
endfunc

func! s:reload_mode(mode)
  let b:mode = a:mode
  :1,$d

  if b:view[b:mode][0] ==# ''
    call s:set_header()
  else
    call append(0, b:view[b:mode])
  endif
endfunc

func! s:set_header()
  :call append(0, ['vsnt - vim simple notebook',b:vsnt_database . ' ' . b:vsnt_table,b:mode . ':  ' . b:message . ' ',''])
  let b:message = ''
endfunc

func! s:block_cursor()
    " Get the current cursor position
    let pos = getpos('.')
    " Check if cursor is below line 3 and column 3
    if pos[1] < 3 || (pos[1] == 3 && pos[2] < 4)
    " Move the cursor to column 3
      call setline(3, b:mode . ':  ')
      call cursor(3, 4)
    endif
endfunc

func! s:set_cursor()
  :silent! normal! gg
  call setline(3, b:mode . ': ' . trim(getline(3)[2:]) . ' ')
  call cursor(3, strwidth(getline(3)))
  "redraw!
  start
endfunc

func! s:show_help()
  :silent! 4,$d
 
  let text = [
              \'',
              \'Invocation like', 
              \'  E: s *         (vsnt command line, line 3)',
              \'  :Snt s *       (vim command line)',
              \'',
              \'All modes (E:, S:, R:)',
              \'  n                   edit new note',
              \'  e {number}          edit note id=number',
              \'  s {words|#tags}     search words and/or #tags',
              \'  s {*|number|#}      show all notes (id >=number) or #tags',
              \'  r {number}          read note id=number',
              \'  {e|r|s}             show mode last view',
              \'  h                   help',
              \'  ',
              \'  db *                list all databases',
              \'  db {path|number}    select database',
              \'  tl *                list all tables',
              \'  tl {name|number}    select table',
              \'  ',
              \'E:dit',
              \'  {number}            edit note id=number',
              \'  w                   write new note',
              \'  w {number}          overwrite note id=number',
              \'  u                   update recent note',
              \'  cb {path}           create database',
              \'  ct {name}           create table',
              \'  ',
              \'S:earch',
              \'  {words|#tags|or}    search words and/or #tags',
              \'  {*|number|#}        show all notes (id >=number) or #tags',
              \'',
              \'R:ead',
              \'  {number}            read note id=number',
              \'  E                   edit note',
              \'',
              \'',
            \]
                 
  call append(3, text)
endfunc

func! s:vsnt_menu(...)
  "parse commands and call actions
  let b:message = ''
  :noh
  if match(getline(5), 'Any mode') < 0 
    let b:view[b:mode] = getline(1,'$')
  endif
  
  "test
  ":echo a:000
  "sleep 3
  
  "any mode (E, S, R)
  if a:1 ==# 'h'
    call s:show_help()
  
  elseif a:1 ==# 'n'
    call s:edit_new()
  
  elseif a:1 ==# 'e'
    if a:0 > 1 && str2nr(a:2) > 0
      call s:read_note(str2nr(a:2))
      call s:edit_note()
    else
      call s:reload_mode(toupper(a:1))
    endif
 
  elseif a:1 ==# 's'
    if a:0 > 1 && len(a:2) > 0
      call call('s:search_note', a:000[1:])
    else
      call s:reload_mode(toupper(a:1))
    endif
 
  elseif a:1 ==# 'r'
    if a:0 > 1 && str2nr(a:2) > 0
      call s:read_note(str2nr(a:2))
    else
      call s:reload_mode(toupper(a:1))
    endif
  
  elseif a:1 ==# 'tl' && a:0 > 1
    call s:change_table(a:2)
  
  elseif a:1 ==# 'db' && a:0 > 1
    call s:change_database(a:2)
  
  "mode Edit
  elseif b:mode ==# 'E'
    if a:1 ==# 'w'
      let id = (a:0 > 1 && str2nr(a:2) > 0)? str2nr(a:2) : 0
      call s:write_note(id)
    elseif a:1 ==# 'u'
      let id = b:id
      call s:write_note(id)
    elseif a:1 ==# 'ct' && a:0 > 1 && len(a:2) > 0
      call s:create_table(a:2)
    elseif a:1 ==# 'cb' && a:0 > 1 && len(a:2) > 0
      call s:create_database(a:2)
    elseif str2nr(a:1) > 0 
      call s:read_note(str2nr(a:1))
      call s:edit_note()
    else
      call setline(3, b:mode . ': ')
    endif

  "mode Search
  elseif b:mode ==# 'S'
    if str2nr(a:1) > 0
      call s:search_note(a:1)
    elseif a:1 ==# 'd' && a:0 > 1 && str2nr(a:2) > 0
      call s:delete_note(str2nr(a:2))
    elseif len(a:1) > 1 || a:1 ==# '#' || a:1 ==# '*'
      call call('s:search_note', a:000)
    else
      call setline(3, b:mode . ': ')
    endif

  "mode Read
  elseif b:mode ==# 'R'
    if a:1 ==# 'E'
      call s:edit_note()
      return
    elseif str2nr(a:1) > 0
      call s:read_note(str2nr(a:1))
    else
      call setline(3, b:mode . ': ')
    endif
  
  "mode empty
  else
    call setline(3, b:mode . ': Enter "h" for help')
  endif
endfunc

func! Vsnt_ctrl(...)
  augroup hilightoff
    autocmd! TextChangedI <buffer>
    call clearmatches()
  augroup END

  "parse args from command line, call s:vsnt_menu() actions 
  if(a:0 ==# 0 || a:1 ==# '')
  "from vsnq command line
    if(line('.') == 3)
      let line = trim(getline(3)[2:])
      let words = split(line, '\s\+')
      call add(words, '')

      if(words[0] ==# '')
        call setline(3, b:mode . ': Enter "h" for help')
      else
        call call ('s:vsnt_menu', words)
      endif
    else
      call setline(3, b:mode . ': Enter "h" for help')
    endif
  else
    "from vim command line
    call call('s:vsnt_menu', a:000)
  endif 
  
  "init highlighting
  if b:mode ==# 'E' || b:mode ==# 'R' || a:1 ==# 'h' 
    call s:hilight_items()
    augroup hilighton
      autocmd TextChangedI <buffer> call s:hilight_items()
    augroup END
  endif
  call s:set_cursor ()
endfunc

func! s:vsnt_config()
  "set vsnt default database path
  let b:vsnt_default = @d
  let b:vsnt_database = b:vsnt_default
  call add(b:databases, b:vsnt_database)
  
  "read user database configs
  let q = 'SELECT ' . '_Database'  . ' ' .
         \'FROM '   . 'vsnt_config' . ';'
  let result = s:query_database(q, 'list')
  
  "add user databases if readable
  if exists('result[0]') && matchstrpos(result[0], 'Error')[1] < 0
    for i in filter(result, 'v:val !~# "^\s*$"')
      if filereadable(expand(i)) && index(b:databases, i) < 0
        call add(b:databases, i)
      endif
    endfor
  endif
endfunc

func! s:vsnt_init()
  "this is a scratch buffer
  setlocal nobuflisted buftype=nofile bufhidden=wipe noswapfile
  setlocal nofoldenable 
 
  "define vsnt submit keys <Shift-F3> and <Enter>
  nnoremap <silent> <buffer> <S-F3> <Cmd> call vsnt#vsnt_main('')<CR>
  inoremap <silent> <buffer> <S-F3> <Cmd> call vsnt#vsnt_main('')<CR>
  "inoremap <silent> <buffer> <expr> <Return> (line('.') == 3 ? "<C-o>:call vsnt#vsnt_main('')<CR>" : "\<CR>")
  inoremap <silent> <buffer> <expr> <Return> ((line('.') > 3 && b:mode ==# 'E') ? "\<CR>" : "<C-o>:call vsnt#vsnt_main('')<CR>")

  "setup control over cursor movements
  augroup blockcursor
    autocmd CursorMovedI <buffer> call s:block_cursor()
  augroup END
  
  "start user interface
  call s:set_header()
  call s:reload_mode('E')
endfunc

if filereadable(expand(@d))
  call s:vsnt_config()
  call s:vsnt_init()
else
  :echo 'vsnt.sqlite not found'
endif

let &cpo = s:save_cpo
unlet s:save_cpo
