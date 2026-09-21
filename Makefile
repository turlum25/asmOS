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

run: asmOS.img
	$(QEMU) -drive format=raw,file=asmOS.img

clean:
	rm -f boot.bin main.bin asmOS.img
