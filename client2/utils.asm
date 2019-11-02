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
		 ; ������Ϣ����
		 mov edx, eax
		 add edx, 2
		 push edx
		 mov bl, [edx]
		 ; �����Է��û���
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
		 ; ����Ϣ�ı����Ƶ����ݻ�����
		 invoke crt_strcpy, content, edx
		 mov eax, 1
		 ret
	.elseif bl == 49
		; ͼƬ��Ϣ����
		mov edx, eax
		 add edx, 2
		 push edx
		 mov bl, [edx]
		 ; �����Է��û���
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
		 ; ��ͼƬ���ݣ������ƣ����Ƶ����ݻ�����
		 invoke crt_strcpy, content, edx
		 mov eax, 2
		 ret
	.elseif bl == 50
		; �Ӻ���
		mov edx, eax
		add edx, 2
		invoke crt_strcpy, content, edx
		mov eax, 3
		ret
	.endif
	ret
_msgParser ENDP

;--------------------------------------------------------
Str_length PROC USES edi, pString:PTR BYTE       ;ָ���ַ���
;�õ��ַ�������
;���룺�ַ�����ַ
;�������eax
;--------------------------------------------------------
    mov edi, pString       ;�ַ�������
    mov eax, 0             ;�ַ�������
L1: cmp BYTE PTR[edi],0
    je L2                  ;�ǣ��˳�
    inc edi                ;��ָ����һ���ַ�
    inc eax                ;��������1
    jmp L1
L2: ret
Str_length ENDP



;--------------------------------------
Str_copy PROC USES eax ecx esi edi,
    source:PTR BYTE,       ; source string
    target:PTR BYTE        ; target string
;���ַ�����Դ�����Ƶ�Ŀ�Ĵ���
;Ҫ��Ŀ�괮�������㹻�ռ����ɴ�Դ�������Ĵ���
;--------------------------------------
    INVOKE Str_length, source      ;EAX = Դ������
    mov ecx, eax                   ;�ظ�������
    inc    ecx                     ;���������ֽڣ��������� 1
    mov esi, source
    mov edi, target
    cld                            ;����Ϊ����
    rep    movsb                   ;�����ַ���
    ret
Str_copy ENDP



;---------------------------------------------------
Str_merge PROC USES eax edx,firstPart:PTR BYTE,secondPart:PTR BYTE
;�ַ���ƴ��
;Ҫ��Ŀ�괮�������㹻�ռ����ɴ�Դ�������Ĵ���
;---------------------------------------------------

	invoke Str_length,firstPart
	mov edx,firstPart
	add edx,eax
	invoke Str_copy,secondPart,edx
    ret

Str_merge ENDP



;----------------------------------------------------------
parseFriendList PROC USES edx ebx edi,_buffer:PTR BYTE
;����������ַ�������ȡ�����б��䵱ǰ״̬
;̫���ˣ���������������������������print��stdout��RtlZeroMemory�����޸�edx��ֵ����������
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
			; ���Ϊ�ո�
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