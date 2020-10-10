  icl 'const.inc' 

display_list
  dta $70, $70, $70, $4d, a(VRAM), $0d, $0d, $0d, $0d, $0d
  dta $0d, $0d, $10, $0d, $0d, $0d, $0d, $0d, $0d, $0d
  dta $0d, $0d, $10, $10, $0d, $0d, $0d, $0d, $0d, $0d
  dta $0d, $0d, $0d, $0d, $0d, $0d, $0d, $0d, $0d, $0d
  dta $0d, $0d, $0d, $0d, $0d, $0d, $0d, $0d, $30, $0d
  dta $0d, $0d, $0d, $0d, $0d, $0d, $0d, $0d, $f0, $02
  dta $f0, $02, $02, $02, $02, $02, $02, $02, $80, $02
  dta $41, a(DLIST)

