ASM = nasm
QEMU = qemu-system-i386

.PHONY: all run clean

all: asmOS.img

boot.bin: boot.asm
	$(ASM) -f bin boot.asm -o boot.bin

main.bin: main.asm macros.asm
	$(ASM) -f bin main.asm -o main.bin

asmOS.img: boot.bin main.bin
	cat boot.bin main.bin > asmOS.img
	truncate -s 3000 asmOS.img # Amount of bytes img size is. Such as 2096 = 2KB. Minimum as of now is 3000. Not any lower.

run: asmOS.img
	$(QEMU) -drive format=raw,file=asmOS.img

clean:
	rm -f boot.bin main.bin asmOS.img
