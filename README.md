# A collection of small programs and tools fully written in RiscV 64bit assembly

This is for learning and fun. I restrict myself to actual syscalls and RiscV 64bit.
All written for the GNU-as.

Currently implemented: `cat, mandelbrot`.

## mandelbrot

This code creates a buffer, injects a BMP header, generates an RGB palette table and computes a mandelbrot graphic
to be written as a BMP file in 2048x1024 pix as default. You can provide two integers as command line arguments for a specific x y size (new ATOI() asm code).
`./mandelbrot 8192 4096` takes 10 seconds on my VisionFive2.
`-> 708 Bytes`.

## cat

This tool comes in several flavors, in order of creation/complexity.

### cat_buf

Reads/writes into 1K buffer repeatedly over file, over all files
`-> 800 Bytes` with C-ext: `768 Bytes`

### cat_mmap_full

uses mmap syscall to fetch each input file as a whole at once and then write it out, over all files
`-> 760 Bytes` with C-ext: `696 Bytes`


### cat_mmap_full_elf

Same as cat_mmap_full but includes its own minmal(ish) ELF64 header
`-> 352 Bytes` with C-ext: `288 Bytes`


## TODOs

- maybe add error handling to cat family
- mandelbrot using fork()
