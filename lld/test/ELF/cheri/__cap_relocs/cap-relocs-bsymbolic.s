# Check that we don't emit relocations against a symbol if -Bsymbolic is used
# All relocations should be load address plus offset and not preemptible!
# This was a problem with __cap_relocs and was found building RTLD

// RUN: %cheri128_purecap_llvm-mc -filetype=obj -defsym=CHERI=1 %s -o %t-cheri.o
// RUN: llvm-readobj -r -t %t-cheri.o | FileCheck %s --check-prefixes OBJ-RELOCS,CHERI-OBJ-RELOCS
// RUN: llvm-mc -triple=mips64-unknown-freebsd -position-independent -filetype=obj %s -o %t-mips.o
// RUN: llvm-readobj -r -t %t-mips.o | FileCheck %s --check-prefixes OBJ-RELOCS,MIPS-OBJ-RELOCS


# OBJ-RELOCS-LABEL: Relocations [
# OBJ-RELOCS-NEXT:   Section (4) .rela.data {
# CHERI-OBJ-RELOCS-NEXT:     0x0 R_MIPS_CHERI_CAPABILITY/R_MIPS_NONE/R_MIPS_NONE foo 0x0
# CHERI-OBJ-RELOCS-NEXT:     0x10 R_MIPS_CHERI_CAPABILITY/R_MIPS_NONE/R_MIPS_NONE bar 0x0
# CHERI-OBJ-RELOCS-NEXT:     0x20 R_MIPS_CHERI_CAPABILITY/R_MIPS_NONE/R_MIPS_NONE baz 0x7
# MIPS-OBJ-RELOCS-NEXT:     0x0 R_MIPS_64/R_MIPS_NONE/R_MIPS_NONE foo 0x0
# MIPS-OBJ-RELOCS-NEXT:     0x10 R_MIPS_64/R_MIPS_NONE/R_MIPS_NONE bar 0x0
# MIPS-OBJ-RELOCS-NEXT:     0x20 R_MIPS_64/R_MIPS_NONE/R_MIPS_NONE baz 0x7
# OBJ-RELOCS-NEXT:   }
# OBJ-RELOCS-NEXT:   Section (6) .rela.pdr {
# OBJ-RELOCS-NEXT:     0x0 R_MIPS_32/R_MIPS_NONE/R_MIPS_NONE foo 0x0
# OBJ-RELOCS-NEXT:   }
# OBJ-RELOCS-NEXT: ]


# RUN: ld.lld %t-mips.o -shared -o %t-mips.so
# RUN: llvm-readobj -r %t-mips.so | FileCheck %s --check-prefix MIPS-PREEMPTIBLE
# MIPS-PREEMPTIBLE-LABEL: Relocations [
# MIPS-PREEMPTIBLE-NEXT:    Section (7) .rel.dyn {
# MIPS-PREEMPTIBLE-NEXT:      0x204C0 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE foo{{$}}
# MIPS-PREEMPTIBLE-NEXT:      0x204D0 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE bar{{$}}
# MIPS-PREEMPTIBLE-NEXT:      0x204E0 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE baz{{$}}
# MIPS-PREEMPTIBLE-NEXT:    }
# MIPS-PREEMPTIBLE-NEXT:  ]
# RUN: llvm-objdump --section=.data -s %t-mips.so | FileCheck %s --check-prefix MIPS-PREEMPTIBLE-ADDEND
# Check that we have written the added 0x7 to the right location:
# MIPS-PREEMPTIBLE-ADDEND-LABEL: Contents of section .data:
# MIPS-PREEMPTIBLE-ADDEND-NEXT:  204c0 00000000 00000000 00000000 00000000  ................
# MIPS-PREEMPTIBLE-ADDEND-NEXT:  204d0 00000000 00000000 00000000 00000000  ................
# MIPS-PREEMPTIBLE-ADDEND-NEXT:  204e0 00000000 00000007 00000000 00000000  ................
#                                                   ^---- Addend for the baz relocation

# Now check for CHERI:
# RUN: ld.lld -preemptible-caprelocs=legacy --no-relative-cap-relocs %t-cheri.o -shared -o %t-cheri.so
# We have 3 load-address relocations for the location field in __cap_relocs and 3 dynamic relocations for the base against the symbols:
# RUN: llvm-readobj -r --cap-relocs %t-cheri.so | FileCheck %s --check-prefix CHERI-PREEMPTIBLE
# CHERI-PREEMPTIBLE-LABEL:  Relocations [
# CHERI-PREEMPTIBLE-NEXT:    Section (7) .rel.dyn {
# CHERI-PREEMPTIBLE-NEXT:      0x20590 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE -{{$}}
# CHERI-PREEMPTIBLE-NEXT:      0x205B8 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE -{{$}}
# CHERI-PREEMPTIBLE-NEXT:      0x205E0 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE -{{$}}
# CHERI-PREEMPTIBLE-NEXT:      0x20598 R_MIPS_CHERI_ABSPTR/R_MIPS_64/R_MIPS_NONE foo{{$}}
# CHERI-PREEMPTIBLE-NEXT:      0x205A8 R_MIPS_CHERI_SIZE/R_MIPS_64/R_MIPS_NONE foo{{$}}
# CHERI-PREEMPTIBLE-NEXT:      0x205C0 R_MIPS_CHERI_ABSPTR/R_MIPS_64/R_MIPS_NONE bar{{$}}
# CHERI-PREEMPTIBLE-NEXT:      0x205D0 R_MIPS_CHERI_SIZE/R_MIPS_64/R_MIPS_NONE bar{{$}}
# CHERI-PREEMPTIBLE-NEXT:      0x205E8 R_MIPS_CHERI_ABSPTR/R_MIPS_64/R_MIPS_NONE baz{{$}}
# CHERI-PREEMPTIBLE-NEXT:      0x205F8 R_MIPS_CHERI_SIZE/R_MIPS_64/R_MIPS_NONE baz{{$}}
# CHERI-PREEMPTIBLE-NEXT:    }
# CHERI-PREEMPTIBLE-NEXT:  ]

# In the case of CHERI we have the addend in the offset field of the cap reloc:
# and .data only contains three uninitialized capabilities:
# CHERI-PREEMPTIBLE-LABEL: CHERI __cap_relocs [
# CHERI-PREEMPTIBLE-NEXT:    0x030640 (funcptr)       Base: 0x0 (foo+0) Length: 0 Perms: Function
# CHERI-PREEMPTIBLE-NEXT:    0x030650 (intptr)        Base: 0x0 (bar+0) Length: 0 Perms: Object
# CHERI-PREEMPTIBLE-NEXT:    0x030660 (shortptr)      Base: 0x0 (baz+7) Length: 0 Perms: Object
# CHERI-PREEMPTIBLE-NEXT: ]
# RUN: llvm-objdump --section=.data -s %t-cheri.so | FileCheck %s --check-prefix CHERI-PREEMPTIBLE-ADDEND
# CHERI-PREEMPTIBLE-ADDEND-LABEL: Contents of section .data:
# CHERI-PREEMPTIBLE-ADDEND-NEXT:  30640 cacacaca cacacaca cacacaca cacacaca  ................
# CHERI-PREEMPTIBLE-ADDEND-NEXT:  30650 cacacaca cacacaca cacacaca cacacaca  ................
# CHERI-PREEMPTIBLE-ADDEND-NEXT:  30660 cacacaca cacacaca cacacaca cacacaca  ................


# RUN: ld.lld %t-mips.o -shared -Bsymbolic -o %t-mips-symbolic.so
# RUN: llvm-readobj -r %t-mips-symbolic.so | FileCheck %s --check-prefix MIPS-BSYMBOLIC
# Should only have three relocations against the load address here:
# MIPS-BSYMBOLIC-LABEL: Relocations [
# MIPS-BSYMBOLIC-NEXT:    Section (7) .rel.dyn {
# MIPS-BSYMBOLIC-NEXT:      0x204C0 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE -{{$}}
# MIPS-BSYMBOLIC-NEXT:      0x204D0 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE -{{$}}
# MIPS-BSYMBOLIC-NEXT:      0x204E0 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE -{{$}}
# MIPS-BSYMBOLIC-NEXT:    }
# MIPS-BSYMBOLIC-NEXT:  ]
# RUN: llvm-objdump --section=.data -s %t-mips-symbolic.so | FileCheck %s --check-prefix MIPS-BSYMBOLIC-ADDEND
# Check that we have written the added 0x7 to the right location:
# MIPS-BSYMBOLIC-ADDEND-LABEL: Contents of section .data:
# MIPS-BSYMBOLIC-ADDEND-NEXT:  204c0 00000000 00010490 00000000 00000000  ................
# MIPS-BSYMBOLIC-ADDEND-NEXT:  204d0 00000000 000204f0 00000000 00000000  ................
# MIPS-BSYMBOLIC-ADDEND-NEXT:  204e0 00000000 00020507 00000000 00000000  ................
#                                                ^---- All values filled in (including baz + 7)


# Now check for CHERI -Bsymbolic:
# RUN: ld.lld -preemptible-caprelocs=legacy --no-relative-cap-relocs %t-cheri.o -shared -Bsymbolic -o %t-cheri-symbolic.so
# With -BSymbolic all 6 relocations should be against the load address:
# We have 3 load-address relocations for the location field in __cap_relocs and 3 dynamic relocations for the base against the symbols:
# RUN: llvm-readobj -r --cap-relocs %t-cheri-symbolic.so | FileCheck %s --check-prefix CHERI-BSYMBOLIC
# CHERI-BSYMBOLIC-LABEL:  Relocations [
# CHERI-BSYMBOLIC-NEXT:    Section (7) .rel.dyn {
# CHERI-BSYMBOLIC-NEXT:      0x20570 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE -{{$}}
# CHERI-BSYMBOLIC-NEXT:      0x20578 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE -{{$}}
# CHERI-BSYMBOLIC-NEXT:      0x20598 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE -{{$}}
# CHERI-BSYMBOLIC-NEXT:      0x205A0 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE -{{$}}
# CHERI-BSYMBOLIC-NEXT:      0x205C0 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE -{{$}}
# CHERI-BSYMBOLIC-NEXT:      0x205C8 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE -{{$}}
# CHERI-BSYMBOLIC-NEXT:    }
# CHERI-BSYMBOLIC-NEXT:  ]

# RUN: llvm-objdump --section=.data -s %t-cheri-symbolic.so | FileCheck %s --check-prefix CHERI-BSYMBOLIC-ADDEND

# In the case of CHERI we have the addend in the offset field of the cap reloc:
# CHERI-BSYMBOLIC-LABEL: CHERI __cap_relocs [
# CHERI-BSYMBOLIC-NEXT:    0x030600 (funcptr)       Base: 0x10560 (foo+0) Length: 16 Perms: Function
# CHERI-BSYMBOLIC-NEXT:    0x030610 (intptr)        Base: 0x30630 (bar+0) Length: 4 Perms: Object
# CHERI-BSYMBOLIC-NEXT:    0x030620 (shortptr)      Base: 0x30640 (baz+7) Length: 32 Perms: Object
#                                                            ^---- All values filled in (but the +7 is in the offset field!)
# CHERI-BSYMBOLIC-NEXT: ]
# and .data only contains three uninitialized capabilities since it will be filled in by __cap_relocs processing:
# CHERI-BSYMBOLIC-ADDEND-LABEL: Contents of section .data:
# CHERI-BSYMBOLIC-ADDEND-NEXT:  30600 cacacaca cacacaca cacacaca cacacaca  ................
# CHERI-BSYMBOLIC-ADDEND-NEXT:  30610 cacacaca cacacaca cacacaca cacacaca  ................
# CHERI-BSYMBOLIC-ADDEND-NEXT:  30620 cacacaca cacacaca cacacaca cacacaca  ................

# TODO: check -Bsymbolic-functions as well?

.macro global_pointer name, target
  .type  \name,@object
  .globl  \name
  .p2align 4
   \name:
  .ifdef CHERI
    .chericap \target
    .size  \name, 16
  .else
    .quad \target
    .size  \name, 8
  .endif
.endm

.data

global_pointer funcptr, foo

global_pointer intptr, bar

global_pointer shortptr, (baz + 7)

.text
  .globl foo
  .p2align 3
  .type foo,@function
  .ent foo
foo:
  addiu $2, $zero, 42
  cjr $c17
  nop
.Lfunc_end0:
  .size foo, .Lfunc_end0-foo
  .end foo

  .type bar,@object
  .data
  .globl bar
  .p2align 4
bar:
  .4byte 42
  .size bar, 4


.p2align 6
  .type baz,@object
  .global baz
baz:
  .space 32
.size baz, 32


