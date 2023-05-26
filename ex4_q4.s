.global main
.text

#======Main and Loops=====================
main:
    addi $4, $0, 0x1        #termination flag enable
    sw $4, tflag($0)
    addi $4, $0, 0x1        #printer disable
    sw $4, printer($0)
    add $3, $0, $0          #init counter 

    movsg $2, $cctrl        #Get val of cctrl
    andi $2, $2, 0x000f     #Disable interrupts
    ori $2, $2, 0xC2        #Enable irq2 and 3
    movgs $cctrl, $2        #store back in cctrl

    sw $0, 0x72003($0)      #Make sure there are no old interrupts still hanging around
    addi $11, $0, 24        #Put our auto load value in
    sw $11, 0x72001($0)
    addi $11, $0, 0x2       #Enable the timer
    sw $11, 0x72000($0)
    addi $2, $0, 0x3        #Paralell control interupt enable 
    sw $2, 0x73004($0)

    movsg $2, $evec         #Copy the old handler’s address to $2
    sw $2, old_handler($0)  #Save it to memory
    la $2, handler          #Get the address of our handler
    movgs $evec, $2         #And copy it into the $evec register

loop:
    lw $4, tflag($0)        #test termination flag
    beqz $4, end            #if termination flag set to zero, got to end subR
    lw $4, printer($0)      #test printer
    beqz $4, serialprinter  #if printer set to zero, got to end subR


    divi $4, $3, 100        #divide counter by 100 for ssd display

    remi $6, $4, 10         #get 1s
    divi $7, $4, 10         #get 10s

    sw $6,0x73009($0)       #display 1s
    sw $7,0x73008($0)       #display 10s

    snei $6, $4, 99         #if counter hits max limit then jump to end subR
    beqz $6, end
    j loop                  #repeat main diplay loop

SerialPoller:
    lw $13, 0x71003($0)     #get serial port status 
    andi $13, $13, 0x2      #Check if the TDS bit is set
    beqz $13, SerialPoller #if not repeat
    jr $ra

serialprinter:
    jal SerialPoller
    addi $4, $0, '\n'
    sw $4, 0x71000($0)      #print time to SP2
   
    jal SerialPoller
    addi $4, $0, '\r'
    sw $4, 0x71000($0)      #print time to SP2

    add $4, $3, $0
    
    jal SerialPoller
    divi $6, $4, 10000         #get 1s
    addi $6, $6, 0x30
    sw $6, 0x71000($0)      #print time to SP2

    
    jal SerialPoller
    divi $6, $4, 1000         #get 1s
    addi $6, $6, 0x30
    sw $6, 0x71000($0)      #print time to SP2

    jal SerialPoller
    addi $5, $0, '.'
    sw $5, 0x71000($0)      #print time to SP2

    jal SerialPoller
    divi $6, $4, 100         #get 1s
    addi $6, $6, 0x30
    sw $6, 0x71000($0)      #print time to SP2
    
    jal SerialPoller
    divi $6, $4, 10         #get 1s
    addi $6, $6, 0x30
    sw $6, 0x71000($0)      #print time to SP2

    addi $4, $0, 0x1        #printer disable
    sw $4, printer($0)
    j loop

#======handlers===================================
handler:
    movsg $13, $estat       #Get the value of the exception status register
    andi $13, $13, 0xffb0   #Check for timer/irq2 interrupt
    beqz $13, handle_irq2   #If it one of ours, go to our handler

    movsg $13, $estat       #Get the value of the exception status register
    andi $13, $13, 0xff70   #Check for Button/irq3 interrupt
    beqz $13, handle_pp     #If it one of ours, go to our handler
    
    lw $13, old_handler($0) #Otherwise, jump to the default handler
    jr $13                  #That we saved earlier.

handle_irq2:
    addi $3, $3, 1          #Handle our interrupt/increment counter
    sw $0, 0x72003($0)      #Acknowledge the interrupt
    rfe 
    
handle_pp:
    lw $13, 0x73001($0)     #get button value
    beqz $13, handle_pp_exit    #if not a button i.e other paralell, exit and acknowledge

    subi $4, $13, 0x1       #is it button RHS/0
    beqz $4, startstop      #pause
    
    subi $4, $13, 0x2       #is it button MID/1
    beqz $4, resetWhenOff   #reset timer
    
    subi $4, $13, 0x4       #is it button LHS/2
    beqz $4, terminationflag    #terminate prog

handle_pp_exit:
    sw $0, 0x73005($0)      #Acknowledge the interrupt
    rfe 

#=========Button push handlers==============================
startstop:                  #pause    
    lw $13, 0x72000($0)     #get timer control bit
    xori $13, $13, 0x1      #toggle timer enable only
    sw $13, 0x72000($0)     #set timer control bit
    j handle_pp_exit        #exit interrupt handler

resetWhenOff:
    lw $13, 0x72000($0)     #get timer control bit    
    subi $13, $13, 0x3      #is the timer running
    beqz $13, serialprinterSet  #if timer running, got to printer
    add $3, $0, $0          #if not, reset timer     
    j handle_pp_exit        #exit interrupt handler

serialprinterSet:
    add $13, $0, $0
    sw $13, printer($0)
    j handle_pp_exit        #exit interrupt handler    

terminationflag:
    add $13, $0, $0
    sw $13, tflag($0)
    j handle_pp_exit        #exit interrupt handler

#===========End Clause=================================
end:                        #terminate prog
    jr $ra

#===========Memory=================================

.bss
old_handler:
    .word
.data
    counter:
    .word 0
    tflag:
    .word 0 
    printer:
    .word 0