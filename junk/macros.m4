changequote(`[',`]')dnl
dnl
dnl
define([K4_BEGIN_IMAGE],[
	.section .data
_image_begin:])dnl
dnl
define([K4_END_IMAGE],[
_image_end:])
dnl
dnl
dnl
dnl
define([K4_QUOTE], [ifelse([$#],
		    [0], [], [[$*]])])dnl
dnl
define([K4_FORLOOP],
	[ifelse(eval([($3) >= ($2)]),[1],
		[pushdef([$1],eval([$2]))_K4_FORLOOP([$1],
		eval([$3]),[$4])popdef([$1])])])dnl
dnl
define([_K4_FORLOOP],
	[$3[]ifelse(indir([$1]),[$2],[],
  		[define([$1],incr(indir([$1])))$0($@)])])dnl
dnl
define([K4_FIRST_L],[$1])dnl
dnl
define([K4_REST_L],[shift($@)])dnl
dnl
define([K4_FOREACH],[ifelse($2,,,
	pushdef([$1])_K4_FOREACH($@)popdef([$1]))])dnl
dnl
define([_K4_FOREACH],
	[ifelse([$2],(),[],
		[define([$1],[K4_FIRST_L$2])$3[]$0([$1],(K4_REST_L$2),[$3])])])dnl
dnl
define([K4_REVERSE_L],
	[ifelse([$1],[],[],[$0(shift($@))[]ifelse($2,[],[],[,])$1])])dnl
dnl		
define([K4_INDENT],[	])dnl
dnl
define([K4_NL],[
]) dnl
define([K4_RESET_ARGS],
	[define([K4_NARG],0)])dnl
dnl
define([K4_INCR_ARGS],
	[define([K4_NARG],incr(K4_NARG))])dnl
dnl
define([K4_PUSH_ARG],[
	push $1[]K4_INCR_ARGS[]])dnl
dnl
define([K4_PUSH_ALL_ARGS],
	[K4_RESET_ARGS[]K4_FOREACH(arg,(K4_REVERSE_L($@)),
		[K4_PUSH_ARG(arg)])])
dnl
define([K4_CALL],
	[K4_PUSH_ALL_ARGS(shift($@))
	call $1[]ifelse(K4_NARG,0,,[
	addl $[]eval(K4_NARG*4),%esp[]])])dnl
dnl
define([K4_SAFE_CALL],[
[#** CALL]($*)
	pushal dnl
	K4_CALL($@)
	movl %eax,28(%esp)
	popal
[#** CALL_END]
])dnl
dnl
define([K4_REMOVE_TRAILING_WHITES],
	[patsubst($1,
	[[ 	
	]+$],[])])dnl
dnl
define([K4_REMOVE_LEADING_WHITES],
	[patsubst($1,
		[^[ 	
		]+],[])])dnl
dnl
define([K4_REPLACE_WHITES_WITH_COMMA],
	[patsubst($1,
		[[ 	
		]+],[,])])dnl
dnl
define([K4_MAKE_LIST],
	[K4_REPLACE_WHITES_WITH_COMMA(K4_REMOVE_TRAILING_WHITES(K4_REMOVE_LEADING_WHITES($1)))])dnl
dnl
define([DICT],[_dict])dnl
define([VTAB],[_vtab])dnl
define([NTAB],[_ntab])dnl
dnl
define([BEGIN_DICT],
	[define([WORD_COUNT],0)dnl
	DICT:])dnl
dnl
define([PTR],[ptr[]$1])dnl
dnl
define([DEF_NTAB_ENTRY],
	[define([NTAB_C_ENTRY$1],
		$3)[]define([NTAB_ENTRY$1],
		$2)[]define([WORD_BCODE$3],$1)])dnl
dnl
define([DEF_IMM_ENTRY],
	[define([IMM_ENTRY$1],1)])dnl
dnl
define([INCR_WORD_COUNT], [define([WORD_COUNT],incr(WORD_COUNT))][])dnl
dnl
define([WORD_COMMENT], [[######## Word: ]"$1"[]K4_NL[]])dnl
dnl
define([WORD_HEADER],
	[WORD_COMMENT($1)
	.set PTR(WORD_COUNT), . - DICT
	.long ifelse($3,WORD,
	      [_docol],
	      [PTR(WORD_COUNT) + 4 + _dict])
___$2:[]DEF_NTAB_ENTRY(WORD_COUNT,$1,$2)[]INCR_WORD_COUNT[]])dnl
dnl
define([WORD_HEADER_STRIP],[INCR_WORD_COUNT[]])dnl
dnl
define([DEF_CODE], [WORD_HEADER($1,$2)[]])dnl
dnl
define([DEF_CODE_STRIP], [ifdef([LOADER],[WORD_HEADER_STRIP($1,$2)],
				[WORD_HEADER($1,$2)])ifdef([LOADER],,K4_QUOTE(])
dnl
define([END_CODE],[
	jmp _next_word])dnl
dnl
define([END_CODE_STRIP],[)) ifdef([LOADER],,
			    [jmp _next_word[]K4_NL[]K4_NL[]K4_NL])])dnl
dnl
define([EMIT_BCODE],
	[K4_FOREACH(arg,($@),[
	.byte ifelse(regexp(arg,[\<[0-9]+]),-1,
		WORD_BCODE[]arg,
	      	[ifelse(eval(arg>127 || arg<-128),0,
	      			    [WORD_BCODElit8s
	      			    .byte arg],
	      			    [WORD_BCODElit32
	      			    .long arg])])])])dnl
dnl
define([DEF_WORD],
	[WORD_HEADER($1,$2,WORD)dnl
	EMIT_BCODE(K4_MAKE_LIST([]])dnl
dnl
define([DEF_WORD_STRIP],
	[ifdef([LOADER],
		[WORD_HEADER_STRIP($1,$2,WORD)[]ifdef([],],
			[][WORD_HEADER($1,$2,WORD)[]EMIT_BCODE(K4_MAKE_LIST(])])dnl
dnl
define([DEF_WORD_BYTEC],
	[WORD_HEADER($1,$2,WORD)])dnl
define([END_WORD_BYTEC],
	[])dnl
dnl
define([END_WORD],[))])dnl
define([END_WORD_STRIP],
	[ifdef([LOADER],[)],[))])])dnl
dnl
define([DEF_IMM_C],
	[DEF_IMM_ENTRY($2)[]DEF_WORD_STRIP($@)])dnl
dnl
define([END_IMM_C],
	[ifdef([LOADER],[)],[))])])dnl
dnl
define([DEF_IMM],
	[WORD_HEADER($1,$2,WORD)[]DEF_IMM_ENTRY($2)[]EMIT_BCODE(K4_MAKE_LIST([]])dnl
dnl
define([END_IMM],[))])dnl
dnl
define([DEF_VAR_B],
	[DEF_CODE($1,$2)
	push $_var_$2
	jmp _next_word
_var_$2:[].byte $3])dnl
dnl
define([DEF_VAR_L],
	[DEF_CODE($1,$2)push $_var_$2
	jmp _next_word
_var_$2:    .long $3])dnl
dnl
define([DEF_VAR_B_C],
	[DEF_CODE_STRIP($1,$2)
	push $_var_$2
	END_CODE_STRIP
	ifdef([LOADER],,
		[_var_$2:	.byte $3])])dnl
dnl
define([DEF_VAR_L_C],
	[DEF_CODE_STRIP($1,$2)[]push $_var_$2
	END_CODE_STRIP[]
	ifdef([LOADER],,
		[_var_$2:[]	.long $3])])dnl
dnl
define([END_DICT],
	[dnl DEF_CODE([toplevel],toplevel)
	_interpret_bcode:	.byte decr(WORD_COUNT), 1
dnl	END_CODE
]
	[ifdef([LOADER],.fill 32,
			      [_u_dic:	
			      	.fill DICT_SIZE
				.long 0])
	VTAB: K4_FORLOOP(arg,0,decr(WORD_COUNT),
		[ifdef(NTAB_ENTRY[]arg,
			[.short PTR(arg)[]K4_NL[]],
			[.short 0[]K4_NL])])
	VTAB[]_end:[]
	ifdef([LOADER],,
		[.fill DICT_SIZE
		.long 0])
dnl		_interpret_bcode:	.byte decr(WORD_COUNT), 1
	ifdef([LOADER],,
		[NTAB:[]K4_FORLOOP(arg,0,decr(WORD_COUNT),
			[.ascii "indir(NTAB_ENTRY[]arg)"[]
			.fill NTAB_ENTRY_SIZE-eval(len(indir(NTAB_ENTRY[]arg))+1)
			.byte ifdef(IMM_ENTRY[]indir(NTAB_C_ENTRY[]arg),1,0)
			])[]undefine([WORD_COUNT])NTAB[]_end:
	.fill DICT_SIZE[]
])dnl
	K4_END_IMAGE])
dnl
dnl
define([K4_IFDEF],[ifdef([$1],K4_QUOTE(])dnl
dnl
define([K4_IFNDEF],[ifdef([$1],,K4_QUOTE(])dnl
dnl
define([K4_ENDIF],[))])dnl
dnl
define([DEF_IMPORT],
	[DEF_CODE($1,$1)dnl
	 push $[]$1 
	 push $[]$2
	 END_CODE])dnl
dnl
define([K4_SAVE_CONTEXT],[
	mov	%esp,_vm_context_ESP
	mov	$(_vm_context_reg+32),%esp
	pushal
	mov	_vm_context_ESP,%esp])dnl
dnl
define([K4_RESTORE_CONTEXT],[
	mov	%eax,(_vm_context_reg+28)
	mov	$(_vm_context_reg),%esp
	popal
	mov	_vm_context_ESP,%esp])dnl
dnl
dnl
.set __prev_word_ptr,0
define([def_code],[
	.long	1f
	.long __prev_word_ptr
	.set __prev_word_ptr, . - 8
	.ascii "$1"
	.fill NTAB_ENTRY_SIZE-eval(len($1)+1)
	.byte 0
1:
])
define([end_code],[
	jmp	_next_word
])	
	
