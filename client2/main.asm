.386
.model flat,stdcall
option casemap:none

include windows.inc
include gdi32.inc
includelib gdi32.lib
include user32.inc
includelib user32.lib
include kernel32.inc
includelib kernel32.lib
include comctl32.inc
includelib comctl32.lib
include msvcrt.inc
includelib msvcrt.lib


.data
hInstance dd ?
hWinMain dd ?
hFont dd ?
hBrush dd ?
hListView dd ?
hUsernameEdit dd ? 
hPasswordEdit dd ? 
hSendButton dd ?
hEdit dd ?
hNewEdit dd ?
ptrCurUser dd 0
ptrUsers dd 0

strUsername db 128 DUP(0)
strPassword db 128 DUP(0)

USER STRUCT
	ID dd 0
	username dd 0
	status dd 0
	row dd 0
	hEdit dd 0
	pNext dd 0
USER ENDS

.const
szMsftedit db 'Msftedit.dll', 0
szLogWindow db 'LogWindow',0
szText db 'Hello, world!',0
szStatic db 'STATIC',0
szButton db 'BUTTON',0
szEdit db 'EDIT',0
szUsername db 'Username', 0
szPassword db 'Password', 0
szLogin db 'Log in', 0
szLogon db 'Log on', 0

szClientWindow db 'ClientWindow',0
szClient db 'Client', 0
WC_LISTVIEW db 'SysListView32', 0
RICHEDIT50W db 'RICHEDIT50W', 0
szID db 'ID', 0
szStatus db 'Status', 0
szHello db 'Hello, ', 0
szSend db 'Send', 0
newLine db 0Dh,0Ah,0
szMe db 'Me', 0
szColon db ':', 0
szNew db 'New', 0
szAddfriend db 'Add friend ', 0
szSuccess db ' success!', 0
szFailed db ' failed!', 0
szShell32 db 'shell32.dll', 0
szOnline db 'Online', 0
szOffline db 'Offline', 0

.code

chat_login PROTO :ptr byte,:ptr byte

chat_sign_in PROTO :ptr byte, :ptr byte

chat_getFriendList PROTO

addFriend PROC username:ptr byte
	mov eax, 1
	ret
addFriend ENDP

CreateUserLabel PROC, Username:DWORD
	local buffer[128]:BYTE
	invoke crt_strcpy, addr buffer, addr szHello
	invoke crt_strcat, addr buffer, Username
	invoke CreateWindowEx, NULL, addr szStatic, addr buffer,
	WS_CHILD or WS_VISIBLE or SS_CENTER or SS_CENTERIMAGE, 10, 10, 300, 20,
	hWinMain, 1, hInstance, NULL
	invoke SendMessage, eax, WM_SETFONT, hFont, 0
	ret
CreateUserLabel ENDP

CreateListView PROC USES eax esi edi
	local @col:LVCOLUMN
	local @hShell:HMODULE
	local @hIcon:HICON
	local @hImageList:HIMAGELIST
	; ��ʼ��ͼ���
	invoke LoadLibrary, addr szShell32
	mov @hShell, eax
	invoke LoadIcon, @hShell, 17
	mov @hIcon, eax
	invoke GetSystemMetrics, SM_CXSMICON
	mov esi, eax
	invoke GetSystemMetrics, SM_CYSMICON
	mov edi, eax
	invoke ImageList_Create, esi, edi, ILC_MASK, 1, 0
	mov @hImageList, eax
	invoke ImageList_AddIcon, @hImageList, @hIcon

	invoke CreateWindowEx, NULL, offset WC_LISTVIEW, \
	NULL, WS_CHILD or WS_VISIBLE or LVS_REPORT or LVS_EDITLABELS or LVS_SINGLESEL, \
	10, 70, 300, 510, hWinMain, 0, hInstance, NULL
	mov hListView, eax
	invoke SendMessage, hListView, LVM_SETIMAGELIST, @hImageList, LVSIL_SMALL

	mov @col.imask, LVCF_TEXT or LVCF_WIDTH or LVCF_SUBITEM
	mov @col.lx, 220
	mov @col.iSubItem, 0
	mov @col.pszText, offset szUsername
	invoke SendMessage, hListView, LVM_INSERTCOLUMN, 0,addr @col
	invoke SendMessage, hListView, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, LVS_EX_FULLROWSELECT or LVS_EX_AUTOSIZECOLUMNS

	mov @col.imask, LVCF_TEXT or LVCF_WIDTH or LVCF_SUBITEM
	mov @col.lx, 80
	mov @col.iSubItem, 0
	mov @col.pszText, offset szStatus
	invoke SendMessage, hListView, LVM_INSERTCOLUMN, 1, addr @col

	mov @col.imask, LVCF_TEXT or LVCF_WIDTH or LVCF_SUBITEM
	mov @col.lx, 0
	mov @col.iSubItem, 0
	mov @col.pszText, offset szID
	invoke SendMessage, hListView, LVM_INSERTCOLUMN, 2, addr @col

	ret
CreateListView ENDP

InitUI PROC USES eax
	invoke CreateWindowEx, NULL, addr szEdit, addr szText,\
	WS_CHILD or WS_VISIBLE or WS_BORDER or WS_VSCROLL or ES_LEFT or ES_MULTILINE or ES_AUTOVSCROLL, 340, 450, 430, 130,\  
	hWinMain, 0, hInstance, NULL
	mov hEdit, eax
	invoke SendMessage, eax, WM_SETFONT, hFont, 0
	
	invoke CreateWindowEx, NULL, addr szButton, addr szSend,\
	WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON, 780, 450, 140, 130,
	hWinMain, 1, hInstance, NULL
	mov hSendButton, eax
	invoke EnableWindow, hSendButton, 0
	invoke SendMessage, hSendButton, WM_SETFONT, hFont, 0

	invoke CreateWindowEx, NULL, addr szEdit, \
	NULL, WS_CHILD or WS_VISIBLE or WS_BORDER, 10, 40, 240, 20, \
	hWinMain, 0, hInstance, NULL
	mov hNewEdit, eax
	invoke SendMessage, hNewEdit, WM_SETFONT, hFont, 0

	invoke CreateWindowEx, NULL, addr szButton, addr szNew,\
	WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON, 260, 40, 50, 20,
	hWinMain, 2, hInstance, NULL
	invoke SendMessage, eax, WM_SETFONT, hFont, 0

	invoke CreateListView

	mov eax, 0
	.while eax == 0
		invoke chat_getFriendList
	.endw
	ret
InitUI ENDP

AppendMsg PROC USES eax edx esi, username:DWORD, msg:DWORD, from:BYTE
	local @hEdit:DWORD
	mov esi, ptrUsers
	.while esi != 0
		mov edi, (USER ptr [esi]).username
		invoke crt_strcmp, edi, username
		.if eax == 0
			.break
		.endif
		mov esi, (USER ptr [esi]).pNext
	.endw
	mov eax, (USER ptr [esi]).hEdit
	mov @hEdit, eax
	invoke SendMessage, @hEdit, EM_SETSEL, -2, -1
	.if from == 0
		invoke SendMessage, @hEdit, EM_REPLACESEL, 1, (USER ptr [esi]).username
	.else
		invoke SendMessage, @hEdit, EM_REPLACESEL, 1, addr szMe
	.endif
	invoke SendMessage, @hEdit, EM_REPLACESEL, 1, addr szColon
	invoke SendMessage, @hEdit, EM_REPLACESEL, 1, addr newLine
	invoke SendMessage, @hEdit, EM_REPLACESEL, 1, msg
    invoke SendMessage, @hEdit, EM_REPLACESEL, 1, addr newLine
	invoke SendMessage, @hEdit, EM_REPLACESEL, 1, addr newLine
	ret
AppendMsg ENDP

SwitchSession PROC USES eax edx esi edi, row:DWORD
	local @item:LV_ITEM
	local @buffer[128]: DWORD

	mov @item.iSubItem, 0
	lea eax, @buffer
	mov @item.pszText, eax
	mov @item.cchTextMax, 128
	invoke SendMessage, hListView, LVM_GETITEMTEXT, row, addr @item

	mov esi, ptrUsers
	.while esi != 0
		mov edi, (USER ptr [esi]).username
		lea eax, @buffer
		invoke crt_strcmp, edi, eax
		.if eax == 0
			.break
		.endif
		mov esi, (USER ptr [esi]).pNext
	.endw
	.if esi != 0
		.if ptrCurUser != 0
			mov edi, ptrCurUser
			invoke ShowWindow, (USER ptr [edi]).hEdit, SW_HIDE
		.endif
		mov ptrCurUser, esi
		invoke ShowWindow, (USER ptr [esi]).hEdit, SW_SHOW
		mov eax, (USER ptr [esi]).status
		.if eax == 0
			invoke EnableWindow, hSendButton, 0
		.else
			invoke EnableWindow, hSendButton, 1
		.endif
	.endif
	ret
SwitchSession ENDP

SendMsg PROC USES eax edx
	local @msg[512]:BYTE
	invoke SendMessage, hEdit, WM_GETTEXT, 512, addr @msg
	invoke SendMessage, hEdit, WM_SETTEXT, 0, 0
	mov edx, ptrCurUser
	invoke AppendMsg, (USER ptr [edx]).username, addr @msg, 1
	;invoke AppendMsg, (USER ptr [edx]).username, addr @msg, 0
	;invoke ChangeFriendStatus, (USER ptr [edx]).username, 0
	ret
SendMsg ENDP

AppendFriend PROC USES eax ebx edx esi, username:DWORD, status:DWORD, ID:DWORD
	local @item: LVITEM
	local @hEdit: DWORD
	local @szID[16]: BYTE
	mov @item.imask, LVIF_TEXT or LVIF_IMAGE
	mov @item.iImage, 0
	mov @item.pszText, NULL
	mov @item.cchTextMax, 1024
	invoke SendMessage, hListView, LVM_GETITEMCOUNT, 0, 0
	mov @item.iItem, eax
	mov esi, eax
	mov @item.iSubItem, 0
	invoke SendMessage, hListView, LVM_INSERTITEM, 0, addr @item

	mov eax, username
	mov @item.pszText, eax
	invoke SendMessage, hListView, LVM_SETITEM, 0, addr @item

	inc @item.iSubItem

	.if status == 1
		mov eax, offset szOnline
	.else
		mov eax, offset szOffline
	.endif
	mov @item.pszText, eax
	invoke SendMessage, hListView, LVM_SETITEM, 0, addr @item

	inc @item.iSubItem

	lea eax, @szID
	invoke crt__itoa, ID, eax, 10
	mov @item.pszText, eax
	invoke SendMessage, hListView, LVM_SETITEM, 0, addr @item

	;���������¼��
	invoke CreateWindowEx, NULL, addr RICHEDIT50W, NULL,\
	WS_CHILD or WS_VISIBLE or WS_BORDER or ES_MULTILINE or WS_VSCROLL or ES_AUTOVSCROLL or ES_NOHIDESEL, 340, 40, 580, 380,\  
	hWinMain, 0, hInstance, NULL
	mov @hEdit, eax
	invoke ShowWindow, @hEdit, SW_HIDE
	invoke SendMessage, @hEdit, EM_SETREADONLY, 1, 0
	invoke SendMessage, @hEdit, WM_SETFONT, hFont, 0

	; ����USER�ṹ��
	invoke GlobalAlloc, GPTR, sizeof USER
	mov ebx, eax
	mov eax, ID
	mov (USER ptr [ebx]).ID, eax
	mov eax, username
	mov (USER ptr [ebx]).username, eax
	mov eax, status
	mov (USER ptr [ebx]).status, eax
	mov (USER ptr [ebx]).row, esi
	mov eax, @hEdit
	mov (USER ptr [ebx]).hEdit, eax

	; ����USERS����
	.if ptrUsers == 0
		mov ptrUsers, ebx
	.else
		mov eax, ptrUsers
		mov edx, (USER ptr [eax]).pNext
		.while edx != 0
			mov eax, edx
			mov edx, (USER ptr [eax]).pNext
		.endw
		mov (USER ptr [eax]).pNext, ebx
	.endif
	ret
AppendFriend ENDP

ChangeFriendStatus PROC USES eax ebx edx, username:DWORD, status:DWORD
	local @item: LVITEM
	local @row: DWORD
	mov esi, ptrUsers
	.while esi != 0
		mov edi, (USER ptr [esi]).username
		invoke crt_strcmp, edi, username
		.if eax == 0
			.break
		.endif
		mov esi, (USER ptr [esi]).pNext
	.endw
	.if esi != 0
		mov @item.imask, LVIF_TEXT
		mov eax, (USER ptr [esi]).row
		mov @item.iItem, eax
		mov @item.iSubItem, 1
		mov eax, status
		mov (USER ptr [esi]).status, eax
		.if status == 1
			mov eax, offset szOnline
		.else
			mov eax, offset szOffline
		.endif
		mov @item.pszText, eax
		mov @item.cchTextMax, 16
		invoke SendMessage, hListView, LVM_SETITEM, 0, addr @item
		invoke SwitchSession, (USER ptr [esi]).row
	.endif
	ret
ChangeFriendStatus ENDP

ClientProc PROC USES ebx esi edi, hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
	local @stPs:PAINTSTRUCT
	local @stRect:RECT
	local @hDc

	mov eax, uMsg

	.if eax == WM_PAINT
		invoke BeginPaint,hWnd,addr @stPs
		mov @hDc,eax

		invoke GetClientRect, hWnd, addr @stRect
		;invoke DrawText, @hDc, addr szText, -1, addr @stRect, DT_SINGLELINE or DT_CENTER or DT_VCENTER  ;���ｫ��ʾszText����ַ���
		invoke EndPaint, hWnd, addr @stPs
	
	.elseif eax == WM_CLOSE  ;���ڹر���Ϣ
		invoke DestroyWindow, hWinMain
		invoke PostQuitMessage, NULL

	.elseif eax == WM_CREATE
		mov eax, hWnd
		mov hWinMain, eax

		invoke CreateUserLabel, addr strUsername
		invoke InitUI

	.elseif eax == WM_COMMAND  ;���ʱ���������Ϣ��WM_COMMAND
		mov eax, wParam  ;���в���wParam�����Ǿ������������һ����ť����wParam���Ǹ���ť�ľ��
		.if eax == 1  ;�������жϾ���Ƕ��ٵ�֪���ĸ���ť�������ˣ��Ӷ�����Ӧ�Ĳ�������������Ǿ��Ϊ1�İ�ť�����£��⽫����һ�����Ϊ2�İ�ť
			invoke SendMsg
		.elseif eax == 2
			invoke GlobalAlloc, GPTR, 128
			mov esi, eax
			invoke SendMessage, hNewEdit, WM_GETTEXT, 128, esi
			invoke addFriend, esi
			.if eax == 1
				invoke MessageBox, hWinMain, addr szSuccess, addr szAddfriend, MB_OK
			.else
				invoke MessageBox, hWinMain, addr szFailed, addr szAddfriend, MB_OK
			.endif
			invoke GlobalFree, esi
		.endif
	.elseif eax == WM_NOTIFY
		mov esi,lParam
		assume esi:ptr NMHDR
		.if [esi].code == NM_DBLCLK 
			assume esi:ptr NMITEMACTIVATE
			mov edi, [esi].iItem
			invoke SwitchSession, edi
		.endif
	.else
		invoke DefWindowProc, hWnd, uMsg, wParam, lParam
		ret
	.endif

	mov eax, 0
	ret
ClientProc ENDP

ClientMain PROC  ;���ڳ���
	local @stWndClass:WNDCLASSEX  ;������һ���ṹ����������������WNDCLASSEX��һ�������ඨ���˴��ڵ�һЩ��Ҫ���ԣ�ͼ�꣬��꣬����ɫ�ȣ���Щ�������ǵ������ݣ����Ƿ�װ��WNDCLASSEX�д��ݵġ�
	local @stMsg:MSG	;��������stMsg��������MSG����������Ϣ���ݵ�

	;invoke GetModuleHandle, NULL  ;�õ�Ӧ�ó���ľ�����Ѹþ����ֵ����hInstance�У������ʲô���򵥵�������ĳ������ı�ʶ�����ļ���������ھ��������ͨ������ҵ���Ӧ������
	mov hInstance, eax
	invoke RtlZeroMemory, addr @stWndClass,sizeof @stWndClass  ;��stWndClass��ʼ��ȫ0

	;�ⲿ���ǳ�ʼ��stWndClass�ṹ�и��ֶε�ֵ�������ڵĸ�������
	INVOKE LoadIcon, NULL, IDI_APPLICATION
	mov @stWndClass.hIcon, eax
	INVOKE LoadCursor, NULL, IDC_ARROW
	mov @stWndClass.hCursor, eax
	mov eax, hInstance
	mov @stWndClass.hInstance, eax
	mov @stWndClass.cbSize, sizeof WNDCLASSEX
	mov @stWndClass.style, CS_HREDRAW or CS_VREDRAW
	mov @stWndClass.lpfnWndProc,offset ClientProc
	mov @stWndClass.hbrBackground, COLOR_WINDOW
	mov @stWndClass.lpszClassName,offset szClientWindow
	invoke RegisterClassEx, addr @stWndClass  ;ע�ᴰ���࣬ע��ǰ����д����WNDCLASSEX�ṹ

	invoke CreateWindowEx, WS_EX_CLIENTEDGE,\  ;��������
			offset szClientWindow,offset szClient,\  ;szClassName��szCaptionMain���ڳ������ж�����ַ�������
			WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 960, 640, \	;szClassName�ǽ�������ʹ�õ������ַ���ָ��
			NULL,NULL,hInstance,NULL		;����ĳ�'button'��ô�����Ľ���һ����ť��szCaptionMain��������Ǵ��ڵ����ƣ������ƻ���ʾ�ڱ�������

	invoke ShowWindow, hWinMain, SW_SHOWNORMAL  ;��ʾ����
	invoke UpdateWindow, hWinMain  ;ˢ�´��ڿͻ���

	.while TRUE  ;�������޵���Ϣ��ȡ�ʹ����ѭ��
		invoke GetMessage,addr @stMsg, 0, 0, 0  ;����Ϣ������ȡ����һ����Ϣ������stMsg�ṹ��
		.break .if eax==0  ;������˳���Ϣ��eax�����ó�0���˳�ѭ��
		invoke TranslateMessage,addr @stMsg  ;���ǰѻ��ڼ���ɨ����İ�����Ϣת���ɶ�Ӧ��ASCII�룬�����Ϣ����ͨ����������ģ��ⲽ������
		invoke DispatchMessage,addr @stMsg  ;���������������ҵ��ô��ڳ���Ĵ��ڹ��̣�ͨ���ô��ڹ�����������Ϣ
	.endw
	ret
ClientMain ENDP

LogProc PROC USES ebx esi edi, hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD  ;���ڹ���
	local @stPs:PAINTSTRUCT
	local @stRect:RECT
	local @hDc

	mov eax, uMsg

	.if eax == WM_PAINT
		invoke BeginPaint,hWnd,addr @stPs
		mov @hDc,eax

		invoke GetClientRect, hWnd, addr @stRect

		;invoke DrawText, @hDc, addr szText, -1, addr @stRect, DT_SINGLELINE or DT_CENTER or DT_VCENTER  ;���ｫ��ʾszText����ַ���
		invoke EndPaint, hWnd, addr @stPs
	
	.elseif eax == WM_CLOSE  ;���ڹر���Ϣ
		invoke DestroyWindow, hWinMain
		invoke PostQuitMessage, NULL

	.elseif eax == WM_CREATE  ;��������  ��������ʾ����һ����ť������button�ַ���ֵ��'button'�������ݶζ��壬��ʾҪ��������һ����ť��showButton��ʾ�ð�ť�ϵ���ʾ��Ϣ
		mov eax, hWnd
		mov hWinMain,eax

		invoke GetStockObject, DEFAULT_GUI_FONT
		mov hFont, eax
		invoke GetStockObject, DKGRAY_BRUSH
		mov hBrush, eax

 		invoke CreateWindowEx,NULL, addr szStatic, addr szUsername,\
		WS_CHILD or WS_VISIBLE or SS_CENTER or SS_CENTERIMAGE, 20, 20, 60, 20,
		hWnd, 0, hInstance,NULL
		invoke SendMessage, eax, WM_SETFONT, hFont,	0

		invoke CreateWindowEx, NULL, addr szEdit, NULL,\
		WS_CHILD or WS_VISIBLE or WS_BORDER or SS_CENTERIMAGE, 90, 20, 210, 20,\  
		hWnd, 0, hInstance, NULL
		mov hUsernameEdit, eax
		invoke SendMessage, hUsernameEdit, WM_SETFONT, hFont, 0

		invoke CreateWindowEx,NULL, addr szStatic, addr szPassword,\
		WS_CHILD or WS_VISIBLE or SS_CENTER or SS_CENTERIMAGE, 20, 60, 60, 20,
		hWnd, 0,hInstance,NULL
		invoke SendMessage, eax, WM_SETFONT, hFont, 0

		invoke CreateWindowEx, NULL, addr szEdit, NULL,\
		WS_CHILD or WS_VISIBLE or WS_BORDER or ES_PASSWORD or SS_CENTERIMAGE, 90, 60, 210, 20,\
		hWnd, 0, hInstance, NULL
		mov hPasswordEdit, eax
		invoke SendMessage, hPasswordEdit, WM_SETFONT, hFont, 0

		invoke CreateWindowEx, NULL, addr szButton, addr szLogin,\
		WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON, 50, 95, 80, 23,
		hWnd, 1, hInstance,NULL
		invoke SendMessage, eax, WM_SETFONT, hFont, 0

		invoke CreateWindowEx, NULL, addr szButton, addr szLogon,\
		WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON, 210, 95, 80, 23,
		hWnd, 2, hInstance,NULL
		invoke SendMessage, eax, WM_SETFONT, hFont, 0

	.elseif eax == WM_COMMAND  ;���ʱ���������Ϣ��WM_COMMAND
		mov eax, wParam  ;���в���wParam�����Ǿ������������һ����ť����wParam���Ǹ���ť�ľ��
		.if eax == 1
			invoke GetWindowText, hUsernameEdit, addr strUsername, 128
			invoke GetWindowText, hPasswordEdit, addr strPassword, 128
			invoke chat_login, addr strUsername, addr strPassword
			.if eax == 1
				invoke DestroyWindow, hWinMain
				invoke PostQuitMessage, NULL
				call ClientMain
			.else
				invoke MessageBox, hWinMain, addr szFailed, addr szText, MB_OK
			.endif
		.elseif eax == 2
			invoke GetWindowText, hUsernameEdit, addr strUsername, 128
			invoke GetWindowText, hPasswordEdit, addr strPassword, 128
			invoke chat_sign_in, addr strUsername, addr strPassword
			.if eax == 1
				invoke MessageBox, hWinMain, addr szSuccess, addr szText, MB_OK
			.else
				invoke MessageBox, hWinMain, addr szFailed, addr szText, MB_OK
			.endif
		.endif
	.else  ;����Ĭ�ϴ�����������Ϣ
		invoke DefWindowProc, hWnd, uMsg, wParam, lParam
		ret
	.endif

	mov eax, 0
	ret
LogProc ENDP

LogMain PROC  ;���ڳ���
	local @stWndClass:WNDCLASSEX  ;������һ���ṹ����������������WNDCLASSEX��һ�������ඨ���˴��ڵ�һЩ��Ҫ���ԣ�ͼ�꣬��꣬����ɫ�ȣ���Щ�������ǵ������ݣ����Ƿ�װ��WNDCLASSEX�д��ݵġ�
	local @stMsg:MSG	;��������stMsg��������MSG����������Ϣ���ݵ�

	invoke GetModuleHandle, NULL  ;�õ�Ӧ�ó���ľ�����Ѹþ����ֵ����hInstance�У������ʲô���򵥵�������ĳ������ı�ʶ�����ļ���������ھ��������ͨ������ҵ���Ӧ������
	mov hInstance, eax
	invoke RtlZeroMemory, addr @stWndClass,sizeof @stWndClass  ;��stWndClass��ʼ��ȫ0

	;�ⲿ���ǳ�ʼ��stWndClass�ṹ�и��ֶε�ֵ�������ڵĸ�������
	INVOKE LoadIcon, NULL, IDI_APPLICATION
	mov @stWndClass.hIcon, eax
	INVOKE LoadCursor, NULL, IDC_ARROW
	mov @stWndClass.hCursor, eax
	mov eax, hInstance
	mov @stWndClass.hInstance, eax
	mov @stWndClass.cbSize, sizeof WNDCLASSEX
	mov @stWndClass.style, CS_HREDRAW or CS_VREDRAW
	mov @stWndClass.lpfnWndProc,offset LogProc
	mov @stWndClass.hbrBackground, COLOR_WINDOW
	mov @stWndClass.lpszClassName,offset szLogWindow
	invoke RegisterClassEx, addr @stWndClass  ;ע�ᴰ���࣬ע��ǰ����д����WNDCLASSEX�ṹ

	invoke CreateWindowEx, WS_EX_CLIENTEDGE,\  ;��������
			offset szLogWindow,offset szLogin,\  ;szClassName��szCaptionMain���ڳ������ж�����ַ�������
			WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 340, 180, \	;szClassName�ǽ�������ʹ�õ������ַ���ָ��
			NULL,NULL,hInstance,NULL		;����ĳ�'button'��ô�����Ľ���һ����ť��szCaptionMain��������Ǵ��ڵ����ƣ������ƻ���ʾ�ڱ�������

	invoke ShowWindow, hWinMain, SW_SHOWNORMAL  ;��ʾ����
	invoke UpdateWindow, hWinMain  ;ˢ�´��ڿͻ���

	.while TRUE  ;�������޵���Ϣ��ȡ�ʹ����ѭ��
		invoke GetMessage,addr @stMsg, 0, 0, 0  ;����Ϣ������ȡ����һ����Ϣ������stMsg�ṹ��
		.break .if eax==0  ;������˳���Ϣ��eax�����ó�0���˳�ѭ��
		invoke TranslateMessage,addr @stMsg  ;���ǰѻ��ڼ���ɨ����İ��� ��Ϣת���ɶ�Ӧ��ASCII�룬�����Ϣ����ͨ����������ģ��ⲽ������
		invoke DispatchMessage,addr @stMsg  ;���������������ҵ��ô��ڳ���Ĵ��ڹ��̣�ͨ���ô��ڹ�����������Ϣ
	.endw
	ret
LogMain ENDP

main PROC
	invoke LoadLibrary, addr szMsftedit
	call LogMain
	invoke ExitProcess, 0
	ret
main ENDP
END main