" -*- vim -*-
" FILE: "/home/johannes/AppendComment.vim"
" MAINTAINER: Johannes Tanzler, <jtanzler@yline.com>
" LAST MODIFICATION: "Wed, 19 Sep 2001 22:52:50 +0200 (johannes)"
" VERSION: 0.02

" TODO
" * don't treat something as a comment which hasn't synID of a comment!
"   using 'synIDattr(synIDtrans(synID(line("."), col("."), 1)), "name")'?
" * make align work if the current comment is at a column > g:Comment_column
"   (or > 40).
" * if last thing in a line is '}' or '#endif', only insert 2 spaces (like
"   Emacsens do) and align it at this position, too.
"       }  // a comment
"       #endif // CURSES_H

" {{{
" Description:
" One thing I liked in Emacs is the ability to insert comments at the end of
" line using <M-;>. This simple script tries to achieve the same for Vim.
" Maybe your language is supported; nevertheless, it's easy to add new ones.
"
" This script was inspired by Meikel Brandmeyer's EnhCommentify.vim. Parts of
" this script are copied from him.


" AppendComment works this way:
" * If you press <M-;> in an empty line, the comment is inserted according to
"   the current indentation:
"
"   if
"   {
"     // ... I pressed <M-;> in this line
"   }
"   
" * If there's a statement in the line, it comment is inserted at
"   g:Comment_column:
"
"   foo_bar();                         // I pressed <M-;> in this line
"
" * If there's already a comment, it's aligned:
"
"   if                                  if
"   {                    <M-;> in       {
"   /* a comment */   <- this line  ->    /* a comment */
"   }                    results in     }
"
"
"   foo_bar();  /* a comment */
"     results in:
"   foo_bar();                         /* a comment */
"
" Normally, comments are inserted at line 40. You can modify this by setting
" the variable 'g:Comment_column', e.g in your ~/.vimrc file:
"
"   let g:Comment_column = 50

" Note:
" * Only use this script if you always insert a whitespace after a comment.
"   This scripts assumes that a comment is followed by a whitespace.
"   If you don't use a whitespace, this script will fail, because in some
"   languages, the comment symbol is used for other things, too. E.g. here in
"   Vim, a '"' can be a comment symbol _or_ a string delimiter.
" 
"   Because of this the '"' in statements like 'line(".")' would be treated as
"   comment symbols and the result of AppendComment() would be
" 
"       line(".                        ")
"       
"   instead of
"
"       line(".")                      " my comment
"
" * It doesn't work with multi-line comments
" * Please send a comment to <jtanzler@yline.com> if you like/dislike this
"   script and/or if you find a bug.


" Bugs:
" * Comment symbol inside Strings aren't recognized.
" * If there's a comment at col 0 and a comment at, say, col 30, alignment
"   will fail. E.g. in TeX
"   % comment1                  % comment2
"   will result in something like
"          % comment1                  % comment2
" * Bugfixing
" * Within HTML files: cursor placement after aligning doesn't work.

" Changes:
" * v0.02
"   + Bugfixing
"   + used strridx() instead of match() (we need the _last_ comment symbol
"   + A comment always has to be followed by a whitespace.
"   + Indentation is handled now.


" Installation:
" Place this script in your ~/.vim/plugin/ directory.
" }}}



if exists("DidAppendComment")
  finish
endif
let DidAppendComment = 1

" {{{
function! s:AppendComment()

  " Get current fileType
  let fileType = &ft

  " Languages with multipart comment symbols
  if fileType == 'c' || fileType == 'css'
    call s:Commentify('/*', '*/')
  elseif fileType == 'html' || fileType == 'xml'
    call s:Commentify('<!--', '-->')
  else
    " Languages with singlepart comment symbols
    if fileType == 'ox' || fileType == 'cpp' || fileType == 'php' 
          \ || fileType == 'java'
      let commentSymbol = '//'
    elseif fileType == 'vim'
      let commentSymbol = '"'
    elseif fileType == 'ruby' || fileType == 'python' || fileType == 'perl'
          \ || fileType =~ '[^w]sh$' || fileType == 'tcl'
      let commentSymbol = '#'
    elseif fileType == 'lisp' || fileType == 'scheme'
      let commentSymbol = ';'
    elseif fileType == 'tex'
      let commentSymbol = '%'
    elseif fileType == 'caos'
      let commentSymbol = '*'
    else
      let commentSymbol = ''
    endif 

    " If the language isn't supported, we do nothing
    if commentSymbol != ''
      call s:Commentify(commentSymbol)
    else
      execute 'echo "AppendComment has not (yet) been implemented for this file-type"'
      "startinsert
    endif
  endif
endfunction
"}}}

" Insert comment / align comment
" param: commentSymbol(s)
function! s:Commentify(commentSymbol, ...)
  let l = getline(line("."))
  
  " A comment is always followed by a whitespace.
  let cs = a:commentSymbol . " "

  " Position of last comment symbol:
  let cs_pos = strridx(l, cs)


  if cs_pos >= 0
    " There's a comment symbol, align it.
    
    let before_cs = strpart(l, 0, cs_pos)
    if before_cs =~ "^\\s\\+$" || before_cs =~ "^$"
      " If there's nothing or only whitespaces before the comment symbol,
      " align it according to Vim's current indentation
      normal ==
    else
      " Else align it at g:Comment_column
      let cs = <SID>Escape_string(cs)
      let spaces = s:Needed_spaces_align(cs_pos)
      sil exe ':s~' . before_cs . cs . '~' . before_cs . spaces . cs . '~'

      normal $
      exe 'normal F' . cs
      let length = strlen(cs)
      let length = length - 1          " whitespace!
      exe 'normal ' . length . 'l'
    endif
    
  else
    " There's no comment symbol, insert one.
    
    if l =~ "^\\s\\+$" || l =~ "^$"
      " If line is empty or only contains whitespaces, insert comment
      " symbol according to ':filetype indent on'
      normal m'
      sil exe ':s~$~' . cs . '~'
      normal ==                        " re-indent line
      normal ''
    else
      let spaces = s:Needed_spaces_insert()
      sil exe ':s~$~' . spaces . cs . '~'
    endif
                  
    " If an endsymbol is given, we insert it, too
    if a:0 == 1  
      sil exe ':s~$~' . ' ' . a:1 . '~'
      " Make sure the cursor is in the middle of the two symbols
      let length = strlen(a:1)
      normal $
      exe 'normal ' . length . 'h'
    else
      normal $
    endif
  endif
  startinsert

endfunction


" Return needed spaces for alignment
" param: Position of comment symbol
function! s:Needed_spaces_align(commentSymbol_position)
  let pos = a:commentSymbol_position
  let pos = pos + 1

  if exists("g:Comment_column")
    let com_col = g:Comment_column
  else
    let com_col = 40
  endif
  
  let needed_spaces = ''
  while pos < com_col
    let needed_spaces = needed_spaces . ' '
    let pos = pos + 1
  endwhile
  return needed_spaces
endfunction


" Return needed spaces for inserting
function! s:Needed_spaces_insert()
  " Get length of cursor line
  let column = col("$")

  if exists("g:Comment_column")
    let com_col = g:Comment_column
  else
    let com_col = 40
  
  if column < com_col
    let needed_spaces = com_col - column
  else
    let needed_spaces = 2 
  endif

  let i = 0
  let spaces = ""
  while i < needed_spaces
    let spaces = spaces . " "
    let i = i + 1
  endwhile

  return spaces
endfunction


" Return indentation of current line as spaces
function! s:Indent2spaces(line)
  let indent = indent(a:line)
  let i = 0
  let spaces = ''
    
  while i < indent
    let spaces = spaces . ' '
    let i = i + 1
  endwhile
  return spaces
endfunction


" Escape string
function! s:Escape_string(string)
  return escape(a:string, "\\*+{}[]()$^")
endfunction


" Key bindings: 
noremap <Plug>AppendComment :call <SID>AppendComment()<CR>
nmap <silent> <unique> <M-;> <Plug>AppendComment
imap <silent> <unique> <M-;> <Esc><Plug>AppendComment 
"nmap <silent> <M-;> <Plug>AppendComment
"imap <silent> <M-;> <Esc><Plug>AppendComment
