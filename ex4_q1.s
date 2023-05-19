.global main
.text

main:
    addi $3, $0, 3 
    lw $3, 0x73009($0)

    movsg $2, $cctrl
    andi $2, $2, 0x000f
    ori $2, $2, 0x22
    movgs $cctrl, $2 

    movsg $2, $evec         #Copy the old handler’s address to $2
    sw $2, old_handler($0)  #Save it to memory
    la $2, handler          #Get the address of our handler
    movgs $evec, $2         #And copy it into the $evec register

loop:
    sw $3, 0x73009($0)
j loop

handler:
    movsg $13, $estat       #Get the value of the exception status register
    andi $13, $13, 0xffd0   #Check if interrupt we don’t handle ourselves
    beqz $13, handle_irq1   #If it one of ours, go to our handler
    
    lw $13, old_handler($0) #Otherwise, jump to the default handler
    jr $13                  #That we saved earlier.

handle_irq1:
    addi $3, $3, 1          #Handle our interrupt
    sw $0, 0x7f000($0)      #Acknowledge the interrupt
    rfe 

.data
old_handler:
    .word 0