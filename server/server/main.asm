.386
.model flat, stdcall
;区分大小写
option casemap :none

include ws2_32.inc
includelib ws2_32.lib
include kernel32.inc
includelib kernel32.lib
;include masm32.inc
includelib masm32.lib
;include wsock32.inc
includelib wsock32.lib
include windows.inc
include user32.inc
includelib user32.lib
include masm32rt.inc
include msvcrt.inc
;include irvine32.inc

ExitProcess PROTO STDCALL:DWORD
StdOut		PROTO STDCALL:DWORD

writeNewUser PROTO :PTR BYTE,:PTR BYTE
writeNewFriend PROTO :PTR BYTE,:PTR BYTE
ifLogged PROTO :PTR BYTE
ifFriends PROTO: PTR BYTE,:PTR BYTE
ifPasswordRight PROTO :PTR BYTE,:PTR BYTE
MemSetZero PROTO: PTR BYTE,:DWORD

;==================== DATA =======================
.data
szConnect db "连接",0
 
szDisConnect db "断开",0
 
szErrSocket db "error !",0
szErrBind db"error bind !",0

hint_start db "start listening!",0dh,0ah,0
 
szAddr db "127.0.0.1",0
serverPort equ 6792
 
szClient db "Client: %s",0dh,0ah,0
szServer db "Server: %s",0dh,0ah,0

typeCodeZero db "0", 0
typeCodeOne db "1", 0
typeCodeTwo db "2", 0
typeCodeThree db "3", 0
typeCodeFour db "4", 0

dwThreadCounter dd ?
dwFlag dd ?
F_STOP dd ?
hWinMain dd ?

IDC_COUNT equ 40002
IDD_DIALOG1 equ 102

listenSocket dd  ?
; write connection socket for each client
connSocket dd 20 DUP(?)

loginSuccess db "success", 0
loginFailure db "fail", 0

msgFormat1 db "%s %s %s", 0

client STRUCT
	username db 64 DUP(?)
	sockfd dd ?
	status dd 0
client ENDS

threadParam STRUCT
	sockid dd ?
	clientid dd ?
threadParam ENDS

clientlist client 100 DUP(<>)
clientnum dd 0

;=================== CODE =========================
.code

stringCopy PROC src:ptr byte, tgt:ptr byte
	push eax
	push ebx
	push ecx
	mov eax, src
	mov ecx, tgt
	mov bl, [eax]
	.while bl != 0
		mov [ecx], bl
		inc eax
		inc ecx
	.endw
	mov bl, 0
	mov [ecx], bl
	pop ecx
	pop ebx
	pop eax
	ret
stringCopy ENDP


stringCmp PROC str1:ptr byte, str2:ptr byte
	LOCAL @str1:ptr byte
	LOCAL @str2:ptr byte
	mov eax, str1
	mov @str1, eax
	mov eax, str2
	mov @str2, eax
	mov edx, @str1
	mov al, [edx]
	mov edx, @str2
	mov bl, [edx]
	.while (al != 0) && (bl != 0)
		.if al != bl
			mov eax, 0
			ret
		.endif
		inc @str1
		inc @str2
		mov edx, @str1
		mov al, [edx]
		mov edx, @str2
		mov bl, [edx]
	.endw
	.if (al == 0) && (bl == 0)
		mov eax, 1
		ret
	.endif
	mov eax, 0
	ret
stringCmp ENDP


nameToFd PROC nameStr:ptr byte, targetfd:ptr dword
	LOCAL @cursor:dword
	mov eax, clientnum
	mov @cursor, 0
	mov ebx, @cursor
	.while ebx < eax
		.if clientlist[ebx].status == 1
			push ebx
			invoke stringCmp, addr clientlist[ebx].username, nameStr
			pop ebx
			.if eax == 1
				mov eax, clientlist[ebx].sockfd
				mov edx, targetfd
				mov [edx], eax
				mov eax, 1
				ret
			.endif
		.endif
		inc @cursor
		mov ebx, @cursor
		mov eax, clientnum
	.endw
	mov eax, 0
	sub eax, 1
	mov edx, targetfd
	mov [edx], eax
	mov eax, 0
	ret
nameToFd ENDP


msgParser PROC buffer:ptr byte, targetfd:ptr dword, content:ptr byte
	mov eax, buffer
	mov bl, [eax]
	.if bl == 0
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
				invoke nameToFd, edx, targetfd
				.break
			.endif
			mov bl, [edx]
			inc edx
		 .endw
		 pop edx
		 ; 将消息文本复制到内容缓冲区
		 invoke stringCopy, content, edx
		 mov eax, 1
		 ret
	.elseif bl == 1
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
				invoke nameToFd, edx, targetfd
				.break
			.endif
			mov bl, [edx]
			inc edx
		 .endw
		 pop edx
		 ; 将图片内容（二进制）复制到内容缓冲区
		 invoke stringCopy, content, edx
		 mov eax, 2
		 ret
	.elseif bl == 2
		; 加好友
		mov edx, eax
		add edx, 2
		invoke stringCopy, content, edx
		mov eax, 3
		ret
	.endif
msgParser ENDP

serviceThread PROC params:PTR threadParam
	LOCAL @stFdset:fd_set,@stTimeval:timeval
	LOCAL @szBuffer[1024]:byte
	LOCAL @type:dword
	LOCAL @currentSock:dword
	LOCAL @currentUsername[64]:byte
	LOCAL @targetSockfd:dword
	LOCAL @msgContent[512]:byte
	LOCAL @msgField[1024]:byte
	LOCAL _hSocket:DWORD
	LOCAL _clientid:DWORD
	push esi
	push eax
	mov esi, params
	mov eax, (threadParam PTR [esi]).sockid
	mov _hSocket, eax
	mov eax, (threadParam PTR [esi]).clientid
	mov _clientid, eax
	invoke stringCopy, addr (clientlist[eax].username), addr @currentUsername
	pop esi
	inc dwThreadCounter
	print "enter thread", 13, 30
	; TODO 返回好友列表
	invoke SetDlgItemInt,hWinMain,IDC_COUNT,dwThreadCounter,FALSE
	.while  TRUE
		mov @stFdset.fd_count,1
		push _hSocket
		pop @stFdset.fd_array
		mov @stTimeval.tv_usec,200*1000 ;ms
		mov @stTimeval.tv_sec,0
		invoke select, 0, addr @stFdset, NULL, NULL, addr @stTimeval
		.if eax == SOCKET_ERROR
			.break
		.endif
		.if eax
			invoke recv, _hSocket, addr @szBuffer, 512, 0
			invoke StdOut, addr @szBuffer
			.break  .if eax == SOCKET_ERROR
			.break  .if !eax
			; 解析消息
			invoke msgParser, addr @szBuffer, addr @targetSockfd, addr @msgContent
			.if eax == 49
				; 文字消息类型
				invoke send, @targetSockfd, addr @msgContent, eax, 0
				.break  .if eax == SOCKET_ERROR
			.elseif eax == 50
				; 图片消息类型
				invoke send, @targetSockfd, addr @msgContent, eax, 0
				.break  .if eax == SOCKET_ERROR
			.elseif eax == 51
				; 加好友
				invoke ifLogged, addr @msgContent
				.if eax == 1
					; 用户存在
					; 检查二人是否已经是好友
					invoke ifFriends, addr @msgContent, addr @currentUsername
					.if eax == 0
						; 两人不是好友 可以添加
						invoke writeNewFriend, addr @msgContent, addr @currentUsername
						; 检查另一方是否在线，如在线，向双方广播
						invoke nameToFd, addr @msgContent, addr @targetSockfd
						.if eax == 1
							; 对方在线，需对双方广播

							; 向当前用户广播
							invoke MemSetZero, addr @msgField, 1024
							; sprintf(msg, "%s %s %s", "3", name, "1")
							invoke crt_sprintf, addr @msgField, addr msgFormat1, addr typeCodeThree, addr @msgContent, addr typeCodeOne
							invoke send, _hSocket, addr @msgField, sizeof @msgField, 0

							; 向好友广播
							invoke MemSetZero, addr @msgField, 1024
							; sprintf(msg, "%s %s %s", "3", name, "1")
							invoke crt_sprintf, addr @msgField, addr msgFormat1, addr typeCodeThree, addr @currentUsername, addr typeCodeOne
							invoke send, @targetSockfd, addr @msgField, sizeof @msgField, 0

						.else
							; 对方不在线，只需对一方广播
							; 向当前用户广播
							invoke MemSetZero, addr @msgField, 1024
							; sprintf(msg, "%s %s %s", "3", name, "0")
							invoke crt_sprintf, addr @msgField, addr msgFormat1, addr typeCodeThree, addr @msgContent, addr typeCodeZero
							invoke send, _hSocket, addr @msgField, sizeof @msgField, 0
						.endif
						invoke send, _hSocket, addr loginSuccess, sizeof loginSuccess, 0
					.else
						; 已有该好友，添加失败
						invoke send, _hSocket, addr loginFailure, sizeof loginFailure, 0
					.endif
				.else
					; 用户不存在，加好友失败
					invoke send, _hSocket, addr loginFailure, sizeof loginFailure, 0
				.endif
			.endif
		.endif
	.endw
	invoke closesocket,_hSocket
	dec dwThreadCounter
	invoke SetDlgItemInt,hWinMain,IDC_COUNT,dwThreadCounter,FALSE
	ret
serviceThread ENDP

login PROC sockfd:dword
	LOCAL @username[512]:byte
	LOCAL @password[512]:byte
	LOCAL @type[10]:byte
	invoke MemSetZero, addr @username, 512
	invoke MemSetZero, addr @password, 512
	invoke MemSetZero, addr @type, 10
	print "connected", 13, 10
	; 接受类型
	invoke recv, sockfd, addr @type, sizeof @type, 0
	invoke StdOut,addr @type
	;print " ", 13, 10
	invoke send, sockfd, addr loginSuccess, sizeof loginSuccess, 0
	; 接受用户名
	invoke recv, sockfd, addr @username, sizeof @username, 0
	;print "finish username", 13, 10
	invoke StdOut,addr @username
	;print " ", 13, 10
	invoke send, sockfd, addr loginSuccess, sizeof loginSuccess, 0
	; 接受密码
	invoke recv, sockfd, addr @password, sizeof @password, 0
	invoke StdOut,addr @password
	;print " ", 13, 10
	invoke send, sockfd, addr loginSuccess, sizeof loginSuccess, 0
	; 判断类型
	mov al, @type
	.if al == 48
		; 登录请求

		; 检查用户名是否存在
		invoke ifLogged, addr @username
		.if eax == 0
			; 用户名不存在 登录失败
			invoke send, sockfd, addr loginFailure, sizeof loginFailure, 0
			mov eax, 0
			ret
		.endif
		; 检查密码是否正确
		invoke ifPasswordRight, ADDR @username, ADDR @password
		.if eax == 1
			; 密码正确 登录成功
			invoke send, sockfd, addr loginSuccess, sizeof loginSuccess, 0

			; 写入当前在线用户列表
			mov eax, clientnum
			mov ebx, type client
			mul ebx
			add eax, offset clientlist
			push eax
			mov ebx, offset client.username
			add eax, ebx
			push eax
			mov edx, eax
			invoke MemSetZero, edx, 64
			pop edx
			invoke crt_strcpy, edx, addr @username
			mov eax, sockfd
			pop edx
			mov clientlist[edx].sockfd, eax
			mov clientlist[edx].status, 1
			inc clientnum
			mov eax, 1
			ret
		.else
			; 密码错误 登录失败
			invoke send, sockfd, addr loginFailure, sizeof loginFailure, 0
			mov eax, 0
			ret
		.endif
	.else
		; 注册请求
		print "type signin", 13, 10

		invoke ifLogged, addr @username
		push eax
		print "checked", 13, 10
		pop eax
		.if eax == 0
			; 用户名不存在 可以注册
			print "start write", 13, 10
			invoke writeNewUser, addr @username, addr @password
			invoke send, sockfd, addr loginSuccess, sizeof loginSuccess, 0
			mov eax, 0
			ret
		.else
			; 用户名已存在 注册失败
			invoke send, sockfd, addr loginFailure, sizeof loginFailure, 0
			mov eax, 0
			ret
		.endif
	.endif
	
	invoke send, sockfd, addr loginFailure, sizeof loginFailure, 0
	mov eax, 0
	ret
login ENDP



sign_in PROC sockfd:dword
	LOCAL @username[512]:byte
	LOCAL @password[512]:byte
	invoke recv, sockfd, addr @username, sizeof @username, 0
	; 处理用户名
	invoke recv, sockfd, addr @password, sizeof @password, 0
	; 处理密码
	; isExisted
	; createUser
	;invoke isExisted, @username
	.if eax == 0
		;invoke createUser, @username, @password
		.if eax == 1
			invoke send, sockfd, addr loginSuccess, sizeof loginSuccess, 0
			mov eax, 1
			ret
		.endif
	.endif
	invoke send, sockfd, addr loginFailure, sizeof loginFailure, 0
	mov eax, 0
	ret
sign_in ENDP


main PROC
    LOCAL @stWsa:WSADATA  
    LOCAL @szBuffer[256]:byte
    LOCAL @stSin:sockaddr_in
	LOCAL @connSock:dword
	LOCAL @param_to_thread:threadParam
    invoke WSAStartup,101h,addr @stWsa
    ;创建流套接字
    invoke socket,AF_INET,SOCK_STREAM,0
    .if eax == INVALID_SOCKET
        invoke MessageBox,NULL,addr szErrSocket,addr szErrSocket,MB_OK
        ret
    .endif
    mov listenSocket,eax
    invoke RtlZeroMemory,addr @stSin,sizeof @stSin
    invoke htons,serverPort
    mov @stSin.sin_port,ax
    mov @stSin.sin_family,AF_INET
    mov @stSin.sin_addr,INADDR_ANY
    invoke bind,listenSocket,addr @stSin,sizeof @stSin
    .if eax
		invoke MessageBox,NULL,addr szErrBind,addr szErrBind,MB_OK
		invoke ExitProcess,NULL
    .endif
    ; start listening
    invoke listen,listenSocket,5
    invoke StdOut,addr hint_start
    .while TRUE
		push ecx
		invoke accept, listenSocket, NULL, 0
        ;mov connSocket,eax
        ;invoke recv,connSocket,addr @szBuffer,sizeof @szBuffer,0
        ;invoke StdOut,addr @szBuffer
        ;invoke StdOut,addr hint_start
		.if eax==INVALID_SOCKET
			.break
        .endif
		mov @connSock, eax
        ;mov connSocket,eax
        ;invoke recv,connSocket,addr @szBuffer,sizeof @szBuffer,MSG_PEEK
        ;invoke StdOut,addr @szBuffer
        ;invoke send,connSocket,addr @szBuffer,sizeof @szBuffer,0

		; 判断请求是注册还是登录
		invoke login, @connSock
		.if eax == 1
			mov @param_to_thread.sockid, eax
			mov @param_to_thread.clientid, edx
			invoke CreateThread, NULL, 0, offset serviceThread, addr @param_to_thread, NULL, esp
		.endif
        pop ecx
        invoke CloseHandle,eax
    .endw
    invoke closesocket,listenSocket
    ;invoke ExitProcess,0
main ENDP

main2 PROC
    LOCAL @stWsa:WSADATA  
    LOCAL @stSin:sockaddr_in
	LOCAL @stFdset:fd_set, @stTimeval:timeval, @stFdread:fd_set
	LOCAL @szBuffer[512]:byte
	LOCAL @i:dword
	LOCAL @msgBuffer[1024]:byte
    invoke WSAStartup,101h,addr @stWsa
    ;创建流套接字
    invoke socket,AF_INET,SOCK_STREAM,0
    .if eax == INVALID_SOCKET
        invoke MessageBox,NULL,addr szErrSocket,addr szErrSocket,MB_OK
        ret
    .endif
    mov listenSocket,eax
    invoke RtlZeroMemory,addr @stSin,sizeof @stSin
    invoke htons,serverPort
    mov @stSin.sin_port,ax
    mov @stSin.sin_family,AF_INET
    mov @stSin.sin_addr,INADDR_ANY
    invoke bind,listenSocket,addr @stSin,sizeof @stSin
    .if eax
		invoke MessageBox,NULL,addr szErrBind,addr szErrBind,MB_OK
		invoke ExitProcess,NULL
    .endif
    ; start listening
    invoke listen,listenSocket,5
    invoke StdOut,addr hint_start
	
    .while TRUE
		mov @stFdset.fd_count,1
		push listenSocket
		pop @stFdset.fd_array
		mov @stTimeval.tv_usec,200*1000 ;ms
		mov @stTimeval.tv_sec,0
		; 调用select开始循环
		invoke select,0,addr @stFdset,NULL,NULL,addr @stTimeval
		.if eax == SOCKET_ERROR
			.break
		.endif
		mov @i, 0
		; 在监听列表中循环
		mov ecx, @stFdset.fd_count
		;.while @i < @stFdset.fd_count
		L1:
			push ecx
			invoke __WSAFDIsSet, @stFdset.fd_array[@i], addr @stFdset
			.if eax == 0
				.break
			.endif
			mov eax, @stFdset.fd_array[@i]
			.if eax == listenSocket
				; 新连入用户
				invoke accept,listenSocket,NULL,0
				;linvoke fdset, eax, addr @stFdset
			.else
			.endif
			add @i, 1
			pop ecx
		loop L1
	.endw
main2 ENDP

END main