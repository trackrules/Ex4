.global main
.text

main:
    add $3, $0, $0          #init counter 
    sw $3, counter($0)

    movsg $2, $cctrl        #Get val of cctrl
    andi $2, $2, 0x000f     #Disable interrupts
    ori $2, $2, 0xA2        #Enable irq1
    movgs $cctrl, $2        #store back in cctrl

    addi $7, $0, 0x3        #Paralell control interupt enable 
    sw $7, 0x73004($0)

    movsg $2, $evec         #Copy the old handler’s address to $2
    sw $2, old_handler($0)  #Save it to memory
    la $2, handler          #Get the address of our handler
    movgs $evec, $2         #And copy it into the $evec register

loop:
    lw $3, counter($0)      #get counter val

    remi $6, $3, 10         #get 1s
    divi $7, $3, 10         #get 10s

    sw $6,0x73009($0)       #display 1s
    sw $7,0x73008($0)       #display 10s


    snei $6, $3, 99         #stop value set
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
    lw $13, counter($0)
    addi $13, $13, 1          #Handle our interrupt/increment counter
    sw $13, counter($0)
    sw $0, 0x7f000($0)      #Acknowledge the interrupt
    rfe 

handle_pp:
    lw $13, 0x73001($0)         #get button value
    beqz $13, handle_pp_exit     #if not a button i.e other paralell, exit and acknowledge
    lw $13, counter($0)
    addi $13, $13, 1          #Handle our interrupt/increment counter
    sw $13, counter($0)

handle_pp_exit:
    sw $0, 0x73005($0) 
    rfe 

end:

.bss
old_handler:
    .word
.data
    counter:
    .word 0