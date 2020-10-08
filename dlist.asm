  icl 'const.inc' 

display_list
  dta $70, $70, $70, $4d, a(VRAM), $0d, $0d, $0d, $0d, $0d
  dta $0d, $0d, $0d, $0d, $0d, $0d, $0d, $0d, $0d, $0d
  dta $0d, $0d, $0d, $0d, $0d, $0d, $0d, $0d, $0d, $0d
  dta $0d, $0d, $0d, $0d, $0d, $0d, $0d, $0d, $0d, $0d
  dta $0d, $0d, $0d, $0d, $0d, $0d, $0d, $0d, $b0, $02
  dta $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
  dta $02, $41, a(DLIST)
