
include masm32rt.inc
;include msvcrt.inc
;includelib msvcrt.lib



.data
relativePathHead byte "./userInfo/",0
fileTail byte ".txt",0
txtName byte 256 dup (0)
my_tab byte " ",0


.code

;--------------------------------------------------------
myPrint PROC pString:PTR BYTE
;��ӡ�ַ���
;--------------------------------------------------------
    LOCAL handle:DWORD        
    LOCAL bwrt:DWORD
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov handle,eax
  ; �����̨дһ���ַ���
    INVOKE WriteConsole,
      handle,          ; ����̨������
      ADDR pString,           ; �ַ���ָ��
      sizeof pString,            ; �ַ�����
      bwrt,      ; ��������ֽ���
      0                       ; δʹ��
    ret
myPrint ENDP


;--------------------------------------------------------
MemSetZero PROC str1:PTR BYTE, str_len:DWORD
;���ڴ�ռ�����Ϊ0
;str1 �׵�ַ
;len ����
	push ecx
	push eax
	push edx
	mov ecx, str_len
	mov edx, str1
	mov al, 0
Lmemsetzero1:
	mov [edx], al
	inc edx
	loop Lmemsetzero1
	pop edx
	pop eax
	pop ecx
	ret
MemSetZero ENDP


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



;----------------------------------------------------------
Str_copy PROC USES eax ecx esi edi,
    source:PTR BYTE,       ; source string
    target:PTR BYTE        ; target string
;���ַ�����Դ�����Ƶ�Ŀ�Ĵ���
;Ҫ��Ŀ�괮�������㹻�ռ����ɴ�Դ�������Ĵ���
;-----------------------------------------------------------
    INVOKE Str_length, source      ;EAX = Դ������
    mov ecx, eax                   ;�ظ�������
    inc    ecx                     ;���������ֽڣ��������� 1
    mov esi, source
    mov edi, target
    cld                            ;����Ϊ����
    rep    movsb                   ;�����ַ���
    ret
Str_copy ENDP



;-----------------------------------------------------------
getUserFileName PROC USES eax ecx,username:PTR BYTE
;��ø��û������ļ�·��
;д��txtName
;-----------------------------------------------------------
    ;ƴ���ļ�·���ַ���
    invoke RtlZeroMemory,addr txtName,sizeof txtName
    invoke Str_copy ,addr relativePathHead,addr txtName
    mov ecx,offset txtName
    invoke Str_length,addr relativePathHead
    add ecx,eax
    invoke Str_copy,username, ecx
    invoke Str_length,username
    add ecx,eax
    invoke Str_copy,addr fileTail,ecx
    ret 
getUserFileName ENDP


;--------------------------------------------------------------
writeNewUser PROC USES eax, username:PTR BYTE,password:PTR BYTE
;��һ���µ��û�д��userInfo�ļ����е�allUsers.txt��
;���������û���txt�ļ���¼��
;��һ��Ϊ���룻�ڶ��м��Ժ�Ϊ��������
;�������û���������
;--------------------------------------------------------------

    LOCAL @hFile :DWORD                          ; file handle          
    LOCAL @cloc  :DWORD                          ; current location variable

    invoke getUserFileName, username

    mov @hFile, fopen("./userInfo/allUsers.txt")            ; open the allUsers file
    mov @cloc, fseek(@hFile,0,FILE_END)           ; set the file pointer to the end
    fprint @hFile,username    ; append username to existing data
    fclose @hFile                                ; close the file

    mov @hFile, fcreate(addr txtName)          ; create the USER.txt
    fprint @hFile,password    ; append password to existing data
    fclose @hFile                                ; close the file
   
    ret

writeNewUser ENDP


;-------------------------------------------------------------
writeNewFriend PROC USES eax, user1:PTR BYTE,user2:PTR BYTE
;����������Ϣд��˫��txt�ļ���
;-------------------------------------------------------------
    LOCAL @hFile :DWORD                          ; file handle          
    LOCAL @cloc  :DWORD                          ; current location variable
    LOCAL bwrt  :DWORD                          ; variable for bytes written

    invoke getUserFileName, user1
    mov @hFile, fopen(addr txtName)        
    mov @cloc, fseek(@hFile,0,FILE_END)         
    fprint @hFile,user2 
    ;mov bwrt, fwrite(hFile,t,len(txt))
    
    fclose @hFile                

    invoke getUserFileName, user2
    mov @hFile, fopen(addr txtName)         
    mov @cloc, fseek(@hFile,0,FILE_END)       
    fprint @hFile,user1    
    fclose @hFile                          
   
    ret

writeNewFriend ENDP


;-------------------------------------------------------------
ifLogged PROC  username:PTR BYTE
; ���û������룬����Ƿ�ע���
; ���ע���eax=1����֮Ϊ0
;-------------------------------------------------------------       

    invoke getUserFileName, username
    .if rv(exist,ADDR txtName) != 0               ; test if file exists
		mov eax,1
    .else
		mov eax,0                      
    .endif
    ret

ifLogged ENDP



;----------------------------------------------------------------
Str_compare_my PROC USES ecx edx esi edi,str1:PTR BYTE,str2:PTR BYTE
; �Ƚ������ַ����Ƿ����
; ���������ַ�����ַ
;----------------------------------------------------------------

	LOCAL str1_len:DWORD
	LOCAL str2_len:DWORD

	invoke Str_length,str1
	mov edx,eax
	mov str1_len,edx
	invoke Str_length,str2
	cmp edx,eax
	mov str2_len,edx
	jne outno
	; ����������
	mov ecx,edx
	; eax��str1��ַ��ebx��str2��ַ
	mov eax,str1
	mov ebx,str2
	mov ecx,0

myloop:
	push eax
	push ebx
	mov al,[eax]
	mov bl,[ebx]
	cmp al,bl
	pop ebx
	pop eax
	jne outno
	inc ecx
	inc eax
	inc ebx
	cmp ecx,str1_len
	jne myloop

outyes:
    ; print������޸�eaxֵ
	;print "string equal!",13,10
	mov eax,0
	jmp outover

outno:
	;print "string not equal!",13,10
	mov eax,1
	jmp outover

outover:
	ret

Str_compare_my ENDP



;-------------------------------------------------------------
ifFriends PROC  user1:PTR BYTE,user2:PTR BYTE
; �����������֣���������Ƿ�Ϊ����;***Ĭ�������û�����ע�ᣬ�����ҵ��ļ���¼***
; �������eax=1,����eax=0
;-------------------------------------------------------------       

    LOCAL @hFile :DWORD                          ; file handle          
    LOCAL @bwrt  :DWORD                          ; variable for bytes written
    LOCAL @flen  :DWORD                          ; file length variable
    LOCAL @hMem  :DWORD                          ; allocated memory handle
    LOCAL @cloc  :DWORD
    LOCAL br   :DWORD
    LOCAL @word:DWORD
    invoke getUserFileName, user1
    mov @hFile, fopen(addr txtName)        
  ; -------------------------------------------------
  ; open the file , read its content
  ; -------------------------------------------------
    mov @flen,fsize(@hFile)                     ; get its length
    mov @hMem, alloc(@flen)                       ; allocate a buffer of that size
    mov @word,alloc(20)
    mov @cloc,0

    ; ���ı����ݶ����ڴ���
    mov @bwrt, fread(@hFile,@hMem,@flen)
    ; ���ı����ݽ���һ���ж�ȡ
	invoke readline,@hMem,@word,0
    ; Stdout���Ҳ���޸�eax��ֵ
	;invoke StdOut,@word
	;inc eax
	;inc eax
	mov @cloc,eax

myloop:
	invoke readline,@hMem,@word,@cloc
	; �ж��Ƿ������ readline������־��eaxΪ0
	cmp eax,0
	je outno
	;������ǣ�����ѭ��
	;inc eax
	;inc eax
	mov @cloc,eax
	;invoke StdOut,@word
	; �Ƚ��Ƿ�һ��
	invoke Str_compare_my,@word,user2
	cmp eax,0
	je outyes
	jmp myloop

outyes:
    fclose @hFile
    ; �ͷ��ڴ�
    free @hMem                                   
    free @word
	mov eax,1
    jmp outover

outno:
    fclose @hFile
    ; �ͷ��ڴ�
    free @hMem                                   
    free @word
	mov eax,0
	jmp outover

outover:   
    
    ret

ifFriends ENDP



;-------------------------------------------------------------
ifPasswordRight PROC  username:PTR BYTE,password:PTR BYTE
; �����û��������룬����Ƿ���ȷ
; �����ȷ��eax=1������eax=0
;-------------------------------------------------------------       

    LOCAL @hFile :DWORD                          ; file handle          
    LOCAL @bwrt  :DWORD                          ; variable for bytes written
    LOCAL @flen  :DWORD                          ; file length variable
    LOCAL @hMem  :DWORD                          ; allocated memory handle
    LOCAL @word  :DWORD
    invoke getUserFileName, username
    mov @hFile, fopen(addr txtName)        
  ; -------------------------------------------------
  ; open the file , read its content
  ; -------------------------------------------------
    mov @flen,fsize(@hFile)                     ; get its length
    mov @hMem, alloc(@flen)                       ; allocate a buffer of that size
    mov @word,alloc(20)

    ; ���ı����ݶ����ڴ���
    mov @bwrt, fread(@hFile,@hMem,@flen)
    ; ���ı����ݵ�һ�н��ж�ȡ
	invoke readline,@hMem,@word,0
    invoke Str_compare_my,@word,password
	cmp eax,0
    jne outno

outyes:
    fclose @hFile
    ; �ͷ��ڴ�
    free @hMem                                   
    free @word
	mov eax,1
    jmp outover

outno:
    fclose @hFile
    ; �ͷ��ڴ�
    free @hMem                                   
    free @word
	mov eax,0
	jmp outover

outover:   
    
    ret

ifPasswordRight ENDP



;--------------------------------------------------------------
;���������û���Ϣ��д���ڴ���
initializeUserInfo  PROC

initializeUserInfo  ENDP


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


;--------------------------------------------------------------
readAllFriends PROC _username:PTR BYTE,_buffer:PTR BYTE
;������Ҫ��ȡ�û��б���û�������������û��б���Ϣ���ַ���ָ��
; ��ʽ��ͬ�� xxx xxx xxxx
;���û����к�����Ϣд���ַ���ָ���ַ
;--------------------------------------------------------------

    LOCAL @hFile :DWORD                          ; file handle          
    LOCAL @bwrt  :DWORD                          ; variable for bytes written
    LOCAL @flen  :DWORD                          ; file length variable
    LOCAL @hMem  :DWORD                          ; allocated memory handle
    LOCAL @cloc  :DWORD
    LOCAL br   :DWORD
    LOCAL @word:DWORD
	;invoke StdOut, _username
	invoke MemSetZero, addr txtName, 256
    invoke getUserFileName, _username
	;invoke StdOut, addr txtName
    mov @hFile, fopen(addr txtName)        
  ; -------------------------------------------------
  ; open the file , read its content
  ; -------------------------------------------------
    mov @flen,fsize(@hFile)                      ; get its length
    mov @hMem, alloc(1024)                       ; allocate a buffer of that size
    mov @word,alloc(20)
    mov @cloc,0

	invoke MemSetZero, @word, 20
	invoke MemSetZero, @hMem, 1024
    ; ���ı����ݶ����ڴ���
    mov eax, fread(@hFile,@hMem,@flen)
	mov @bwrt, eax
    ; ���ı����ݽ���һ���ж�ȡ
	invoke readline,@hMem,@word,0
    ; Stdout���Ҳ���޸�eax��ֵ
	;invoke StdOut,@word
	;inc eax
	;inc eax
	mov @cloc,eax

	invoke readline,@hMem,@word,@cloc
	; �ж��Ƿ������ readline������־��eaxΪ0
	cmp eax,0
	je outno
	mov @cloc,eax
    invoke Str_merge,_buffer,@word

myloop:
	invoke readline,@hMem,@word,@cloc
	; �ж��Ƿ������ readline������־��eaxΪ0
	cmp eax,0
	je outno
	mov @cloc,eax
    invoke Str_merge,_buffer,addr my_tab
    invoke Str_merge,_buffer,@word   
	jmp myloop


outno:
    fclose @hFile
    ; �ͷ��ڴ�
    free @hMem                                   
    free @word
    invoke StdOut,_buffer
	mov eax,0
    
    ret

readAllFriends ENDP


end
