include masm32rt.inc
include msvcrt.inc
includelib msvcrt.lib

AppendFriend PROTO :DWORD, status:DWORD, ID:DWORD


;==================== DATA =======================

.data

hint byte "test",0
hint_parserfriend byte "start parse friends",0dh,0ah,0

;=================== CODE =========================
.code

_msgParser PROC USES eax ebx,buffer:ptr byte, content:ptr byte
	mov eax, buffer
	mov bl, [eax]

	.if bl == 48
		 ; 文字消息类型
		 mov edx, eax
		 add edx, 2
		 push edx
		 mov bl, [edx]
		 ; 解析对方用户名
		 .while bl != 0
			.if bl == 32
				mov bl, 0
				mov [edx], bl
				mov eax, edx
				inc eax
				pop edx
				push eax
				;invoke nameToFd, edx, targetfd
				.break
			.endif
			mov bl, [edx]
			inc edx
		 .endw
		 pop edx
		 ; 将消息文本复制到内容缓冲区
		 invoke crt_strcpy, content, edx
		 mov eax, 1
		 ret
	.elseif bl == 49
		; 图片消息类型
		mov edx, eax
		 add edx, 2
		 push edx
		 mov bl, [edx]
		 ; 解析对方用户名
		 .while bl != 0
			.if bl == 32
				mov bl, 0
				mov [edx], bl
				mov eax, edx
				inc eax
				pop edx
				push eax
				;invoke nameToFd, edx, targetfd
				.break
			.endif
			mov bl, [edx]
			inc edx
		 .endw
		 pop edx
		 ; 将图片内容（二进制）复制到内容缓冲区
		 invoke crt_strcpy, content, edx
		 mov eax, 2
		 ret
	.elseif bl == 50
		; 加好友
		mov edx, eax
		add edx, 2
		invoke crt_strcpy, content, edx
		mov eax, 3
		ret
	.endif
	ret
_msgParser ENDP

;--------------------------------------------------------
Str_length PROC USES edi, pString:PTR BYTE       ;指向字符串
;得到字符串长度
;传入：字符串地址
;结果存入eax
;--------------------------------------------------------
    mov edi, pString       ;字符计数器
    mov eax, 0             ;字符结束？
L1: cmp BYTE PTR[edi],0
    je L2                  ;是：退出
    inc edi                ;否：指向下一个字符
    inc eax                ;计数器加1
    jmp L1
L2: ret
Str_length ENDP



;--------------------------------------
Str_copy PROC USES eax ecx esi edi,
    source:PTR BYTE,       ; source string
    target:PTR BYTE        ; target string
;将字符串从源串复制到目的串。
;要求：目标串必须有足够空间容纳从源复制来的串。
;--------------------------------------
    INVOKE Str_length, source      ;EAX = 源串长度
    mov ecx, eax                   ;重复计数器
    inc    ecx                     ;由于有零字节，计数器加 1
    mov esi, source
    mov edi, target
    cld                            ;方向为正向
    rep    movsb                   ;复制字符串
    ret
Str_copy ENDP



;---------------------------------------------------
Str_merge PROC USES eax edx,firstPart:PTR BYTE,secondPart:PTR BYTE
;字符串拼接
;要求：目标串必须有足够空间容纳从源复制来的串。
;---------------------------------------------------

	invoke Str_length,firstPart
	mov edx,firstPart
	add edx,eax
	invoke Str_copy,secondPart,edx
    ret

Str_merge ENDP



;----------------------------------------------------------
parseFriendList PROC USES edx ebx edi,_buffer:PTR BYTE
;解析传入的字符串，获取好友列表及其当前状态
;太坑了！！！！！！！！！！！！！！print和stdout和RtlZeroMemory都会修改edx的值。。。。。
;----------------------------------------------------------
	LOCAL @username[100]:DWORD
	LOCAL @status[10]:DWORD
	LOCAL @pos:DWORD

			push edx
			invoke StdOut,addr hint_parserfriend
			pop edx
	mov edx,_buffer
	mov @pos,edx
	mov bl,[edx]

	.while TRUE
		.if bl==0
			.break
		.endif
		.if bl==32
			; 如果为空格
			mov bl,0
			mov [edx],bl

            push edx
			invoke RtlZeroMemory,addr @username,sizeof @username
			invoke RtlZeroMemory,addr @status,sizeof @status
			invoke crt_strcpy,addr @username,@pos
			push edx
			invoke StdOut,addr @username
			pop edx
            pop edx

			inc edx
			mov @pos,edx
			inc edx
			mov bl,[edx]

			.if bl==0
				invoke Str_copy,@pos,addr @status
				push edx
				invoke StdOut,addr @status
				pop edx
				.break
			.elseif bl==32
				mov bl,0
				mov [edx],bl
				invoke Str_copy,@pos,addr @status
				push edx
				invoke StdOut,addr @status
				pop edx
			.endif

            pushad
			;invoke AppendFriend,@username,@status,0
            popad	
	
			inc edx
			mov @pos,edx
			dec edx
		.endif

		inc edx
		mov bl,[edx]
	.endw

	ret

parseFriendList ENDP



END 