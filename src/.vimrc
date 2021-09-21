" Install minimal vimrc using:
" wget -q https://yogendra.me/minimal-vimrc  -O ~/.vimrc
" OR
" curl -sL https://yogendra.me/minimal-vimrc -o ~/.vimrc

set autoindent
set nobackup
set nowritebackup
set noswapfile
set history=50
set ruler
set showcmd
set number
set tabstop=2
set shiftwidth=2
set shiftround
set expandtab
set noswapfile
set nobackup
set nowb

set nowrap
set linebreak

set wildmode=list:longest
set wildmenu
set wildignore=*.o,*.obj,*~
set wildignore+=*vim/backups*
set wildignore+=*sass-cache*
set wildignore+=*DS_Store*
set wildignore+=vendor/rails/**
set wildignore+=vendor/cache/**
set wildignore+=*.gem
set wildignore+=log/**
set wildignore+=tmp/**
set wildignore+=*.png,*.jpg,*.gif


set scrolloff=8
set sidescrolloff=15
set sidescroll=1


set incsearch
set hlsearch
set ignorecase
set smartcase
set expandtab

set number
set hlsearch
set incsearch
let g:netrw_liststyle=3
syntax enable
colorscheme evening
