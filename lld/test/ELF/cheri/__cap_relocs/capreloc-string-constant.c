// REQUIRES: clang

// RUN: %cheri256_purecap_cc1 %s -emit-obj -o %t.o
// RUN: llvm-readobj -r %t.o | FileCheck -check-prefix READOBJ %s

// RUN: ld.lld -preemptible-caprelocs=legacy %t.o -static -o %t-static.exe 2>&1 | FileCheck -check-prefixes UNKNOWN_LENGTH %s
// RUN: llvm-readobj --cap-relocs -s %t-static.exe | FileCheck -check-prefixes STATIC %s

// same again for statically dynamically linked exe:
// RUN: %cheri_purecap_clang %S/Inputs/dummy_shlib.c -c -o %T/integrated_dummy_shlib.o
// RUN: ld.lld -preemptible-caprelocs=legacy -pie -Bdynamic %t.o -o %t-dynamic.exe
// RUN: llvm-readobj -r -s --cap-relocs  %t-dynamic.exe | FileCheck -check-prefixes DYNAMIC %s

// Look at shared libraries:
// RUN: ld.lld -preemptible-caprelocs=legacy %t.o -shared -o %t.so
// RUN: llvm-readobj -r -s --cap-relocs %t.so | FileCheck -check-prefixes DYNAMIC-RELOCS %s


// FIXME: it would be good if we could set bounds here instead of having it as -1


struct option {
    int id;
    const char* name;
};

struct option options_table[] = {
        { 1, "first" },
        { 2, "second" + 4 },
        { 3, "duplicate" },
        { 4, "duplicate" },
        { 5, "duplicate" + 1 },


};

// READOBJ:      Relocations [
// READOBJ-NEXT:   Section (6) .rela.data {
// READOBJ-NEXT:     R_MIPS_CHERI_CAPABILITY/R_MIPS_NONE/R_MIPS_NONE .L.str 0x0
// READOBJ-NEXT:     R_MIPS_CHERI_CAPABILITY/R_MIPS_NONE/R_MIPS_NONE .L.str.1 0x4
// READOBJ-NEXT:     R_MIPS_CHERI_CAPABILITY/R_MIPS_NONE/R_MIPS_NONE .L.str.2 0x0
// READOBJ-NEXT:     R_MIPS_CHERI_CAPABILITY/R_MIPS_NONE/R_MIPS_NONE .L.str.2 0x0
// READOBJ-NEXT:     R_MIPS_CHERI_CAPABILITY/R_MIPS_NONE/R_MIPS_NONE .L.str.2 0x1
// READOBJ-NEXT:   }
// READOBJ-NEXT: ]

// UNKNOWN_LENGTH: warning: cannot find entry symbol __start
// UNKNOWN_LENGTH-NOT: warning


// dynamic should have 10 relocations against the load address
// DYNAMIC-RELOCS-LABEL: Relocations [
// DYNAMIC-RELOCS-NEXT:   Section ({{.+}}) .rel.dyn {
// DYNAMIC-RELOCS-NEXT:     0x20000 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE - 0x0 (real addend unknown)
// DYNAMIC-RELOCS-NEXT:     0x20008 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE - 0x0 (real addend unknown)
// DYNAMIC-RELOCS-NEXT:     0x20028 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE - 0x0 (real addend unknown)
// DYNAMIC-RELOCS-NEXT:     0x20030 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE - 0x0 (real addend unknown)
// DYNAMIC-RELOCS-NEXT:     0x20050 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE - 0x0 (real addend unknown)
// DYNAMIC-RELOCS-NEXT:     0x20058 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE - 0x0 (real addend unknown)
// DYNAMIC-RELOCS-NEXT:     0x20078 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE - 0x0 (real addend unknown)
// DYNAMIC-RELOCS-NEXT:     0x20080 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE - 0x0 (real addend unknown)
// DYNAMIC-RELOCS-NEXT:     0x200A0 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE - 0x0 (real addend unknown)
// DYNAMIC-RELOCS-NEXT:     0x200A8 R_MIPS_REL32/R_MIPS_64/R_MIPS_NONE - 0x0 (real addend unknown)
// DYNAMIC-RELOCS-NEXT:   }
// DYNAMIC-RELOCS-NEXT: ]

// STATIC: Section {
// STATIC: Name: .rodata (
// STATIC-NEXT: Type: SHT_PROGBITS (0x1)
// STATIC-NEXT: Flags [ (0x32)
// STATIC-NEXT:   SHF_ALLOC (0x2)
// STATIC-NEXT:   SHF_MERGE (0x10)
// STATIC-NEXT:   SHF_STRINGS (0x20)
// STATIC-NEXT: ]
// STATIC-NEXT: Address: [[$RODATA:0x120000198]]

// STATIC-LABEL: CHERI __cap_relocs [
// STATIC-NEXT:    0x120010020 Base: 0x[[@EXPR tolower(hex($RODATA))]]      (<unknown symbol>+0) Length: 6 Perms: Object
// STATIC-NEXT:    0x120010060 Base: 0x[[@EXPR tolower(hex($RODATA + 16))]] (<unknown symbol>+4) Length: 7 Perms: Object
// STATIC-NEXT:    0x1200100a0 Base: 0x[[@EXPR tolower(hex($RODATA + 6))]]  (<unknown symbol>+0) Length: 10 Perms: Object
// STATIC-NEXT:    0x1200100e0 Base: 0x[[@EXPR tolower(hex($RODATA + 6))]]  (<unknown symbol>+0) Length: 10 Perms: Object
// STATIC-NEXT:    0x120010120 Base: 0x[[@EXPR tolower(hex($RODATA + 6))]]  (<unknown symbol>+1) Length: 10 Perms: Object
// STATIC-NEXT: ]



// DYNAMIC: Section {
// DYNAMIC:      Name: .rodata (
// DYNAMIC-NEXT: Type: SHT_PROGBITS (0x1)
// DYNAMIC-NEXT: Flags [ (0x32)
// DYNAMIC-NEXT:   SHF_ALLOC (0x2)
// DYNAMIC-NEXT:   SHF_MERGE (0x10)
// DYNAMIC-NEXT:   SHF_STRINGS (0x20)
// DYNAMIC-NEXT: ]
// DYNAMIC-NEXT: Address: [[$RODATA:0x428]]

// PIE exe amd shlib should have a dynamic relocations and only have the offset+length values filled in:
// DYNAMIC-LABEL: CHERI __cap_relocs [
// DYNAMIC-NEXT:    0x010020 Base: 0x[[@EXPR tolower(hex($RODATA))]]      (<unknown symbol>+0) Length: 6 Perms: Object
// DYNAMIC-NEXT:    0x010060 Base: 0x[[@EXPR tolower(hex($RODATA + 16))]] (<unknown symbol>+4) Length: 7 Perms: Object
// DYNAMIC-NEXT:    0x0100a0 Base: 0x[[@EXPR tolower(hex($RODATA + 6))]]  (<unknown symbol>+0) Length: 10 Perms: Object
// DYNAMIC-NEXT:    0x0100e0 Base: 0x[[@EXPR tolower(hex($RODATA + 6))]]  (<unknown symbol>+0) Length: 10 Perms: Object
// DYNAMIC-NEXT:    0x010120 Base: 0x[[@EXPR tolower(hex($RODATA + 6))]]  (<unknown symbol>+1) Length: 10 Perms: Object
// DYNAMIC-NEXT: ]



