" -*- vim -*-
" FILE: "/home/johannes/AppendComment.vim"
" MAINTAINER: Johannes Tanzler, <jtanzler@yline.com>
" LAST MODIFICATION: "Thu, 13 Sep 2001 00:00:08 +0200 (johannes)"
" VERSION: 0.01

" Description:
" One thing I liked in Emacs is the ability to insert comments at the end of
" line using <M-;>. This simple script tries to achieve the same for Vim.
" If there's already a comment after an expression, it's aligned.
"
" Maybe your language is supported; nevertheless, it's easy to add new ones.
"
" This script was inspired by Meikel Brandmeyer's EnhCommentify.vim. A lot of
" code was copied from him.

" Installation:
" Place this script in your ~/.vim/plugin/ directory.


" TODO:
" * If filetype isn't supported, there are some bugs:
"   + insert mode is turned on, nevertheless
"     (because of the 'i' at the end of the following command:
"     'nmap <silent> <unique> <M-;> <Plug>AppendCommenti')
"   + Because of this, the message 'AppendComment has not (yet)
"     implemented...' is displayed too short (overwritten by -- INSERT --)
"



if exists("DidAppendComment")
  finish
endif
let DidAppendComment = 1


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
    endif
  endif
endfunction


" Insert comment / align comment
" param: commentSymbol(s)
function! s:Commentify(commentSymbol, ...)

  " Some substitution needed for C's '/*':
  let cs = substitute(a:commentSymbol, '/', '\\/', '')
  let cs = substitute(a:commentSymbol, '*', '\\*', '')

  " Position of comment symbol:
  let cs_pos = match(getline(line(".")), cs)
  
  " cs und cs_pos passen!
  "exe ':s~^~' . cs . ' at pos ' . cs_pos . '!~g' 
  "return

   

  " If line contains a comment symbol (not a pos 0!), align it
  " Else, insert comment symbol
  if cs_pos > 0
    
    let spaces = s:Needed_spaces_align(cs_pos)
    sil exe ':s~' . cs . '~' . spaces . cs . '~'  
    
  else 
    let spaces = s:Needed_spaces_insert()
    sil exe ':s~$~' . spaces . a:commentSymbol . '  ~'

    " If a endsymbol is given, we insert it, too
    if a:0 == 1
      sil exe ':s~$~' .  a:1 . '~'
      " Make sure the cursor is in the middle of the two symbols
      let length = strlen(a:1)
      exe 'normal $' . length . 'h'
    else
      exe 'normal $'
    endif    
  endif

endfunction


" Return needed spaces for alignment
" @param: Position of comment symbol
function! s:Needed_spaces_align(commentSymbol_position)
  let pos = a:commentSymbol_position
  let pos = pos + 1

  let needed_spaces = ''
  while pos < 40
    let needed_spaces = needed_spaces . ' '
    let pos = pos + 1
  endwhile
  return needed_spaces
endfunction


" Return needed spaces for inserting
function! s:Needed_spaces_insert()
  " Get length of cursor line
  let column = col("$")

  if column < 40
    let needed_spaces = 40 - column
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



" Key bindings: 

noremap <Plug>AppendComment :call <SID>AppendComment()<CR>
nmap <silent> <unique> <M-;> <Plug>AppendCommenti
imap <silent> <unique> <M-;> <Esc><Plug>AppendCommenti


