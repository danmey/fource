\ 8086 registers
0 Constant ax   1 Constant cx   2 Constant dx   3 Constant bx
4 Constant sp   5 Constant bp   6 Constant si   7 Constant di
8 Constant al   9 Constant cl  $a Constant dl  $b Constant bl
$c Constant ah  $d Constant ch  $e Constant dh  $f Constant bh
\ ALU instructions
0 Constant #add
1 Constant #adc
2 Constant #sbb
3 Constant #and
4 Constant #sub
5 Constant #xor
6 Constant #cmp
\ Condition codes
0 Constant eq 1 Constant ne
\ regsrc regdst modifier -- 
: addrb, 3 And 6 Lshift swap 7 and Lshift 3 Or swap 7 And Or c, ;
\ immediate value tag
: # $ff ;
: inc, $40 + c, ; : dec, $48 + c, ;
: jmp, $eb c, 2 - c, ; immediate 
: mov, swap dup # = if drop $b8 + c, , else swap $8b c, 3 addrb, then ; immediate
: test
    [
    100 # bx mov,
    bx ax mov,
    inc,
    dec,
    dec,
    ] ;

: test-jmp 1 [ here ] dup . [ ax inc, here - jmp, ] ;

\ test-jmp
