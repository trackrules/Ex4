.global main
.text

main:
    addi $4, $0, 0x1
    sw $4, tflag($0)
    add $3, $0, $0 

    movsg $2, $cctrl        #Get val of cctrl
    andi $2, $2, 0x000f     #Disable interrupts
    ori $2, $2, 0xC2        #Enable irq2
    movgs $cctrl, $2        #store back in cctrl

    sw $0, 0x72003($0)      # Make sure there are no old interrupts still hanging around
    addi $11, $0, 2400    # Put our auto load value in
    sw $11, 0x72001($0)
    addi $11, $0, 0x2       # Enable the timer and autorestart
    sw $11, 0x72000($0)
    addi $2, $0, 0x3      
    sw $2, 0x73004($0)

    movsg $2, $evec         #Copy the old handler’s address to $2
    sw $2, old_handler($0)  #Save it to memory
    la $2, handler          #Get the address of our handler
    movgs $evec, $2         #And copy it into the $evec register

loop:
    lw $4, tflag($0)
    beqz $4, end
    remi $6, $3, 10
    divi $7, $3, 10

    sw $6,0x73009($0)
    sw $7,0x73008($0)

    snei $6, $3, 99
    beqz $6, end
j loop

handler:


    movsg $13, $estat       #Get the value of the exception status register
    andi $13, $13, 0xffb0   #Check if interrupt we don’t handle ourselves
    beqz $13, handle_irq2   #If it one of ours, go to our handler

    movsg $13, $estat       #Get the value of the exception status register
    andi $13, $13, 0xff70   #Check if interrupt we don’t handle ourselves
    beqz $13, handle_pp     #If it one of ours, go to our handler
    
    lw $13, old_handler($0) #Otherwise, jump to the default handler
    jr $13                  #That we saved earlier.

handle_irq2:
    addi $3, $3, 1          #Handle our interrupt
    sw $0, 0x72003($0)      #Acknowledge the interrupt
    rfe 
    
handle_pp:
    lw $13, 0x73001($0)
    beqz $13, handle_pp_exit

    subi $4, $13, 0x1
    beqz $4, startstop
    
    subi $4, $13, 0x2
    beqz $4, resetWhenOff
    
    subi $4, $13, 0x4
    beqz $4, terminationflag            #terminate

handle_pp_exit:
    sw $0, 0x73005($0)      #Acknowledge the interrupt
    rfe 

startstop:
    lw $13, 0x72000($0)
    xori $13, $13, 0x1    #should work
    sw $13, 0x72000($0)
    j handle_pp_exit

resetWhenOff:
    lw $13, 0x72000($0)
    subi $13, $13, 0x3
    beqz $13, handle_pp_exit
    add $3, $0, $0
    j handle_pp_exit

terminationflag:
    add $13, $0, $0
    sw $13, tflag($0)
    j handle_pp_exit

end:
    jr $ra

.bss
old_handler:
    .word
.data
    counter:
    .word 0
    tflag:
    .word 0 