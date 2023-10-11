.global _start

.equ FILENO_STDOUT, 1
.equ FILENO_STDIN, 0

.equ SEEK_SET,		0
.equ SEEK_END,		2
.equ PROT_READ,		0x1
.equ PROT_WRITE,		0x2
.equ MAP_SHARED,		0x01
.equ MAP_ANONYMOUS,		0x20

.equ AT_FDCWD, -100
.equ O_RDONLY, 00
.equ sys_exit,	93
.equ sys_read,	63
.equ sys_write,	64
.equ sys_close,	57
.equ sys_openat, 56
.equ sys_lseek,	62
.equ sys_mmap,	222
.equ sys_munmap, 215

.text

load_address = 0x010000 
ehdr:
    .byte 0x7f, 0x45, 0x4c, 0x46, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .half 2                                 #   e_type
    .half 0xf3                              #   e_machine
    .word 1                                 #   e_version
    .quad load_address + _start - ehdr      #   e_entry
    .quad phdr - ehdr                       #   e_phoff
    .quad 0                                 #   e_shoff
    .word 0                                 #   e_flags
    .half ehdrsize                          #   e_ehsize    (64)
    .half phdrsize                          #   e_phentsize (56)
    .half 1                                 #   e_phnum
    .half 0                                 #   e_shentsize (64)
    .half 0                                 #   e_shnum
    .half 0                                 #   e_shstrndx
ehdrsize = . - ehdr

phdr:
    .word 1                                 #   p_type
    .word 5                                 #   p_flags
    .quad 0                                 #   p_offset
    .quad load_address                      #   p_vaddr
    .quad load_address                      #   p_paddr
    .quad filesize                          #   p_filesz
    .quad filesize                          #   p_memsz
    .quad 0x1000                            #   p_align
phdrsize = . - phdr

_start:
    li t3 ,1 #file counter
    ld t4, 0(sp)
    mv s6, sp #keep it for a clean exit later

    ld		a0,	0(sp) 		#argc 1 on stack
    addi	a0, 	a0,	 -1 	#was it 1? Then fetch from STDIN
    bnez	a0,	openFile

    li		a0,	FILENO_STDIN
    j readFile

openFile:
    li		a0,	AT_FDCWD
    ld		a1,	16(sp) #the first input name is on stack ARGV
    li		a2, 	O_RDONLY
    mv		a3,	zero
    li		a7, 	sys_openat
    ecall	#file handler FD in a0
    mv t2, a0	#keep fd in t2
    
readFile:

#create large buffer
	#a0 is still fd here
	mv		a1,		zero
	li		a2,		SEEK_END
	li		a7,		sys_lseek
	ecall
	#blt		a0,		zero,		errorLoadFile
	
	mv		s5,		a0		#// s5, a0 hold size

	mv		a0,		t2
	mv		a1,		zero
	li		a2,		SEEK_SET
	li		a7,		sys_lseek
	ecall						#// Rewind
	#blt		a0,		zero,		errorLoadFile

	/*	Do mapping	*/
	mv		a0,		zero
	mv a1, s5 #file size
	li		a2,		(PROT_READ | PROT_WRITE)
	li		a3,		(MAP_ANONYMOUS | MAP_SHARED)
	mv		a4,		zero
	li		a7,		sys_mmap
	ecall
	mv		s0,		a0
	
    #call, fd, buffer, size
    #t2 is fd here
	mv		a0,		t2
	mv		a1,		s0
	mv		a2,		s5
	li		a7,		sys_read
	ecall
	
	
writeOut:
    	mv a2 ,a0 #how much was read?
    	li a0, FILENO_STDOUT
    	mv a1, s0 #buffer
    	li a7, sys_write
    	ecall

    	mv a0, t2
    	li a7, sys_close
    	ecall

	#unmap here
	mv		a0,		s0 #adr
	mv		a1,		s5 #size
	li		a7,		sys_munmap
	ecall
	
    #are we done?
    #t4 is argc
    #t3 is file counter (1 start)
    addi t3,t3, 1
    bge t3, t4, exit
    addi sp,sp, 8
    j openFile
    
exit:	
    mv sp, s6	
    li a0,0
    li a7, sys_exit
    ecall
filesize = . - ehdr
