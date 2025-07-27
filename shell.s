.data
    shell_prompt: .asciz "shell> "
    .set PROMPT_LEN, . - shell_prompt - 1 @ Calculate length: current address - start address - 1

    test_string: .asciz "hello" @ String to compare user input against
    test_string_len = . - test_string - 1 

    hello_world_msg: .asciz "Hello World!\n"
    HELLO_WORLD_MSG_LEN = . - hello_world_msg - 1

    invalid_input_msg: .asciz "Invalid Input!\n"
    INVALID_INPUT_MSG_LEN = . - invalid_input_msg - 1

    help_cmd: .asciz "help"
    HELP_CMD_LEN = . - help_cmd - 1

    help_msg: .asciz "Available commands:\n\nhello - Prints 'Hello World!'\nhelp - Lists all commands\nexit - Terminates the shell\nclear - Clears the screen\n"
    HELP_MSG_LEN = . - help_msg - 1 

    exit_cmd: .asciz "exit"
    EXIT_CMD_LEN = . - exit_cmd - 1

    clear_cmd: .asciz "clear"
    CLEAR_CMD_LEN = . - clear_cmd - 1  

    clear_screen_ansi: .asciz "\x1b[2J\x1b[H"
    CLEAR_SCREEN_ANSI_LEN = . - clear_screen_ansi - 1 
    

    .bss
    input_buffer: .space 256 @reserve 256 bytes for user input
    INPUT_BUFFER_SIZE = 256

    .text
    .global main

main:

shell_loop:
    @ 1. Print prompt
    MOV     R7, #4              @ R7 = SYS_WRITE
    MOV     R0, #1              @ R0 = 1 ;file descriptor for stdout
    LDR     R1, =shell_prompt   @ R1 = Address of the shell_prompt string
    LDR     R2, =PROMPT_LEN     @ R2 = Length of the prompt string
    SVC     #0                  @ Execute system call

    @ 2. Read Input
    MOV     R7, #3                  @ R7 = SYS_READ
    MOV     R0, #0                  @ R0 = 0 ;file descriptor for stdin 
    LDR     R1, =input_buffer       @ R1 = Address of the input_buffer 
    MOV     R2, #INPUT_BUFFER_SIZE  @ R2 = Max bytes to read 
    SVC     #0                      @ Perform the system call
    
    @strip newline
    MOV     R5, R0                 @ Save 'bytes_read' into R5, as R0 will be used in subsequent operations

    CMP     R5, #0                 @ Check if any bytes were actually read
    BEQ     after_strip            @ If R5 is 0 (empty line), skip stripping

    @ Calculate address of the last character read: input_buffer + (bytes_read - 1)
    SUB     R3, R5, #1             @ R3 = bytes_read - 1 (offset to the last character)
    ADD     R3, R1, R3             @ R3 = address of input_buffer + offset (points to the last char)

    LDRB    R4, [R3]               @ Load the character at that position into R4
    CMP     R4, #10                @ Is it a newline character (ASCII 10)?
    BEQ     replace_with_null      @ If yes, jump to replace it

    @ If the last character was NOT a newline, ensure null termination *after* the last actual character
    ADD     R3, R1, R5             @ R3 = input_buffer_address + bytes_read (points *after* the last char)
    B       store_null             @ Jump to store the null

replace_with_null:
    @ R3 already points to the newline. Now, store null at this location.
store_null:
    MOV     R4, #0                 @ Load null byte (0) into R4
    STRB    R4, [R3]               @ Store null byte (from R4) at the address in R3

after_strip:
    @ Ensure input_buffer[0] is null for a completely empty line (user just pressed Enter)
    CMP     R5, #0                 @ Check original 'bytes_read' (saved in R5)
    BNE     continue_strcmp        @ If R5 is not 0, means input was not empty, so skip this part.

    MOV     R4, #0                 @ Load null byte into R4
    STRB    R4, [R1]               @ Store null at input_buffer[0] (R1 is input_buffer base address)

    @test
continue_strcmp:
    @ Compare input with "hello"
    LDR     R0, =input_buffer   @ First string address (user input)
    LDR     R1, =test_string    @ Second string address
    BL      strcmp              @ Branch with Link to strcmp. LR now holds return address.

    CMP     R0, #0              @ Compare R0 with 0
    BEQ     handle_hello_command_match   

    @Compare input with "help"
    LDR     R0, =input_buffer
    LDR     R1, =help_cmd
    BL      strcmp
    CMP     R0, #0
    BEQ     handle_help_command_match 

    @Compare input with "exit"
    LDR     R0, =input_buffer
    LDR     R1, =exit_cmd
    BL      strcmp
    CMP     R0, #0
    BEQ     handle_exit_command_match

    @Compare input with "clear"
    LDR     R0, =input_buffer
    LDR     R1, =clear_cmd
    BL      strcmp
    CMP     R0, #0
    BEQ     handle_clear_command_match

    B       strings_are_not_equal @ If R0 is not 0, branch to not equal handler

handle_hello_command_match:
    MOV     R7, #4
    MOV     R0, #1
    LDR     R1, =hello_world_msg
    MOV     R2, #HELLO_WORLD_MSG_LEN
    SVC     #0
    B       shell_loop

handle_help_command_match:
    MOV     R7, #4
    MOV     R0, #1
    LDR     R1, =help_msg
    LDR     R2, =HELP_MSG_LEN
    SVC     #0
    B       shell_loop

handle_exit_command_match:
    MOV     R7, #1              @ SYS_EXIT
    MOV     R0, #0              @ Exit code 0
    SVC     #0                  @ Execute system call to exit

handle_clear_command_match:
    MOV     R7, #4                      @ SYS_WRITE
    MOV     R0, #1                      @ File descriptor for stdout
    LDR     R1, =clear_screen_ansi      @ ANSI escape code to clear the screen
    MOV     R2, #CLEAR_SCREEN_ANSI_LEN  @ Length of the escape code
    SVC     #0                          @ Execute system call to clear the screen
    B       shell_loop

strings_are_not_equal:
    B       shell_loop

    @strcmp function definition

    @ R0: Address of string 1
    @ R1: Address of string 2
    @ Returns: R0 = 0 if equal, 1 if not equal
strcmp:
    PUSH    {R4, R5, LR}    @ Save registers used by this function and the Link Register

compare_loop:
    LDRB    R2, [R0]        @ Load byte from string 1 into R2
    LDRB    R3, [R1]        @ Load byte from string 2 into R3

    CMP     R2, R3          @ Compare the bytes
    BNE     not_equal       @ If bytes are not equal, strings are different

    CMP     R2, #0          @ Check if the current byte (from R2 or R3) is a null terminator
    BEQ     are_equal       @ If it is, and they were equal so far, then strings are equal

    ADD     R0, R0, #1      @ Increment address for string 1
    ADD     R1, R1, #1      @ Increment address for string 2
    B       compare_loop    @ Continue loop

not_equal:
    MOV     R0, #1          @ Set return value to 1 (not equal)
    POP     {R4, R5, LR}    @ Restore saved registers and Link Register
    BX      LR              @ Return to caller

are_equal:
    MOV     R0, #0          @ Set return value to 0 (equal)
    POP     {R4, R5, LR}    @ Restore saved registers and Link Register
    BX      LR              @ Return to caller

    .end 
    