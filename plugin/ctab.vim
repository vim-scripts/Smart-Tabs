" Smart C tabs
" Author: Michael Geddes <michaelrgeddes@optushome.com.au>
" Version: 0.1

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
	return Column(matchstr(getline(a:lineNo),'^\s*'))
endfun

fun! s:IndentTo(n)
	let co=virtcol('.')
	let ico=StartColumn('.')+a:n
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

if 0
if exists('*PushOption')
  aug MRGIndentTo
  au!
  au User cppEnter call PushOption('imap <m-;>','<c-r>=IndentTo(20)<cr>// ')
  au User cEnter call PushOption('imap <m-;>','<c-r>=IndentTo(10)<cr>/*  */<c-o>:start<bar>norm 2h<cr>')
  au User cLeave,cppLeave call RestoreOptions()
  aug END
endif
endif

