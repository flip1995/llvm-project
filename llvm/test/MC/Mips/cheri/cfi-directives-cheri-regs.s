# RUN: %cheri128_purecap_llvm-mc %s -show-encoding -filetype=obj -o %t.purecap
# RUN: %cheri128_llvm-mc %s -show-encoding -filetype=obj -o %t.hybrid
# RUN: llvm-dwarfdump -all %t.purecap | FileCheck %s -check-prefixes=CHECK,PURECAP
# RUN: llvm-dwarfdump -all %t.hybrid | FileCheck %s -check-prefixes=CHECK,HYBRID

# llvm-mc used to not parse $cNN register correctly and always used -1 instead.
# This caused completely useless debug information when I tried to annotate the
# lazy binding resolver.

.text
.ent b
b:
  .cfi_startproc
  .frame	$c11,48,$c17
  .mask 	0x00000000,0
  .fmask	0x00000000,0
  cincoffset	$c11, $c11, -48
  .cfi_def_cfa_offset 48
  nop
  .cfi_def_cfa  $sp, 64 # Should result in register 29
  nop
  .cfi_def_cfa  $c11, 32  # Should be register 83
  nop
  .cfi_offset $c18, -32
  nop
  # FIXME: for some reason LLVM truncates this to 6 bits so it ends up being 25
  .cfi_restore $c17 # should be dwarf reg 89
  .cfi_endproc

.end b

# HYBRID:   DW_CFA_def_cfa_register: SP_64
# PURECAP:   DW_CFA_def_cfa_register: C11

# HYBRID:      00000014 00000028 00000018 FDE cie=00000000 pc=00000000...00000014
# PURECAP:     00000014 00000020 00000018 FDE cie=00000000 pc=00000000...00000014
# CHECK-NEXT:   Format: DWARF32
# CHECK-NEXT:   DW_CFA_advance_loc: 4
# CHECK-NEXT:   DW_CFA_def_cfa_offset: +48
# CHECK-NEXT:   DW_CFA_advance_loc: 4
# CHECK-NEXT:   DW_CFA_def_cfa: SP_64 +64
# CHECK-NEXT:   DW_CFA_advance_loc: 4
# CHECK-NEXT:   DW_CFA_def_cfa: C11 +32
# CHECK-NEXT:   DW_CFA_advance_loc: 4
# CHECK-NEXT:   DW_CFA_offset_extended: C18 -32
# CHECK-NEXT:   DW_CFA_advance_loc: 4
# CHECK-NEXT:   DW_CFA_restore_extended: C17
# CHECK-NEXT:   DW_CFA_nop:
# CHECK-EMPTY:
