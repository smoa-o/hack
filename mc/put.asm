%macro PUT 4
%1:
    push %3
    mov %3, Dbg
    call %2
    pop %3
    call %2
    mov %3, Line
    call %2
    ret

%2:
    lodsb
    or al, al
    jz .done
    call %4
    jmp %2
.done:
    ret

%4:
    push dx
    push ax
.wait_:
    mov dx, COM+5
    in al, dx
    test al, 0x20
    jz .wait_
    mov dx, COM
    pop ax
    out dx, al
    pop dx
    ret
%endmacro
