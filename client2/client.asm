.386
.model flat, stdcall
;���ִ�Сд
option casemap :none

include ws2_32.inc
includelib ws2_32.lib
include kernel32.inc
includelib kernel32.lib
;include masm32.inc
includelib masm32.lib
;include wsock32.inc
;includelib wsock32.lib
include windows.inc
include user32.inc
;include Irvine32.inc
includelib user32.lib
include msvcrt.inc
includelib msvcrt.lib


ExitProcess PROTO STDCALL:DWORD
StdOut		PROTO STDCALL:DWORD
BufSize = 80

Str_length PROTO :PTR BYTE   
Str_merge PROTO :PTR BYTE,:PTR BYTE 
Str_copy PROTO :PTR BYTE,:PTR BYTE    
;msgParser PROTO :ptr byte,:ptr byte
AppendMsg PROTO :DWORD, :DWORD, :BYTE  
AppendFriend PROTO :DWORD, status:DWORD, ID:DWORD
ChangeFriendStatus PROTO :DWORD, :DWORD
parseFriendList PROTO :PTR BYTE

;==================== DATA =======================

.data
szConnect db "����",0
 
szDisConnect db "�Ͽ�",0
 
szErrSocket db "error !",0
szErrBind db"error bind !",0
szErrConnect db "error connect !",0
 
szAddr db "127.0.0.1",0
serverPort equ 6792
 
szClient db "Client: %s",0dh,0ah,0
szServer db "Server: %s",0dh,0ah,0

buffer BYTE BufSize DUP(?),0,0
stdInHandle HANDLE ?
bytesRead   DWORD ?

test_username byte "wangwang",0
test_password byte "password",0

hint_connect byte "You connect!",0dh,0ah,0
hint_fromServer byte "from server: ",0
hint_login byte "You are trying to login",0dh,0ah,0

signal_signin byte "1",0
signal_login byte "0",0
signal_sendtext byte "1 ",0
signal_addfriend byte "3",0
signal_getFriendList byte "4 ",0
signal_tab byte " ",0


test_msg byte "1 wangwang jkdfdhfjdshfdjsf",0
test_content byte 100 dup(?)
test_user byte 100 dup(?)

test_friendList byte "wangwang 0 qq 1 hdhhdfhh 0",0

connSocket dd  ?
userlist byte 1024 dup(?)


;=================== CODE =========================
.code

;------------------------------------------------------------------
msgParser PROC USES eax ebx edx,_buffer:ptr byte, _username:ptr byte,_content:ptr byte
; �������˷��ص���Ϣ
;------------------------------------------------------------------
	mov eax, _buffer
	mov bl, [eax]
	.if bl == 49
		 ; ������Ϣ����
		 mov edx, eax
		 add edx, 2
		 push edx
		 mov bl, [edx]
		 ; �����Է��û��������û��������û���������
		 .while bl != 0
			.if bl == 32                
				mov bl, 00
                dec edx
				mov [edx], bl
				mov eax, edx
				inc eax
				pop edx
				push eax
                invoke crt_strcpy,_username,edx
                ;invoke StdOut,_username
                ;invoke StdOut,addr szConnect
				;invoke nameToFd, edx, targetfd
				.break
			.endif
			mov bl, [edx]
			inc edx
		 .endw
		 pop edx
		 ; ����Ϣ�ı����Ƶ����ݻ�����
		 invoke crt_strcpy, _content, edx
		 ;mov eax, 1
         ;invoke StdOut,_content
         ;invoke StdOut,addr szConnect
         invoke AppendMsg,_username,_content,0
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
		 invoke crt_strcpy, _content, edx
		 mov eax, 2
		 ret
	.elseif bl == 51
		; �Ӻ���
		 mov edx, eax
		 add edx, 2
		 push edx
		 mov bl, [edx]
		 ; �����Է��û��������û��������û���������
		 .while bl != 0
			.if bl == 32                
				mov bl, 00
                dec edx
				mov [edx], bl
				mov eax, edx
				inc eax
				pop edx
				push eax
                invoke crt_strcpy,_username,edx
                ;invoke StdOut,_username
                ;invoke StdOut,addr szConnect
				;invoke nameToFd, edx, targetfd
				.break
			.endif
			mov bl, [edx]
			inc edx
		 .endw
		 pop edx
		 ; ����Ϣ�ı����Ƶ����ݻ�����
		 invoke crt_strcpy, _content, edx
		 mov eax, 1
         ;invoke StdOut,_content
         ;invoke StdOut,addr szConnect
         invoke AppendFriend,_username,_content,0
		ret
	.elseif bl == 52
		; ��������
		mov edx, eax
		add edx, 2
		invoke crt_strcpy, _username, edx
		mov eax, 3
        ; ����0�����ߣ�1������
        invoke ChangeFriendStatus,_username,1
		ret
	.elseif bl == 53
		; ��������
		mov edx, eax
		add edx, 2
		invoke crt_strcpy, _username, edx
		mov eax, 3
        ; ����0�����ߣ�1������
        invoke ChangeFriendStatus,_username,0
		ret
	.endif
	ret
msgParser ENDP


;------------------------------------------------------------------------------
chat_recvmsg PROC _hSocket
; �û��յ���������������Ϣ
; ��������Ϣ
;------------------------------------------------------------------------------
    LOCAL @szBuffer[1024]:byte
    LOCAL @username[20]:byte
    LOCAL @content[1024]:byte
    
    ; �����û��б�
	invoke RtlZeroMemory,addr userlist,sizeof userlist
	invoke recv,_hSocket,addr userlist,sizeof userlist,0
	invoke StdOut,addr hint_fromServer
	invoke StdOut,addr userlist

	.while TRUE
		invoke RtlZeroMemory,addr @szBuffer,sizeof @szBuffer
		invoke recv,_hSocket,addr @szBuffer,sizeof @szBuffer,0
        invoke StdOut,addr hint_fromServer
        invoke StdOut,addr @szBuffer
        ; ���ı����ݽ���һ���ж�ȡ
        invoke msgParser,addr @szBuffer,addr @username,addr @content

	.endw
    
    invoke closesocket,_hSocket
    ret

chat_recvmsg ENDP



;---------------------------------------------------------------
chat_login PROC username:PTR BYTE,password:PTR BYTE
; ���������׽��֣������������������͵�½ָ��û���������,�������߳̽�����Ϣ
; ����ɹ���¼��eax=1������Ϊ0
;---------------------------------------------------------------
    LOCAL @stWsa:WSADATA  
    LOCAL @szBuffer[256]:byte
    LOCAL @stSin:sockaddr_in

    invoke StdOut,addr hint_login
    invoke WSAStartup,101h,addr @stWsa
    ; �������׽��֣�����connSocket
    invoke socket,AF_INET,SOCK_STREAM,0
    ; ��������׽���ʧ�ܣ�������Ϣ��
    .if eax == INVALID_SOCKET
        invoke MessageBox,NULL,addr szErrSocket,addr szErrSocket,MB_OK
        mov eax,0
        ret
    .endif
    mov connSocket,eax

    ; ������������
    invoke RtlZeroMemory,addr @stSin,sizeof @stSin
    ; ת��ip
    invoke inet_addr,offset szAddr
    mov @stSin.sin_addr,eax   
    invoke htons,serverPort
    mov @stSin.sin_port,ax
    mov @stSin.sin_family,AF_INET
    invoke connect,connSocket,addr @stSin,sizeof @stSin
    ; ������ӳ��ִ��󣬵����Ի���
    .if eax == SOCKET_ERROR
        invoke WSAGetLastError
        .if eax != WSAEWOULDBLOCK
            invoke closesocket,connSocket;�ر��׽���
            mov connSocket,0
            invoke MessageBox,NULL,addr szErrConnect,addr szErrConnect,MB_OK
            mov eax,0
            ret
        .endif
    .endif

invoke StdOut,addr hint_connect
	;.while TRUE

	; ��ȡ��׼������
	;INVOKE GetStdHandle, STD_INPUT_HANDLE
	;mov    stdInHandle,eax
	; �ȴ��û�����
	;invoke RtlZeroMemory,addr buffer,sizeof buffer
	;INVOKE ReadConsole, stdInHandle, ADDR buffer,BufSize, ADDR bytesRead, 0
	;invoke CloseHandle,stdInHandle
	; ��ʾ������
	;mov    esi,OFFSET buffer
	;mov    ecx,bytesRead
	;mov    ebx,TYPE buffer
	;call    DumpMem
    ; �������
    ;invoke RtlZeroMemory,addr buffer,sizeof buffer
	;INVOKE ReadConsole, stdInHandle, ADDR buffer,BufSize, ADDR bytesRead, 0
    invoke send,connSocket,addr signal_login,1,0
invoke RtlZeroMemory,addr @szBuffer,sizeof @szBuffer
	invoke recv,connSocket,addr @szBuffer,sizeof @szBuffer,0
    invoke Str_length,username
	invoke send,connSocket,username,eax,0
invoke RtlZeroMemory,addr @szBuffer,sizeof @szBuffer
	invoke recv,connSocket,addr @szBuffer,sizeof @szBuffer,0
    invoke Str_length,password
	invoke send,connSocket,password,eax,0
invoke RtlZeroMemory,addr @szBuffer,sizeof @szBuffer
	invoke recv,connSocket,addr @szBuffer,sizeof @szBuffer,0
	;invoke CloseHandle,stdInHandle
	;.if eax == SOCKET_ERROR
	;invoke MessageBox,NULL,addr szErrSocket,addr szErrSocket,MB_OK
	;.endif
	;invoke StdOut,addr szAddr
	invoke RtlZeroMemory,addr @szBuffer,sizeof @szBuffer
	invoke recv,connSocket,addr @szBuffer,sizeof @szBuffer,0
	invoke StdOut,addr hint_fromServer
	invoke StdOut,addr @szBuffer


    ;����һ�����̼߳�����������Ϣ����
    invoke CreateThread,NULL,0,offset chat_recvmsg,connSocket,NULL,esp
    invoke CloseHandle,eax
   
    mov eax,1
    ret

chat_login ENDP



;---------------------------------------------------------------
chat_sign_in PROC username:PTR BYTE,password:PTR BYTE
; ���������׽��֣�������������������ע��ָ��û���������,�ر��׽���
; ����ɹ�ע�ᣬeax=1������Ϊ0
;---------------------------------------------------------------
    LOCAL @stWsa:WSADATA  
    LOCAL @szBuffer[256]:byte
    LOCAL @stSin:sockaddr_in
    invoke WSAStartup,101h,addr @stWsa
    ; �������׽��֣�����connSocket
    invoke socket,AF_INET,SOCK_STREAM,0
    ; ��������׽���ʧ�ܣ�������Ϣ��
    .if eax == INVALID_SOCKET
        invoke MessageBox,NULL,addr szErrSocket,addr szErrSocket,MB_OK
        mov eax,0
        ret
    .endif
    mov connSocket,eax

    ; ������������
    invoke RtlZeroMemory,addr @stSin,sizeof @stSin
    ; ת��ip
    invoke inet_addr,offset szAddr
    mov @stSin.sin_addr,eax   
    invoke htons,serverPort
    mov @stSin.sin_port,ax
    mov @stSin.sin_family,AF_INET
    invoke connect,connSocket,addr @stSin,sizeof @stSin
    ; ������ӳ��ִ��󣬵����Ի���
    .if eax == SOCKET_ERROR
        invoke WSAGetLastError
        .if eax != WSAEWOULDBLOCK
            invoke closesocket,connSocket;�ر��׽���
            mov connSocket,0
            invoke MessageBox,NULL,addr szErrConnect,addr szErrConnect,MB_OK
            mov eax,0
            ret
        .endif
    .endif

    invoke StdOut,addr hint_connect

    invoke send,connSocket,addr signal_signin,1,0
    invoke RtlZeroMemory,addr @szBuffer,sizeof @szBuffer
	invoke recv,connSocket,addr @szBuffer,sizeof @szBuffer,0
    invoke Str_length,username
	invoke send,connSocket,username,eax,0
    invoke RtlZeroMemory,addr @szBuffer,sizeof @szBuffer
	invoke recv,connSocket,addr @szBuffer,sizeof @szBuffer,0
    invoke Str_length,password
	invoke send,connSocket,password,eax,0
    invoke RtlZeroMemory,addr @szBuffer,sizeof @szBuffer
	invoke recv,connSocket,addr @szBuffer,sizeof @szBuffer,0
	;invoke CloseHandle,stdInHandle
	;.if eax == SOCKET_ERROR
	;invoke MessageBox,NULL,addr szErrSocket,addr szErrSocket,MB_OK
	;.endif
	;invoke StdOut,addr szAddr
	invoke RtlZeroMemory,addr @szBuffer,sizeof @szBuffer
	invoke recv,connSocket,addr @szBuffer,sizeof @szBuffer,0
	invoke StdOut,addr hint_fromServer
	invoke StdOut,addr @szBuffer


    invoke closesocket,connSocket  

    mov eax,1
    ret

chat_sign_in ENDP



;------------------------------------------------------------------------------
chat_sendmsg PROC username:PTR BYTE,sendmsg:PTR BYTE
; �û�������Ϣ,���뷢����Ϣ�Ķ����û���������Ҫ���͵���Ϣ: ���� 1 xiaohong xxxxxxxxx
; ���ͳɹ���eax=1
;------------------------------------------------------------------------------

    LOCAL @szBuffer[256]:byte

    invoke StdOut,addr szConnect
	invoke RtlZeroMemory,addr @szBuffer,sizeof @szBuffer
    invoke Str_copy,addr signal_sendtext,addr @szBuffer
    invoke Str_merge,addr @szBuffer, username
    invoke Str_merge,addr @szBuffer,addr signal_tab
    invoke Str_merge,addr @szBuffer,sendmsg	
    invoke StdOut,addr @szBuffer   
    invoke Str_length,addr @szBuffer
	invoke send,connSocket,addr @szBuffer,eax,0
    mov eax,1
    ret

chat_sendmsg ENDP



;------------------------------------------------------------------------------
chat_addFriend PROC username:PTR BYTE
; �û������ť��Ӻ���
; ����ָ� 3 xiaohong 
; ��������ɹ���eax=1������Ϊ0
;------------------------------------------------------------------------------

    LOCAL @szBuffer[256]:byte

	invoke RtlZeroMemory,addr @szBuffer,sizeof @szBuffer
    invoke Str_copy,addr signal_addfriend,addr @szBuffer
    invoke Str_merge,addr @szBuffer,addr signal_tab
    invoke Str_merge,addr @szBuffer,username
    invoke StdOut,addr @szBuffer
    invoke Str_length,addr @szBuffer
	invoke send,connSocket,addr @szBuffer,eax,0
    mov eax,1
    ret

chat_addFriend ENDP



;------------------------------------------------------------------------------
chat_getFriendList PROC 
; �û���ȡ�����б�
; ����ָ� 3 xiaohong 
; ��������ɹ���eax=1������Ϊ0
;------------------------------------------------------------------------------

    invoke parseFriendList,addr userlist
    mov eax,1
    ret

chat_getFriendList ENDP


;------------------------------------------------------------------------------
chat_sendimg PROC username:PTR BYTE
; �û������ť��Ӻ���
; ����ָ� 3 xiaohong 
;------------------------------------------------------------------------------

    LOCAL @szBuffer[256]:byte

	invoke RtlZeroMemory,addr @szBuffer,sizeof @szBuffer
    invoke Str_copy,addr signal_addfriend,addr @szBuffer
    invoke Str_merge,addr @szBuffer,addr signal_tab
    invoke Str_merge,addr @szBuffer,username
    invoke StdOut,addr @szBuffer
    invoke Str_length,addr @szBuffer
	invoke send,connSocket,addr @szBuffer,eax,0
    ret

chat_sendimg ENDP


mytest PROC
;invoke chat_login,addr test_username,addr test_password
;invoke chat_sendmsg, addr test_username,addr test_password
;invoke chat_addFriend,addr test_username
;invoke ExitProcess,0
;invoke msgParser,addr test_msg,addr test_user,addr test_content
invoke parseFriendList,addr test_friendList
invoke ExitProcess,0
mytest ENDP

END