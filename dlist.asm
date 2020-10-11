  icl 'const.inc' 

display_list
  dta $70, $70, $70, $4d, a(VRAM), $0d, $0d, $0d, $0d, $0d
  dta $0d, $0d, $10, $0d, $0d, $0d, $0d, $0d, $0d, $0d
  dta $0d, $0d, $10, $10, $0d, $0d, $0d, $0d, $0d, $0d
  dta $0d, $0d, $0d, $0d, $0d, $0d, $0d, $0d, $0d, $0d
  dta $0d, $0d, $0d, $0d, $0d, $0d, $0d, $0d, $30, $5d
  dta a(VRAM+41*40), $5d, a(VRAM+41*40+$50), $5d, a(VRAM+41*40+$a0), $5d, a(VRAM+41*40+$f0), $5d, a(VRAM+41*40+$140), $5d
  dta a(VRAM+41*40+$190), $5d, a(VRAM+41*40+$1e0), $5d, a(VRAM+41*40+$230), $5d, a(VRAM+41*40+$280), $f0, $42, a(VRAM+41*40+9*80)
  dta $f0, $02, $02, $02, $02, $02, $02, $02, $80, $02
  dta $41, a(DLIST)

