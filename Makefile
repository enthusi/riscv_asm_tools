SRC_BUF  = cat_buf
SRC_MMAP = cat_mmap_full
SRC_ELF = cat_mmap_full_elf
SRC_MAND = mandelbrot
SRC_TEST = c_test
FLAGS = -march=rv64gc
all: mandelbrot c_test cat_buf cat_mmap_full mmap_full_ownelf

mandelbrot: $(SRC_MAND).s
	as $(FLAGS) -o $(SRC_MAND).o $(SRC_MAND).s 
	ld -o $(SRC_MAND)_tmp $(SRC_MAND).o   
	objcopy -O binary $(SRC_MAND)_tmp $(SRC_MAND)
	rm $(SRC_MAND)_tmp
	
c_test: $(SRC_TEST).s
	as $(FLAGS) -o $(SRC_TEST).o $(SRC_TEST).s 
	ld -o $(SRC_TEST) $(SRC_TEST).o   
	objdump -d $(SRC_TEST)

cat_buf: $(SRC_BUF).s
	as $(FLAGS) -o $(SRC_BUF).o $(SRC_BUF).s 
	ld -o $(SRC_BUF) $(SRC_BUF).o   
	strip $(SRC_BUF)
	
cat_mmap_full: $(SRC_MMAP).s
	as $(FLAGS) -o $(SRC_MMAP).o $(SRC_MMAP).s 
	ld -o $(SRC_MMAP) $(SRC_MMAP).o   
	strip $(SRC_MMAP)
	
mmap_full_ownelf: $(SRC_ELF).s 
	as $(FLAGS) -o $(SRC_ELF).o $(SRC_ELF).s 
	ld -o $(SRC_ELF)_tmp $(SRC_ELF).o   
	objcopy -O binary $(SRC_ELF)_tmp $(SRC_ELF)
	rm $(SRC_ELF)_tmp
	
clean:
	rm *.o
	
