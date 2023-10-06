# A (future) collection of assembly replacement for simple shell tools

This is for learning and fun. I restrict myself to actual syscalls and RiscV 64bit.
All written for the GNU-as.

Currently implemented: `cat`.

## cat

Early version. Does it's job but no error handling or optimisations YET.

## TODOs

- Construct own ELF headers to shrink sizes further.
- branch into minimal size and 'most proper'.
- add error handling.
- consider mmap for read vs. fixed buffer.
