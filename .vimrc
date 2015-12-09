set nocompatible
filetype off
syntax enable
set background=dark
colorscheme molokai
set guifont=Courier\ new:h16
set ai                      "自动缩进
set bs=2                    "在insert模式下用退格键删除
set showmatch               "代码匹配
set laststatus=2            "总是显示状态行
set expandtab               "以下三个配置配合使用，设置tab和缩进空格数
set shiftwidth=4
set tabstop=4
set cursorline              "为光标所在行加下划线
set number                  "显示行号
set autoread                "文件在Vim之外修改过，自动重新读入
set ignorecase              "检索时忽略大小写
set fileencodings=uft-8,gbk "使用utf-8或gbk打开文件
set hls                     "检索时高亮显示匹配项
set helplang=cn             "帮助系统设置为中文
set foldmethod=syntax       "代码折叠
set foldlevel=99

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" let Vundle manage Vundle, required
Plugin 'gmarik/vundle'

" The following are examples of different formats supported.
" Keep Plugin commands between here and filetype plugin indent on.
" scripts on GitHub repos
Plugin 'tpope/vim-fugitive'
Plugin 'Lokaltog/vim-easymotion'
Plugin 'tpope/vim-rails.git'
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" scripts from http://vim-scripts.org/vim/scripts.html
Plugin 'L9'
Plugin 'FuzzyFinder'
" scripts not on GitHub
Plugin 'git://git.wincent.com/command-t.git'
" git repos on your local machine (i.e. when working on your own plugin)
" Plugin 'file:///home/gmarik/path/to/plugin'
Plugin 'kien/ctrlp.vim.git:'
Plugin 'taglist.vim'
Bundle 'Lokaltog/vim-powerline'
Bundle 'scrooloose/nerdtree'
Bundle 'majutsushi/tagbar'
Bundle 'wesleyche/SrcExpl'
filetype plugin indent on   
"vundle设置完毕

syntax on
let g:tagbar_ctags_bin='/usr/local/bin/ctags'
let g:tagbar_left = 0
nnoremap <F3> :TagbarToggle<CR>
let NERDTreeWinPos='left'
nnoremap <F2> :NERDTreeToggle<CR>
nmap <F4> :SrcExplToggle<CR>
let g:Srcexpl_winHeight = 8
" // Set 100 ms for refreshing the Source Explorer
let g:SrcExpl_refreshTime = 100

" // Set "Enter" key to jump into the exact definition context
let g:SrcExpl_jumpKey = "<ENTER>"

" // Set "Space" key for back from the definition context
let g:SrcExpl_gobackKey = "<SPACE>"

let g:SrcExpl_pluginList = [
         \ "__Tag_List__",
                 \ "_NERD_tree_"
           \ ]


set tags=../tags;/  "搜索上一级建立的tag

"taglist{
let Tlist_Show_One_File = 1            "只显示当前文件的taglist，默认是显示多个
let Tlist_Exit_OnlyWindow = 1          "如果taglist是最后一个窗口，则退出vim
let Tlist_Use_Right_Window = 1         "在右侧窗口中显示taglist
let Tlist_GainFocus_On_ToggleOpen = 1  "打开taglist时，光标保留在taglist窗口
let Tlist_Ctags_Cmd='/usr:/local/bin/ctags'  "设置ctags命令的位置
nnoremap <leader>tl : Tlist<CR>        "设置关闭和打开taglist窗口的快捷键
"}

"conf for tabs, 为标签页进行的配置，通过ctrl h/l切换标签等
let mapleader = ','
nnoremap <C-l> gt
nnoremap <C-h> gT
nnoremap <leader>t : tabe<CR>
nnoremap <F6> :CommandT<CR>

nmap <C-HH222222> <C-W>h "control+h进入左边的窗口
nmap <C-J> <C-W>j  "control+j进入下边的窗口
nmap <C-K> <C-W>k "control+k进入上边的窗口
nmap <C-L> <C-W>l  "control+l进入右边的窗口
nmap s <Plug>(easymotion-s2)
nmap t <Plug>(easymotion-t2)
map  / <Plug>(easymotion-sn)
omap / <Plug>(easymotion-tn)
map  n <Plug>(easymotion-next)
map  N <Plug>(easymotion-prev)
nmap se :SrcExplToggle<CR>
let g:ctrlp_match_window = 'results:100'

set fileencodings=utf-8,chinese,latin-1
set termencoding=utf-8
set encoding=utf-8