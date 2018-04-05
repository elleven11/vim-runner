" Author: Huang Po-Hsuan <aben20807@gmail.com>
" Filename: runner.vim
" Last Modified: 2018-04-05 18:09:35
" Vim: enc=utf-8

" Function: runner#InitVariable() function
" 初始化變數
" Ref: https://github.com/scrooloose/nerdcommenter/blob/master/plugin/NERD_commenter.vim#L26
" Args:
"   -var: the name of the var to be initialised
"   -value: the value to initialise var to
" Returns:
"   1 if the var is set, 0 otherwise
function! runner#InitVariable(var, value)
    if !exists(a:var)
        execute 'let ' . a:var . ' = ' . "'" . a:value . "'"
        return 1
    endif
    return 0
endfunction


" Function: runner#SetUpFiletype(filetype) function
" Set up filetype.
" Args:
"   -filetype
function! runner#SetUpFiletype(filetype)
    let b:ft = a:filetype
    if b:ft ==# 'rust'
        let l:current_dir = getcwd()
        if filereadable(current_dir . "/../Cargo.toml") ||
                    \ filereadable(current_dir . "/Cargo.toml")
            let g:runner_rust_executable = "cargo"
        else
            let g:runner_rust_executable = "rustc"
        endif
        let b:supported = 1
        return
    endif
    if b:ft ==# 'markdown' && g:runner_is_with_md
        let b:supported = 1
        return
    endif
    if b:ft ==# 'c' || b:ft ==# 'cpp' || b:ft ==# 'python' || b:ft == 'lisp'
        let b:supported = 1
        return
    endif
    let b:supported = 0
endfunction


" Function: runner#ShowInfo(str) function
" Use to print info string.
" Args:
"   -str: string need to print.
function! runner#ShowInfo(str)
    if g:runner_show_info
        redraw
        echohl WarningMsg
        echo a:str
        echohl NONE
    else
        return
    endif
endfunction


" Function: runner#InitTmpDir() function
" Initialize temporary directory for products after compiling.
" Ref: http://vim.wikia.com/wiki/Automatically_create_tmp_or_backup_directories
function! runner#InitTmpDir()
    let b:tmp_dir = g:runner_tmp_dir
    if !isdirectory(b:tmp_dir)
        call mkdir(b:tmp_dir)
    endif
endfunction


" Function: runner#DoAll() function
" To do all subfunctions.
function! runner#DoAll()
    if b:supported
        call runner#Before()
        call runner#Compile()
        call runner#Run()
        call runner#After()
    else
        call runner#ShowInfo("   ❖  不支援  ❖ ")
    endif
endfunction


" Function: runner#Before() function
" To do something before compiling.
function! runner#Before()
    call runner#InitTmpDir()
    if g:runner_is_save_first
        execute "up"
    endif
    if g:runner_is_with_ale
        let b:runner_ale_status = get(g:, 'ale_enabled', 1)
        let g:ale_enabled = 0
    endif
    if g:runner_print_timestamp && b:ft !=# 'markdown'
        let l:date = strftime("%Y-%m-%d_%T")
        silent execute "!echo -e '\033[31m' "
        silent execute '!printf "<<<< \%s \%s >>>>\n" ' .
                    \l:date . " " . expand('%:t')
        silent execute "!echo -en '\033[0m'"
        if b:supported = 0
            execute "!echo -e ''"
        endif
    endif
endfunction


" Function: runner#Compile() function
" To do something when compiling.
function! runner#Compile()
    let b:tmp_name = strftime("%s")
    if b:ft ==# 'c'
        silent execute "!" . g:runner_c_executable . " " .
                    \ g:runner_c_compile_options .
                    \ " % -o " .
                    \ b:tmp_dir .
                    \ b:tmp_name .
                    \ ".out"
    elseif b:ft ==# 'cpp'
        silent execute "!" . g:runner_cpp_executable . " " .
                    \ g:runner_cpp_compile_options .
                    \ " % -o " .
                    \ b:tmp_dir .
                    \ b:tmp_name .
                    \ ".out"
    elseif b:ft ==# 'rust'
        if g:runner_rust_executable ==# "rustc"
            silent execute "!" . g:runner_rust_executable . " " .
                        \ g:runner_rust_compile_options .
                        \ " % -o " .
                        \ b:tmp_dir .
                        \ b:tmp_name .
                        \ ".out"
        endif
    elseif b:ft ==# 'python'
    elseif b:ft ==# 'lisp'
    endif
endfunction


" Function: runner#Run() function
" To do something when running.
function! runner#Run()
    if g:runner_print_time_usage
        let l:time = "time"
    else
        let l:time = ""
    endif
    if b:ft ==# 'c'
        execute "!" .
                    \ l:time . " "
                    \ b:tmp_dir .
                    \ b:tmp_name .
                    \ ".out " .
                    \ g:runner_c_run_options
    elseif b:ft ==# 'cpp'
        execute "!" .
                    \ l:time . " " .
                    \ b:tmp_dir .
                    \ b:tmp_name .
                    \ ".out" .
                    \ g:runner_cpp_run_options
    elseif b:ft ==# 'rust'
        if g:runner_rust_run_backtrace
            let l:rust_bt = "RUST_BACKTRACE=1"
        else
            let l:rust_bt = ""
        endif
        if g:runner_rust_executable ==# "rustc"
            execute "!" .
                        \ l:time . " " .
                        \ l:rust_bt . " " .
                        \ b:tmp_dir .
                        \ b:tmp_name .
                        \ ".out " .
                        \ g:runner_rust_run_options
        else
            execute "!" .
                        \ l:time . " " .
                        \ l:rust_bt . " " .
                        \ "cargo run"
        endif
    elseif b:ft ==# 'python'
        execute "!" .
                    \ l:time . " "
                    \ g:runner_python_executable .
                    \ " %"
    elseif b:ft ==# 'lisp'
        execute "!" .
                    \ l:time . " "
                    \ g:runner_lisp_executable .
                    \ " %"
    elseif b:ft ==# 'markdown'
        " markdown preview
        try
            " Stop before starting and handle exception
            execute "MarkdownPreviewStop"
        catch /^Vim:E492:/
            execute "MarkdownPreview"
        endtry
    endif
endfunction


" Function: runner#After() function
" To do something after running.
function! runner#After()
    if (b:ft ==# 'c' || b:ft ==# 'cpp') && g:runner_auto_remove_tmp
        silent execute "!rm " .
                    \ b:tmp_dir .
                    \ b:tmp_name .
                    \ ".out"
    endif
    if g:runner_is_with_ale
        let g:ale_enabled = b:runner_ale_status
    endif
endfunction