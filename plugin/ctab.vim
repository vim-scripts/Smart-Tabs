" Intelligent Indent
" Author: Michael Geddes < vimmer at frog dot wheelycreek dot net >
" Version: 2.0
" Last Modified: 4 June 2009
"
" Histroy:
"   1.0: - Added RetabIndent command - similar to :retab, but doesn't cause
"         internal tabs to be modified.
"   1.1: - Added support for backspacing over spaced tabs 'smarttab' style
"        - Clean up the look of it by blanking the :call
"        - No longer a 'filetype' plugin by default.
"   1.2: - Interactions with 'smarttab' were causing problems. Now fall back to
"          vim's 'smarttab' setting when inserting 'indent' tabs.
"        - Fixed compat with digraphs (which were getting swallowed)
"        - Made <BS> mapping work with the 'filetype' plugin mode.
"        - Make CTabAlignTo() public.
"   1.3: - Fix removing trailing spaces with RetabIndent! which was causing
"          initial indents to disappear.
"   1.4: - Fixed Backspace tab being off by 1
"   2.0: - Add support for alignment whitespace for mismatched brackets to be spaces.
"   2.1: - Fix = operator
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
"
"  CTabAlignTo(n)
"     'Tab' to the n'th column from the start of the indent.

" g:ctab_filetype_maps
"   set this to true for the maps to be <buffer> specific
" g:ctab_disable_checkalign
"   set this to true to disable re-check of alignment



if  exists('g:ctab_filetype_maps') && g:ctab_filetype_maps
  " FileType:cpp,c,idl
  "imap <buffer> <tab> <c-r>=<SID>InsertSmartTab()<cr>
  "inoremap <buffer> <BS> <c-r>=<SID>DoSmartDelete()<cr><BS>
  imap <expr> <buffer> <tab> <SID>InsertSmartTab()
  inoremap <expr> <buffer> <BS> <SID>DoSmartDelete()."\<BS>"

  " FileType:cpp,idl
  if (&filetype =~ '^\(cpp\|idl\)$' )
    imap <buffer> <m-;> <c-r>=CTabAlignTo(20)<cr>//
    imap <buffer> <m-s-;> <c-r>=CTabAlignTo(30)<cr>//
    imap <buffer> º <m-s-;>
  endif

  " FileType:c
  if &filetype == 'c'
    imap <buffer> <m-;> <c-r>=CTabAlignTo(10)<cr>/*  */<c-o>:start<bar>norm 2h<cr>
  endif
else
  "imap <tab> <c-r>=<SID>InsertSmartTab()<cr>
  " inoremap <BS> <c-r>=<SID>DoSmartDelete()<cr><BS>
  imap <expr> <tab> <SID>InsertSmartTab()
  inoremap <expr> <BS> <SID>DoSmartDelete()."\<BS>"
endif

" Insert a smart tab.
fun! s:InsertSmartTab()
  " Clear the status
  echo ''
  if strpart(getline('.'),0,col('.')-1) =~'^\s*$' | return "\<Tab>" | endif

  let sts=exists("b:insidetabs")?(b:insidetabs):((&sts==0)?&sw:&sts)
  let sp=(virtcol('.') % sts)
  if sp==0 | let sp=sts | endif
  return strpart("                  ",0,1+sts-sp)
endfun


" Do a smart delete.
" The <BS> is included at the end so that deleting back over line ends
" works as expected.
fun! s:DoSmartDelete()
  " Clear the status
  "echo ''
  let uptohere=strpart(getline('.'),0,col('.')-1)
  " If at the first part of the line, fall back on defaults... or if the
  " preceding character is a <TAB>, then similarly fall back on defaults.
  "
  let lastchar=matchstr(uptohere,'.$')
  if lastchar == "\<tab>" || uptohere =~ '^\s*$' | return '' | endif        " Simple cases
  if lastchar != ' ' | return ((&digraph)?("\<BS>".lastchar): '')  | endif  " Delete non space at end / Maintain digraphs

  " Work out how many tabs to use
  let sts=(exists("b:insidetabs")?(b:insidetabs):((&sts==0)?(&sw):(&sts)))

  let ovc=virtcol('.')              " Find where we are
  let sp=(ovc % sts)                " How many virtual characters to delete
  if sp==0 | let sp=sts | endif     " At least delete a whole tabstop
  let vc=ovc-sp                     " Work out the new virtual column
  " Find how many characters we need to delete (using \%v to do virtual column
  " matching, and making sure we don't pass an invalid value to vc)
  let uthlen=strlen(uptohere)
  let bs= uthlen-((vc<1)?0:(  match(uptohere,'\%'.(vc-1).'v')))
  let uthlen=uthlen-bs
  " echo 'ovc = '.ovc.' sp = '.sp.' vc = '.vc.' bs = '.bs.' uthlen='.uthlen
  if bs <= 0 | return  '' | endif

  " Delete the specifed number of whitespace characters up to the first non-whitespace
  let ret=''
  let bs=bs-1
  if uptohere[uthlen+bs] !~ '\s'| return '' | endif
  while bs>=-1
    let bs=bs-1
    if uptohere[uthlen+bs] !~ '\s' | break | endif
    let ret=ret."\<BS>"
  endwhile
  return ret
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

fun! CTabAlignTo(n)
  let co=virtcol('.')
  let ico=s:StartColumn('.')+a:n
  if co>ico
    let ico=co
  endif
  let spaces=ico-co
  let spc=''
  while spaces > 0
    let spc=spc." "
    let spaces=spaces-1
  endwhile
  return spc
endfun

if ! exists('g:ctab_disable_checkalign') || g:ctab_disable_checkalign==0
  " Check the alignment of line.
  " Used in the case where some alignment whitespace is required .. like for unmatched brackets.
  fun! s:CheckAlign(line)
    if &expandtab
      return ''
    endif

    let tskeep=&ts
    let swkeep=&sw
    try
      set ts=50
      set sw=50
      if &indentexpr != ''
        let v:lnum=a:line
        sandbox exe 'let inda='.&indentexpr
        if inda == -1
          let inda=indent(a:line-1)
        endif
      elseif &cindent
        let inda=cindent(a:line)
      elseif &smarttab
        return ''
      endif
    finally
      let &ts=tskeep
      let &sw=swkeep
    endtry
    let indatabs=inda / 50
    let indaspace=inda % 50
    let indb=indent(a:line)
    if indatabs*&tabstop + indaspace == indb
      let txtindent=repeat("\<Tab>",indatabs).repeat(' ',indaspace)
      call setline(a:line, substitute(getline(a:line),'^\s*',txtindent,''))
    endif
    return ''
  endfun
  if  exists('g:ctab_filetype_maps') && g:ctab_filetype_maps
    inoremap <buffer> <CR> <CR><c-r>=<SID>CheckAlign(line('.'))."\<lt>END>"<CR>
    nnoremap <buffer> o o<c-r>=<SID>CheckAlign(line('.'))."\<lt>END>"<CR>
    nnoremap <buffer> O O<c-r>=<SID>CheckAlign(line('.'))."\<lt>END>"<CR>
    map <buffer> <expr> = <SID>SetupEqual()
  else
    " Get the spaces at the end of the  indent correct.
    " This is trickier than it should be, but this seems to work.
    inoremap <CR> <CR><c-r>=<SID>CheckAlign(line('.'))."\<lt>END>"<CR>
    nnoremap o o<c-r>=<SID>CheckAlign(line('.'))."\<lt>END>"<CR>
    nnoremap O O<c-r>=<SID>CheckAlign(line('.'))."\<lt>END>"<CR>

    " Ok.. now re-evaluate the = re-indented section

    " The only way I can think to do this is to remap the =
    " so that it calls the original, then checks all the indents.
    map <expr> = <SID>SetupEqual()
  endif
  fun! s:SetupEqual()
    set operatorfunc=CtabRedoIndent
    " Call the operator func so we get the range
    return 'g@'
  endfun

endif

fun! CtabRedoIndent(type,...)
  set operatorfunc=
  let ln=line("'[")
  let lnto=line("']")
  " Do the original equals
  norm! '[=']

  if ! &et
    " Then check the alignment.
    while ln <= lnto
      call s:CheckAlign(ln)
      let ln+=1
    endwhile
  endif
endfun

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
    endif
    if force || txt =~ checkspace
      let i=indent(l)
      let tabs= (&expandtab ? (0) : (i / newtabstop))
      let spaces=(&expandtab ? (i) : (i % newtabstop))
      let txtindent=repeat("\<tab>",tabs).repeat(' ',spaces)
      let store = 1
      let txt=substitute(txt,'^\s*',txtindent,'')
    endif
    if store | call setline(l, txt ) | endif

    let l=l+1
  endwhile
  if newtabstop != &tabstop | let &tabstop = newtabstop | endif
endfun


" Retab the indent of a file - ie only the first nonspace.
"   Optional argumet specified the value of the new tabstops
"   Bang (!) causes trailing whitespace to be gobbled.
com! -nargs=? -range=% -bang -bar RetabIndent call <SID>RetabIndent(<q-bang>,<line1>, <line2>, <q-args> )

" vim: sts=2 sw=2 et
