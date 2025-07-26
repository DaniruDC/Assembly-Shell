# Assembly-Shell

# assemble: 
arm-linux-gnueabi-gcc -Wall shell.s -o shell

# run:
qemu-arm -L /usr/arm-linux-gnueabi ./shell
