.global main
.text

main:
    movsg $2, $evec
    sw $2, old_handler($0)
    la $2, handler
    movgs $evec, $2

handler:

.data
old_handler:
    .word