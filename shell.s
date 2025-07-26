.data
    shell_prompt: .asciz "shell> \n"
    .set PROMPT_LEN, . - shell_prompt - 1 @ Calculate length: current address - start address - 1

    .bss
    input_buffer: .space 256 @reserve 256 bytes for user input
    INPUT_BUFFER_SIZE = 256

    .text
    .global main

main:

shell_loop:
    @ 1. Print the prompt 'shell>
    MOV     R7, #4              @ R7 = SYS_WRITE
    MOV     R0, #1              @ R0 = 1 ;file descriptor for stdout
    LDR     R1, =shell_prompt   @ R1 = Address of the shell_prompt string
    LDR     R2, =PROMPT_LEN     @ R2 = Length of the prompt string
    SVC     #0                  @ Execute system call

    @ 2. Exit the program
    MOV     R7, #3                  @ R7 = SYS_READ
    MOV     R0, #0                  @ R0 = 0 ;file descriptor for stdin 
    LDR     R1, =input_buffer       @ R1 = Address of the input_buffer 
    MOV     R2, #INPUT_BUFFER_SIZE  @ R2 = Max bytes to read 
    SVC     #0                      @ Perform the system call

    b       shell_loop

    .end
