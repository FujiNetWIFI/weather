(* declare your interrupt routines here *)

procedure dli;assembler;interrupt;
asm {
    pha ; store registers

    sta wsync
    mva 712 atari.colpf2 
    mva cityColor atari.colpf1 
    
    
    mwa #dli2 VDSLST    
    pla ; restore registers
};
end;

procedure dli2;assembler;interrupt;
asm {
    pha ; store registers

    sta wsync
    mva #$f atari.colpf1 
    
    mwa #dli3 VDSLST    
    pla ; restore registers
};
end;

procedure dli3;assembler;interrupt;
asm {
    pha ; store registers

    sta wsync
    mva menuColor atari.colpf1 ; change backgroung color to white
    
    mwa #dli VDSLST    
    pla ; restore registers
};
end;

