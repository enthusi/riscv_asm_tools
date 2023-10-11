.global _start
.equ BUFSIZE, 1024
.equ FILENO_STDOUT, 1
.equ FILENO_STDIN, 0

.equ AT_FDCWD, -100
.equ O_RDONLY, 00
.equ sys_exit,	93
.equ sys_read,	63
.equ sys_write,	64
.equ sys_close,	57
.equ sys_openat, 56
.equ sys_lseek,	62
.equ sys_mmap,	222
.equ sys_munmap,215

.text
_start:
    li t3 ,1 #file counter
    ld t4, 0(sp)

    ld		a0,	0(sp) 		#argc 1 on stack
    addi	a0, 	a0,	 -1 	#was it 1? Then fetch from STDIN
    bnez	a0,	openFile

    li		a0,	FILENO_STDIN
    j readFile

openFile:
    li		a0,	AT_FDCWD
    ld		a1,	16(sp) #the name is on stack ARGV
    li		a2, 	O_RDONLY
    mv		a3,	zero
    li		a7, 	sys_openat
    ecall	#file handler FD in a0
    mv t2, a0	#keep fd in t2
    
readFile:
    #call, fd, buffer, size
    #t2 is fd here
    mv a0 ,t2
    la a1, buf 
    li a2, BUFSIZE
    li a7, sys_read
    ecall
    
writeOut:
    mv a2 ,a0 #how much was read?
    mv t1, a0 #remember
    #call, STDOUT, buf, size
    li a0, FILENO_STDOUT
    la a1, buf
    #li a2, BUFSIZE
    li a7, sys_write
    ecall

    bne t1, zero, readFile

    mv a0, t2
    li a7, sys_close
    ecall

    #are we done?
    #t4 is argc
    #t3 is file counter (1 start)
    addi t3,t3, 1
    bge t3, t4, exit
    addi sp,sp, 8
    j openFile
    
        
exit:
    li a0,0
    li a7, sys_exit
    ecall


.bss
buf:
.space BUFSIZE, 0

