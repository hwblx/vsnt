# vsnt - vim simple notebook
****
- **Edit, search and read notes in Vim**
- **Quick and simple with minimal workflow impact**
- **SQLite format**
****

![image](https://github.com/user-attachments/assets/309faf5e-f558-42d6-b7e1-d1ceb4d8e0f7)


## Requirements
Vim >= 8.1.0875 or Neovim >= 0.4.4

SQLite (e.g. `apt install sqlite3` on a Debian based system)

## Installation
### vim-plug
Add `Plug 'hwblx/vsnt'` to your `.vimrc`.

Install with `:PlugInstall`.

### packages (built-in)
#### Vim
`git clone https://github.com/hwblx/vsnt ~/.vim/pack/plugins/start/vsnt`

#### Neovim
`git clone https://github.com/hwblx/vsnt ~/.local/share/nvim/site/pack/plugins/start/vsnt`

## Usage
Open a new buffer and start with `:Snt`.

Actions are called up via the insert or command line mode.

### Insert mode (line 3, vsnt command line) 
Submit with `<Enter>` or `<Shift-F3>`, e.g.

`E: s python #html or`

`S: r 2`
  
`R: n`

### Command line mode
Prefix all commands with `Snt`, e.g.

`:Snt n`

`:Snt s *`

`:Snt tl vsnt_peers`

## Commands
#### All modes (E:dit, R:ead or S:earch)
`  n                   edit new note`

`  e {number}          edit note id=number`

`  s {words|#tags}     search words and/or #tags`                  

`  s {*|number|#}      show all notes (id >=number) or #tags`

`  r {number}          read note id=number`

`  {e|r|s}             show mode last view`

`  h                   help`

`  db *                list all databases`

`  db {path|number}    select database`

`  tl *                list all tables`

`  tl {name|number}    select table`

The `vsnt` default database comes with two sample tables, `vsnt_snippets` and `vsnt_peers`. 

Experiment with the commands, then start creating your own database with custom tables and personal notes.

<img src="https://github.com/user-attachments/assets/a2317df6-e800-4d91-a9a0-fb78c36c61ad" width="200" height="96">

#### E:
`  {number}            edit note id=number`

`  w                   write new note`

`  w {number}          overwrite note id=number`

`  u                   update recent note`

`  cb {path}           create database`

`  ct {name}           create table`

Note templates define a set of table column names. 

Column names are enclosed by angled brackets, e.g. like `<Title>`. 

Optionally, include a `<Tags>` column for searching #tags.

<img src="https://github.com/user-attachments/assets/cf2128dd-2da8-4052-8d66-961f9cdeedd5" width="200" height="96">

#### S:
`  {words|#tags|or}    search words and/or #tags`

`  {*|number|#}        show all notes (id >=number) or #tags`

Words are searched for in the first column of the table (the top note item).

#Tags are searched in `<Tags>` if present, otherwise in the first column.

Search phrases are concatenated with "and" by default. Toggle "or" concatenation like

`S: html #python or`

`E: s debian or git`

`:Snt s or #javascript #html`

#### R:
`  {number}            read note id=number`

`  E                   edit note`

## Defaults
Add your database file paths to the `vsnt_config` table to quickly navigate between different databases.

<img src="https://github.com/user-attachments/assets/32664f9b-31aa-4838-9be1-ad5e393275d3" width="200" height="96">



