/// Check that we use the lib64 directory if it is available
// RUN: %cheri_clang -no-canonical-prefixes \
// RUN:   %s --sysroot=%S/Inputs/basic_cheribsd_libcompat_tree -### 2>&1 \
// RUN:   | FileCheck --check-prefixes=CHECK-CHERI-HYBRID,CHECK-CHERI-HYBRID64 %s
// RUN: %riscv32_cheri_clang -no-canonical-prefixes \
// RUN:   %s --sysroot=%S/Inputs/basic_cheribsd_libcompat_tree -### 2>&1 \
// RUN:   | FileCheck --check-prefixes=CHECK-CHERI-HYBRID,CHECK-CHERI-HYBRID32 %s
// RUN: %riscv64_cheri_clang -no-canonical-prefixes \
// RUN:   %s --sysroot=%S/Inputs/basic_cheribsd_libcompat_tree -### 2>&1 \
// RUN:   | FileCheck --check-prefixes=CHECK-CHERI-HYBRID,CHECK-CHERI-HYBRID64 %s
// CHECK-CHERI-HYBRID: ld{{.*}}" "--sysroot=[[SYSROOT:[^"]+]]"
// TODO: should probably set /libexec/ld-elf64.so.1
// CHECK-CHERI-HYBRID: "-dynamic-linker" "/libexec/ld-elf.so.1"
// CHECK-CHERI-HYBRID64: "[[SYSROOT]]/usr/lib64/crt1.o"
// CHECK-CHERI-HYBRID32: "[[SYSROOT]]/usr/lib32/crt1.o"
// CHECK-CHERI-HYBRID: "crti.o" "crtbegin.o"
// CHECK-CHERI-HYBRID64: "-L[[SYSROOT]]/usr/lib64"
// CHECK-CHERI-HYBRID32: "-L[[SYSROOT]]/usr/lib32"
// CHECK-CHERI-HYBRID: "crtend.o"
// CHECK-CHERI-HYBRID: "crtn.o"

/// Purecap should never look at lib64:
// RUN: %cheri_purecap_clang -no-canonical-prefixes -no-pie \
// RUN:   %s --sysroot=%S/Inputs/basic_cheribsd_libcompat_tree -### 2>&1 \
// RUN:   | FileCheck --check-prefixes=CHECK-CHERI-PURECAP %s
// RUN: %riscv32_cheri_purecap_clang -no-canonical-prefixes -no-pie \
// RUN:   %s --sysroot=%S/Inputs/basic_cheribsd_libcompat_tree -### 2>&1 \
// RUN:   | FileCheck --check-prefixes=CHECK-CHERI-PURECAP %s
// RUN: %riscv64_cheri_purecap_clang -no-canonical-prefixes -no-pie \
// RUN:   %s --sysroot=%S/Inputs/basic_cheribsd_libcompat_tree -### 2>&1 \
// RUN:   | FileCheck --check-prefixes=CHECK-CHERI-PURECAP %s
// PURECAP-MIPS128: "-cc1" "-triple" "mips64c{{128|256}}-unknown-freebsd-purecap"
// PURECAP-MIPS128: "-target-abi" "purecap"
// PURECAP-RISCV32: "-cc1" "-triple" "riscv32-unknown-freebsd"
// PURECAP-RISCV32: "-target-abi" "il32pc64"
// PURECAP-RISCV64: "-cc1" "-triple" "riscv64-unknown-freebsd"
// PURECAP-RISCV64: "-target-abi" "l64pc128"
// CHECK-CHERI-PURECAP: ld{{.*}}" "--sysroot=[[SYSROOT:[^"]+]]"
// CHECK-CHERI-PURECAP: "-dynamic-linker" "/libexec/ld-elf.so.1"
// CHECK-CHERI-PURECAP: "crt1.o" "crtbegin.o"
// CHECK-CHERI-PURECAP-NOT: "crti.o"
// CHECK-CHERI-PURECAP: "-L[[SYSROOT]]/usr/lib"
// CHECK-CHERI-PURECAP: "crtend.o"
// CHECK-CHERI-PURECAP-NOT: "crtn.o"

// RUN: %cheri_clang --target=mips64-unknown-freebsd -no-canonical-prefixes %s -fsanitize=fuzzer \
// RUN:   --sysroot=%S/Inputs/basic_cheribsd_libcompat_tree -### 2>&1 | FileCheck --check-prefix=CHECK-FUZZER-MIPS64 %s
// RUN: %riscv64_cheri_clang -no-canonical-prefixes %s -fsanitize=fuzzer \
// RUN:   --sysroot=%S/Inputs/basic_cheribsd_libcompat_tree -### 2>&1 | FileCheck --check-prefix=CHECK-FUZZER-RISCV64 %s

// CHECK-FUZZER-MIPS64: "--whole-archive" "{{.+}}/lib/freebsd/libclang_rt.fuzzer-mips64.a" "--no-whole-archive"
// CHECK-FUZZER-MIPS64: "--whole-archive" "{{.+}}/lib/freebsd/libclang_rt.ubsan_standalone-mips64.a" "--no-whole-archive"

// CHECK-FUZZER-RISCV64: error: unsupported option '-fsanitize=fuzzer' for target 'riscv64-unknown-freebsd'
// TODO-CHECK-FUZZER-RISCV64: "--whole-archive" "{{.+}}/lib/freebsd/libclang_rt.fuzzer-riscv64.a" "--no-whole-archive"
// TODO-CHECK-FUZZER-RISCV64: "--whole-archive" "{{.+}}/lib/freebsd/libclang_rt.ubsan_standalone-riscv64.a" "--no-whole-archive"
