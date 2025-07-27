# Assembly-Shell

This project implements a basic command-line interpreter (shell) entirely in ARMv7 assembly language, targeting a Linux environment. It demonstrates fundamental concepts of operating system interaction, string processing, and system calls at a low level.

## Features

The shell supports the following commands:

* **`hello`**: Prints a classic "Hello World!" message.
* **`help`**: Displays a list of all available commands and their descriptions.
* **`exit`**: Terminates the shell gracefully.
* **`clear`**: Clears the terminal screen.
* **`color <red|green|blue|reset>`**: Changes the text color of the shell prompt and subsequent output.
* **`heartsay <message>`**: Prints a user-provided message artistically framed by heart symbols.


## How to Build and Run

To compile and execute the shell, ensure you have the `arm-linux-gnueabi-gcc` cross-compiler and QEMU installed.

**Assemble:**

arm-linux-gnueabi-gcc -Wall shell.s -o shell

**Run:**

qemu-arm -L /usr/arm-linux-gnueabi ./shell

**Example Usage:**
shell> help
