\ 8086 registers
0 Constant ax   1 Constant cx   2 Constant dx   3 Constant bx
4 Constant sp   5 Constant bp   6 Constant si   7 Constant di
8 Constant al   9 Constant cl  $a Constant dl  $b Constant bl
\ $c Constant ah  $d Constant ch  $e Constant dh  $f Constant bh

0 Constant #add
1 Constant #adc
2 Constant #sbb
3 Constant #and
4 Constant #sub
5 Constant #xor
6 Constant #cmp


: $b,
    3 6 shiftl >r
    3 shiftl r> and
    and
;

: reg,
    
    
: movl,
    $8a literal
    
