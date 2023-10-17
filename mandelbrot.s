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
.equ O_WRONLY, 1
.equ O_RDWR, 2
.equ O_RDONLY, 00
.equ O_CREAT, 100
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

openFile: 
#compute size

 	li a0, 54+4*256 #bmp header + PAL table
	li s10, 2048
	li s11, 1024
	mul a5,s10,s11
	add a0,a0,a5
	mv s5,a0 #keep size for later

	/*	Do mapping	*/
	mv		a0,		zero
	mv a1, s5 #file size
	li		a2,		(PROT_READ | PROT_WRITE)
	li		a3,		(MAP_ANONYMOUS | MAP_SHARED)
	mv a5, zero
	mv		a4,		zero
	li		a7,		sys_mmap
	ecall
	mv		s0,		a0
	
#======================================	
#first inject BMP header
	la t4, bmpheader
	mv t5, s0
	li t6, 8*7
head_write_loop:
	lb a0, 0(t4)
	sb a0, 0(t5)
	addi t5,t5,1
	addi t4,t4,1
	addi t6,t6,-1
	bge t6,zero,head_write_loop
	
	#fill buffer here, dont use s5, s0
	mv t5, s0 #the local pointer into buffer
	mv t4, s0 #also used for palette
	mv t6, s5 #remember the size

	
#change sizes
	sh s10,0x12(s0) #size x
	sh s11,0x16(s0) #size y
#================
	li t3, 0  
pal_loop:
	mv a0, t3
#a0 = v

#red = t0
#green = t1
#blue = t2

    li t0,255
    mv t1,t0
    mv t2,t0 
    
#A 0..63
#B 64..127
#C 128..192
#D 192..255

    li a1, 64
    li a2, 128
    li a3, 192

    bge a0, a1, B #is a0 >= 64?
A:
    slli a0,a0,2 #*1024/256 = *4
    mv t0, zero
	mv t1, a0
    jal E
B:   
    bge a0, a2, C #is a0 >= 128?
    mv t0, zero
    sub s2, a2, a0 # s2=64-v
    slli s2,s2,2 #*1024/256 = *4
    addi t2,s2,255 # blue = t2
    jal E
C:
    bge a0, a3, D #is a0 >= 192?
    mv t2, zero
    sub s2, a0, a2 # s2=v-128
    slli t0,s2,2
    jal E
D:
    mv t2, zero
    sub s2, a3, a0 # a5=192-v
    slli s2,s2,2 #*1024/256 = *4
    addi t1,s2,255 # green = t1
E:    
    #t2+t1<<8+t0<<16
    slli t0,t0,16
    slli t1,t1,8
    add t2,t2,t0
    add t2,t2,t1
	slli t2,t2,8
    #=====================	
   	sw t2, 0x3a(t4)
	addi t4,t4,4 #destination in buffer
	addi t3,t3,1
	li s3, 255
	ble t3,s3,pal_loop
    
#    j skip_math 
do_math:
    #++++++++++++++++++++++++++++++++++++++++++++++
    mv a5,s10
	mv a6,s11
	#fixpoint math with 2.13 bit precision.
    li a1,-17337 #-0.7 * 2**13 - 3.0769*2**12)
    li a2,  9869 
    li a3,-10000
    li a4, 0000
    
    li t3,16384 
    li t4,268435456 # mandelbrot threshold
   
    #s2=xstep
    #s3=ystep 
    #s4 divider 5
    #properly compute this based on x and y size!

	#li s4,20
	srli s4,s10,5#/32
    sub s2,a2,a1 #(xmax-xmin)
    div s2,s2,s4 #32/SCREEN_WIDTH = /5

	srli s4,s11,5
	sub s3,a4,a3 #(xmax-xmin)
    div s3,s3,s4 #32/SCREEN_WIDTH = /5
    
    li s5,0 #Y
loopy:
    #s7 = q
    mul s7,s5,s3 #y*ys
    srai s7,s7,4 #/16
    add s7,s7,a3 #+ymin
    li s6,0 #X

loopx:
    #s8 = p
    mul s8,s6,s2 #x*xs
    srai s8,s8,5 #/32
    add s8,s8,a1 #+xmin

    li s9,0#xn
    li s10,0#x0
    li s11,0#y0
    
    li t2,128*2 #maxiter
innerloop:
    #xn=mul((x0+y0),(x0-y0)) +p;
    add t0,s10,s11
    sub t1,s10,s11
    mul s9,t0,t1
    srai s9,s9,13
    add s9,s9,s8

    #y0=mul(32768,mul(x0,y0)) +q;
    mul t0,s10,s11
    srai t0,t0,13
    mul s11,t3,t0
    srai s11,s11,13
    add s11,s11,s7

    #x0=xn;
    mv s10,s9

    #((mul(xn,xn)+mul(y0,y0))<(65536)
    mul t0,s9,s9 #xn**2
    mul t1,s11,s11 #y0**2
    add t0,t0,t1

    bgt t0,t4, exitloop
    addi t2,t2,-1
    bne t2,zero,innerloop

exitloop:
   # mv a0,t2
   #write pixel value in a0 into buffer!
    sb t2,0x436(t5)	
    addi t5,t5,1

    #next x
    addi s6,s6,1
    #li t0,320#160
    bne s6,a5, loopx #t0,loopx

    #next y
    addi s5,s5,1
    #li t0,160#80
    bne s5,a6,loopy #t0,loopy
    #++++++++++++++++++++++++++++++++++++++++++++++
skip_math:
    mv s5, t6 #restore size, optimize later
#======================================
	li a0, AT_FDCWD
	la a1, outfilename
	li a2, O_CREAT | O_WRONLY
	li a3, 0700
	li a7, sys_openat
	ecall
    mv s1,a0
writeOut:
  mv a2 ,s5 #we write as much as we mapped
  mv a0, s1#FILENO_STDOUT
  mv a1, s0 #buffer
  li a7, sys_write
  ecall

  mv a0,s1 	
  li a7, sys_close
  ecall

	#unmap here
	mv		a0,		s0 #adr
	mv		a1,		s5 #size
	li		a7,		sys_munmap
	ecall

    
exit:	
    mv sp, s6	
    li a0,0
    li a7, sys_exit
    ecall
    
outfilename:
.asciz "res.bmp"
 
.align 4
bmpheader:
.byte 0x42,0x4d,0x36,0x36,0x00,0x00,0x00,0x00, 0x00,0x00,0x36,0x04,0x00,0x00,0x28,0x00
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0x50,0x00, 0x00,0x00,0x01,0x00,0x08,0x00,0x00,0x00
.byte 0x00,0x00,0x00,0x32,0x00,0x00,0x13,0x0b, 0x00,0x00,0x13,0x0b,0x00,0x00,0x00,0x01
.byte 0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00

filesize = . - ehdr
