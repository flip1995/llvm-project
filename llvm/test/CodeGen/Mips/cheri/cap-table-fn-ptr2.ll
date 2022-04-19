; RUN: %cheri_purecap_llc -cheri-cap-table-abi=plt %s -mxcaptable=true  -o - | %cheri_FileCheck %s -check-prefixes CHECK,BIGTABLE
; RUN: %cheri_purecap_llc -cheri-cap-table-abi=plt %s -mxcaptable=false -o - | %cheri_FileCheck %s -check-prefixes CHECK,SMALLTABLE

; ModuleID = '/Users/alex/cheri/llvm/tools/clang/test/CodeGen/CHERI/cap-table-call-extern.c'
source_filename = "/Users/alex/cheri/llvm/tools/clang/test/CodeGen/CHERI/cap-table-call-extern.c"

declare void @extern_func() addrspace(200) #0

@fn = local_unnamed_addr addrspace(200) global void () addrspace(200)* @extern_func, align 32
@fn2 = internal unnamed_addr addrspace(200) global void () addrspace(200)* @extern_func, align 32

; Function Attrs: nounwind
define void @test(void () addrspace(200)* %arg) local_unnamed_addr addrspace(200) #1 {
entry:
  %0 = load void () addrspace(200)*, void () addrspace(200)* addrspace(200)* @fn, align 32
  ; load address of fn:
  ; BIGTABLE:      lui	$1, %captab_hi(fn)
  ; BIGTABLE-NEXT: daddiu	$1, $1, %captab_lo(fn)
  ; BIGTABLE-NEXT: clc	$c1, $1, 0($c18)
  ; SMALLTABLE: clcbi $c1, %captab20(fn)($c18)
  store void () addrspace(200)* %arg, void () addrspace(200)* addrspace(200)* @fn2, align 32
  ; load address of fn2:
  ; BIGTABLE-NEXT: lui	$1, %captab_hi(fn2)
  ; BIGTABLE-NEXT: daddiu	$1, $1, %captab_lo(fn2)
  ; BIGTABLE-NEXT: clc	$c2, $1, 0($c18)
  ; SMALLTABLE-NEXT: clcbi $c2, %captab20(fn2)($c18)
  ; load fn for call:
  ; CHECK-NEXT: clc	$c12, $zero, 0($c1)
  ; call fn:
  ; CHECK-NEXT: cjalr	$c12, $c17
  ; save %arg to fn2 (delay slot)
  ; CHECK-NEXT: csc	$c3, $zero, 0($c2)
  tail call void %0() #2
  ret void
}


; CHECK:        .type	fn,@object              # @fn
; CHECK-NEXT: 	.data
; CHECK-NEXT: 	.globl	fn
; CHECK-NEXT: 	.p2align	{{5|4}}
; CHECK-NEXT: fn:
; CHECK-NEXT: 	.chericap	extern_func
; CHECK-NEXT: 	.size	fn, [[#CAP_SIZE]]

; CHECK:      	.type	fn2,@object             # @fn2
; CHECK-NEXT: 	.p2align	{{5|4}}
; CHECK-NEXT: fn2:
; CHECK-NEXT: 	.chericap	extern_func
; CHECK-NEXT: 	.size	fn2, [[#CAP_SIZE]]

attributes #0 = { nounwind }
attributes #1 = { nounwind }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"PIC Level", i32 1}
!2 = !{!"clang version 6.0.0 (https://github.com/llvm-mirror/clang.git c5f3638ca2170161f8769db4a5886c2a206dba1b) (https://github.com/llvm-mirror/llvm.git 28c5d377cdc9e35a9dc5e9e435c8974159c122b6)"}
!3 = !{!4, !4, i64 0}
!4 = !{!"any pointer", !5, i64 0}
!5 = !{!"omnipotent char", !6, i64 0}
!6 = !{!"Simple C/C++ TBAA"}
