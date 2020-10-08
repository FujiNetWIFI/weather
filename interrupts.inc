(* declare your interrupt routines here *)

procedure dli;assembler;interrupt;
asm {
    pha ; store registers

    sta wsync
    mva 712 atari.colpf2 ; change backgroung color to white
    mva #$f atari.colpf1 ; change backgroung color to white
    
    pla ; restore registers
};
end;

procedure vbl;assembler;interrupt;
asm {
    phr ; store registers
    
;   *** example test routine    
;    mva 20 atari.colbk // blink background
    
;   *** RMT play routine
;    lda MSX
;    ldy MSX+1
;    jsr RMT.TRMT.PLAY

    plr ; restore registers
    jmp $E462 ; jump to system VBL handler
};
end;
