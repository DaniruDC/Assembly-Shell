@ Constants for System Calls and File Descriptors
.equ SYS_EXIT, 1
.equ SYS_READ, 3
.equ SYS_WRITE, 4
.equ SYS_GETTIMEOFDAY, 78 @ System call for gettimeofday

.equ STDIN, 0
.equ STDOUT, 1

.equ NEWLINE, 10
.equ NULL, 0

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

    color_cmd: .asciz "color"
    .set COLOR_CMD_LEN, . - color_cmd - 1

    help_msg: .asciz "Available commands:\n\nhello - Prints 'Hello World!'\nhelp - Lists all commands\nexit - Terminates the shell\nclear - Clears the screen\ncolor - Changes text color\nheartsay - Prints a message in a heart (e.g., heartsay hello)\n"
    HELP_MSG_LEN = . - help_msg - 1 

    exit_cmd: .asciz "exit"
    EXIT_CMD_LEN = . - exit_cmd - 1

    clear_cmd: .asciz "clear"
    CLEAR_CMD_LEN = . - clear_cmd - 1  

    clear_screen_ansi: .asciz "\x1b[2J\x1b[H"
    CLEAR_SCREEN_ANSI_LEN = . - clear_screen_ansi - 1 

    color_usage_msg: .asciz "Usage: color <red|green|blue|reset>\n"
    .set COLOR_USAGE_MSG_LEN, . - color_usage_msg - 1

    @ Heartsay Command Data
    heartsay_cmd: .asciz "heartsay"
    .set HEARTSAY_CMD_LEN, . - heartsay_cmd - 1
    heartsay_usage_msg: .asciz "Usage: heartsay <message>\n"
    .set HEARTSAY_USAGE_MSG_LEN, . - heartsay_usage_msg - 1
    heart_top: .asciz " <3 <3 <3 <3\n< "
    .set HEART_TOP_LEN, . - heart_top -1
    heart_bottom: .asciz " >\n <3 <3 <3 <3\n"
    .set HEART_BOTTOM_LEN, . - heart_bottom -1

    @ Color Argument Strings
    red_str:   .asciz "red"
    green_str: .asciz "green"
    blue_str:  .asciz "blue"
    reset_str: .asciz "reset"

    ansi_red:    .asciz "\x1b[31m"
    .set ANSI_RED_LEN, . - ansi_red - 1
    ansi_green:  .asciz "\x1b[32m"
    .set ANSI_GREEN_LEN, . - ansi_green - 1
    ansi_blue:   .asciz "\x1b[34m"
    .set ANSI_BLUE_LEN, . - ansi_blue - 1
    ansi_reset:  .asciz "\x1b[0m"
    .set ANSI_RESET_LEN, . - ansi_reset - 1
    

    .bss
    input_buffer: .space 256 @reserve 256 bytes for user input
    INPUT_BUFFER_SIZE = 256

    .text
    .global main

main:

shell_loop:
    @ 1. Print prompt
    MOV     R7, #SYS_WRITE              @ R7 = SYS_WRITE
    MOV     R0, #STDOUT              @ R0 = 1 ;file descriptor for stdout
    LDR     R1, =shell_prompt   @ R1 = Address of the shell_prompt string
    LDR     R2, =PROMPT_LEN     @ R2 = Length of the prompt string
    SVC     #0                  @ Execute system call

    @ 2. Read Input
    MOV     R7, #SYS_READ                 @ R7 = SYS_READ
    MOV     R0, #STDIN                  @ R0 = 0 ;file descriptor for stdin 
    LDR     R1, =input_buffer       @ R1 = Address of the input_buffer 
    MOV     R2, #INPUT_BUFFER_SIZE  @ R2 = Max bytes to read 
    SVC     #0                      @ Perform the system call
    
    @strip newline
    MOV     R5, R0                 @ Save 'bytes_read' into R5, as R0 will be used in subsequent operations

    CMP     R5, #0                 @ Check if any bytes were actually read
    BEQ     after_strip            @ If R5 is 0 (empty line), skip stripping

    @ Calculate address of the last character read: input_buffer + (bytes_read - 1)
    SUB     R3, R5, #SYS_EXIT             @ R3 = bytes_read - 1 (offset to the last character)
    ADD     R3, R1, R3             @ R3 = address of input_buffer + offset (points to the last char)

    LDRB    R4, [R3]               @ Load the character at that position into R4
    CMP     R4, #NEWLINE                @ Is it a newline character (ASCII 10)?
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
    LDR     R1, =test_string    @ Second string address (e.g., "hello")
    BL      strcmp              @ Branch with Link to strcmp. LR now holds return address.

    CMP     R0, #0              @ Compare R0 with 0
    BEQ     handle_hello_command_match   

    @Compare input with "help"
    LDR     R0, =input_buffer
    LDR     R1, =help_cmd
    BL      strcmp
    CMP     R0, #0
    BEQ     handle_help_command_match

    @ Compare with "color" command (special case with arguments)
    LDR     R0, =input_buffer
    LDR     R1, =color_cmd
    MOV     R2, #COLOR_CMD_LEN
    BL      strncmp
    CMP     R0, #0
    BEQ     handle_color_command 

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

    @ Compare with "heartsay" (uses strncmp)
    LDR     R0, =input_buffer
    LDR     R1, =heartsay_cmd
    MOV     R2, #HEARTSAY_CMD_LEN
    BL      strncmp
    CMP     R0, #0
    BEQ     handle_heartsay_cmd

    B       strings_are_not_equal @ If R0 is not 0, branch to not equal handler

handle_hello_command_match:
    MOV     R7, #SYS_WRITE
    MOV     R0, #SYS_EXIT 
    LDR     R1, =hello_world_msg
    MOV     R2, #HELLO_WORLD_MSG_LEN
    SVC     #0
    B       shell_loop

handle_help_command_match:
    MOV     R7, #SYS_WRITE
    MOV     R0, #SYS_EXIT
    LDR     R1, =help_msg
    LDR     R2, =HELP_MSG_LEN
    SVC     #0
    B       shell_loop

handle_exit_command_match:
    MOV     R7, #SYS_EXIT              @ SYS_EXIT
    MOV     R0, #0              @ Exit code 0
    SVC     #0                  @ Execute system call to exit

handle_clear_command_match:
    MOV     R7, #SYS_WRITE              @ SYS_WRITE
    MOV     R0, #SYS_EXIT              @ File descriptor for stdout
    LDR     R1, =clear_screen_ansi  @ ANSI escape code to clear the screen
    MOV     R2, #CLEAR_SCREEN_ANSI_LEN  @ Length of the escape code
    SVC     #0                  @ Execute system call to clear the screen
    B       shell_loop

strings_are_not_equal:
    B       shell_loop

handle_color_command:
    @ First, check if an argument was even provided.
    SUB     R6, R5, #1              @ R6 = length of the input string
    LDR     R7, =COLOR_CMD_LEN      @ R7 = length of "color" (5)
    CMP     R6, R7                  @ Compare lengths
    BEQ     invalid_color_arg       @ If equal, no argument was given.

    @ Argument exists. Move pointer past "color " to read it.
    LDR     R0, =input_buffer
    ADD     R0, R0, #6

    @ Check which color it is
    LDR R1, =red_str
    BL strcmp
    CMP R0, #0
    BEQ set_red

    LDR R0, =input_buffer
    ADD R0, R0, #6
    LDR R1, =green_str
    BL strcmp
    CMP R0, #0
    BEQ set_green

    LDR R0, =input_buffer
    ADD R0, R0, #6
    LDR R1, =blue_str
    BL strcmp
    CMP R0, #0
    BEQ set_blue

    LDR R0, =input_buffer
    ADD R0, R0, #6
    LDR R1, =reset_str
    BL strcmp
    CMP R0, #0
    BEQ set_reset

    @ If we get here, the argument was not "red", "green", "blue", or "reset".
    B       invalid_color_arg

set_red:
    LDR R1, =ansi_red
    MOV R2, #ANSI_RED_LEN
    B   print_color
set_green:
    LDR R1, =ansi_green
    MOV R2, #ANSI_GREEN_LEN
    B   print_color
set_blue:
    LDR R1, =ansi_blue
    MOV R2, #ANSI_BLUE_LEN
    B   print_color
set_reset:
    LDR R1, =ansi_reset
    MOV R2, #ANSI_RESET_LEN
    B   print_color

print_color:
    MOV     R7, #SYS_WRITE
    MOV     R0, #STDOUT
    SVC     #0
    B       shell_loop

invalid_color_arg:
    @ This label is used if no arg is given OR if the arg is invalid.
    MOV R7, #SYS_WRITE
    MOV R0, #STDOUT
    LDR R1, =color_usage_msg
    MOV R2, #COLOR_USAGE_MSG_LEN
    SVC #0
    B   shell_loop

handle_heartsay_cmd:
    SUB     R6, R5, #1              @ R6 = length of the input string
    LDR     R4, =HEARTSAY_CMD_LEN   @ R4 = length of "heartsay"
    ADD     R4, R4, #1              @ Add 1 for the space: "heartsay "
    CMP     R6, R4                  @ Is input length <= "heartsay "?
    BLE     invalid_heartsay_arg    @ If so, no message was given.

    @ Print top of heart
    MOV R7, #SYS_WRITE
    MOV R0, #STDOUT
    LDR R1, =heart_top
    LDR R2, =HEART_TOP_LEN
    SVC #0;

    @ Print user message
    LDR     R1, =input_buffer       @ R1 = start of buffer
    ADD     R1, R1, R4              @ R1 = start of buffer + len("heartsay ") = message
    SUB     R2, R6, R4              @ R2 = total_len - len("heartsay ") = msg_len
    MOV R7, #SYS_WRITE
    MOV R0, #STDOUT
    SVC #0;

    @ Print bottom of heart
    MOV R7, #SYS_WRITE
    MOV R0, #STDOUT
    LDR R1, =heart_bottom
    LDR R2, =HEART_BOTTOM_LEN
    SVC #0;
    B       shell_loop

invalid_heartsay_arg:
    MOV R7, #SYS_WRITE
    MOV R0, #STDOUT
    LDR R1, =heartsay_usage_msg
    MOV R2, #HEARTSAY_USAGE_MSG_LEN
    SVC #0
    B shell_loop

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

@ strncmp: Compares up to n characters of two strings.
@ R0: Address of string 1
@ R1: Address of string 2
@ R2: Number of bytes to compare (n)
@ Returns: R0 = 0 if equal, 1 if not equal
strncmp:
    PUSH    {R3, R4, R5, LR}
    MOV     R5, R2 @ Copy n to R5
strncmp_loop:
    CMP     R5, #0
    BEQ     strncmp_equal
    LDRB    R3, [R0], #1
    LDRB    R4, [R1], #1
    CMP     R3, R4
    BNE     strncmp_not_equal
    CMP     R3, #0
    BEQ     strncmp_equal
    SUB     R5, R5, #1
    B       strncmp_loop
strncmp_not_equal:
    MOV R0, #1
    POP {R3, R4, R5, LR}
    BX LR

strncmp_equal:
    MOV R0, #0
    POP {R3, R4, R5, LR}
    BX LR

    .end 
    