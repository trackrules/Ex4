.global main
.text

main:
    add $3, $0, $0 
    addi $5, $5, 1

    movsg $2, $cctrl
    andi $2, $2, 0x000f
    ori $2, $2, 0xA2
    movgs $cctrl, $2 

    addi $7, $0, 0x3 
    sw $7, 0x73004($0)

    movsg $2, $evec         #Copy the old handler’s address to $2
    sw $2, old_handler($0)  #Save it to memory
    la $2, handler          #Get the address of our handler
    movgs $evec, $2         #And copy it into the $evec register

loop:
    remi $6, $3, 10
    divi $7, $3, 10

    sw $6,0x73009($0)
    sw $7,0x73008($0)

    snei $6, $3, 99
    beqz $6, end
j loop

handler:
    movsg $13, $estat       #Get the value of the exception status register
    andi $13, $13, 0xffd0   #Check if interrupt we don’t handle ourselves
    beqz $13, handle_irq1   #If it one of ours, go to our handler

    movsg $13, $estat       #Get the value of the exception status register
    andi $13, $13, 0xff70   #Check if interrupt we don’t handle ourselves
    beqz $13, handle_pp     #If it one of ours, go to our handler

    lw $13, old_handler($0) #Otherwise, jump to the default handler
    jr $13                  #That we saved earlier.

handle_irq1:
    addi $3, $3, 1          #Handle our interrupt
    sw $0, 0x7f000($0)      #Acknowledge the interrupt
    rfe 

handle_pp:
    lw $13, 0x73001($0)
    beqz $13, handle_pp_exit
    addi $3, $3, 1          #Handle our interrupt

handle_pp_exit:
    sw $0, 0x73005($0) 
    rfe 

end:

.bss
old_handler:
    .word