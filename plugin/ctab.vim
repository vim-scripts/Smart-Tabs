" Intelligent Indent
" Author: Michael Geddes <michaelrgeddes@optushome.com.au>
" Version: 1.0
"
" Histroy:
"   1.0:  Added RetabIndent command - similar to :retab, but doesn't cause
"   internal tabs to be modified.
"

" This is designed as a filetype plugin (originally a 'Buffoptions.vim' script).
"
" The aim of this script is to be able to handle the mode of tab usage which
" distinguishes 'indent' from 'alignment'.  The idea is to use <tab>
" characters only at the beginning of lines.
"
" This means that an individual can use their own 'tabstop' settings for the
" indent level, while not affecting alignment.
"
" The one caveat with this method of tabs is that you need to follow the rule
" that you never 'align' elements that have different 'indent' levels.
"
" :RetabIndent[!] [tabstop]
"     This is similar to the :retab command, with the exception that it
"     affects all and only whitespace at the start of the line, changing it to
"     suit your current (or new) tabstop and expandtab setting.
"     With the bang (!) at the end, the command also strips trailing
"     whitespace.

"if !exists('DoingSOURCE')
"  SO <sfile>
"  finish
"endif
" FileType:cpp,c,idl
imap <buffer> <tab> <c-r>=<SID>InsertSmartTab()<cr>

fun! s:InsertSmartTab()
  if strpart(getline('.'),0,col('.')-1) =~'^\s*$'
    return "\<Tab>"
  endif
  if exists("b:insidetabs")
    let sts=b:insidetabs
  else
    let sts=&sts
    if sts==0
      let sts=&sw
    endif
  endif
  let sp=(virtcol('.') % sts)
  if sp==0
    let sp=sts
  endif
  return strpart("                  ",0,1+sts-sp)
endfun


fun! s:Column(line)
  let c=0
  let i=0
  let len=strlen(a:line)
  while i< len
    if a:line[i]=="\<tab>" 
      let c=(c+&tabstop)
      let c=c-(c%&tabstop)
    else
      let c=c+1
    endif
    let i=i+1
  endwhile
  return c
endfun
fun! s:StartColumn(lineNo)
  return s:Column(matchstr(getline(a:lineNo),'^\s*'))
endfun

fun! s:IndentTo(n)
  let co=virtcol('.')
  let ico=s:StartColumn('.')+a:n
  if co>ico 
    let ico=co
  endif
  let spaces=ico-co
  let spc=""
  while spaces > 0
    let spc=spc." "
    let spaces=spaces-1
  endwhile
  return spc
endfun

" FileType:cpp,idl
if &filetype != 'c' 
imap <buffer> <m-;> <c-r>=<SID>IndentTo(20)<cr>// 
imap <buffer> <m-s-;> <c-r>=<SID>IndentTo(30)<cr>// 
imap <buffer> º <m-s-;>
endif

" FileType:c
if &filetype == 'c'
imap <buffer> <m-;> <c-r>=<SID>IndentTo(10)<cr>/*  */<c-o>:start<bar>norm 2h<cr>
endif

" Retab the indent of a file - ie only the first nonspace
fun! s:RetabIndent( bang, firstl, lastl, tab )
  let checkspace=((!&expandtab)? "^\<tab>* ": "^ *\<tab>")
  let l = a:firstl
  let force= a:tab != '' && a:tab != 0 && (a:tab != &tabstop)
  let newtabstop = (force?(a:tab):(&tabstop))
  while l <= a:lastl
    let txt=getline(l)
    let store=0
    if a:bang == '!' && txt =~ '\s\+$'
      let txt=substitute(txt,'\s\+$','','')
      let store=1
      let txtindent=''
    endif
    if force || txt =~ checkspace
      let i=indent(l)
      let tabs= (&expandtab ? (0) : (i / newtabstop))
      let spaces=(&expandtab ? (i) : (i % newtabstop))
      let txtindent=''
      while tabs>0 | let txtindent=txtindent."\<tab>" | let tabs=tabs-1| endwhile
      while spaces>0 | let txtindent=txtindent." " | let spaces=spaces-1| endwhile
      let store = 1
    endif
    if store | call setline(l, substitute(txt,'^\s*',txtindent,'')) | endif

    let l=l+1
  endwhile
  if newtabstop != &tabstop | let &tabstop = newtabstop | endif
endfun

" Retab the indent of a file - ie only the first nonspace.
"   Optional argumet specified the value of the new tabstops
"   Bang (!) causes trailing whitespace to be gobbled.
com! -nargs=? -range=% -bang -bar RetabIndent call <SID>RetabIndent(<q-bang>,<line1>, <line2>, <q-args> )

" vim: sts=2 sw=2 et
