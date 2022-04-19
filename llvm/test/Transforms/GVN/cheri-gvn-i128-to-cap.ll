; This used to crash: https://github.com/CTSRD-CHERI/llvm-project/issues/286
; RUN: opt -S -passes=gvn %s -o - | FileCheck %s
target datalayout = "E-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-n32:64-S128"
target triple = "riscv64-unknown-freebsd"

; Generated from this C++ source code (reduced testcase for libc++)
; template <class T> class j {
;  T aj;
;public:
;  template <class c> j(c k) : aj(k) {}
;};
;template <class d, class c>
;void operator-(j<d>, j<c> &);
;
;void e(long k) {
;  j<__int128> a(k), b(a);
;  j<__int128>(0) - b;
;}

%class.j = type { i128 }

; Function Attrs: argmemonly nounwind
declare void @llvm.lifetime.start.p0i8(i64, i8* nocapture) #1
declare void @llvm.lifetime.end.p0i8(i64, i8* nocapture) #1
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* nocapture writeonly, i8* nocapture readonly, i64, i1) #1

declare void @_ZmiInnEv1jIT_ERS0_IT0_E(i64 inreg, i64 inreg, %class.j* dereferenceable(16)) #2

define void @_Z1el(i64 signext %k) local_unnamed_addr #0 {
; CHECK-LABEL: @_Z1el(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[A_SROA_0:%.*]] = alloca i8 addrspace(200)*, align 16
; CHECK-NEXT:    [[TMPCAST7:%.*]] = bitcast i8 addrspace(200)** [[A_SROA_0]] to i128*
; CHECK-NEXT:    [[B:%.*]] = alloca i8 addrspace(200)*, align 16
; CHECK-NEXT:    [[TMPCAST:%.*]] = bitcast i8 addrspace(200)** [[B]] to %class.j*
; CHECK-NEXT:    [[A_SROA_0_0__SROA_CAST6:%.*]] = bitcast i8 addrspace(200)** [[A_SROA_0]] to i8*
; CHECK-NEXT:    call void @llvm.lifetime.start.p0i8(i64 16, i8* nonnull [[A_SROA_0_0__SROA_CAST6]])
; CHECK-NEXT:    [[CONV_I_I:%.*]] = sext i64 [[K:%.*]] to i128
; CHECK-NEXT:    store i128 [[CONV_I_I]], i128* [[TMPCAST7]], align 16
; CHECK-NEXT:    [[TMP0:%.*]] = bitcast i8 addrspace(200)** [[B]] to i8*
; CHECK-NEXT:    call void @llvm.lifetime.start.p0i8(i64 16, i8* nonnull [[TMP0]])
; CHECK-NEXT:    [[A_SROA_0_0_A_SROA_0_0_:%.*]] = load i8 addrspace(200)*, i8 addrspace(200)** [[A_SROA_0]], align 16
; CHECK-NEXT:    store i8 addrspace(200)* [[A_SROA_0_0_A_SROA_0_0_]], i8 addrspace(200)** [[B]], align 16
; CHECK-NEXT:    call void @_ZmiInnEv1jIT_ERS0_IT0_E(i64 inreg 0, i64 inreg 0, %class.j* nonnull dereferenceable(16) [[TMPCAST]])
; CHECK-NEXT:    call void @llvm.lifetime.end.p0i8(i64 16, i8* nonnull [[TMP0]])
; CHECK-NEXT:    call void @llvm.lifetime.end.p0i8(i64 16, i8* nonnull [[A_SROA_0_0__SROA_CAST6]])
; CHECK-NEXT:    ret void
entry:
  %a.sroa.0 = alloca i8 addrspace(200)*, align 16
  %tmpcast7 = bitcast i8 addrspace(200)** %a.sroa.0 to i128*
  %b = alloca i8 addrspace(200)*, align 16
  %tmpcast = bitcast i8 addrspace(200)** %b to %class.j*
  %a.sroa.0.0..sroa_cast6 = bitcast i8 addrspace(200)** %a.sroa.0 to i8*
  call void @llvm.lifetime.start.p0i8(i64 16, i8* nonnull %a.sroa.0.0..sroa_cast6)
  %conv.i.i = sext i64 %k to i128
  store i128 %conv.i.i, i128* %tmpcast7, align 16
  %0 = bitcast i8 addrspace(200)** %b to i8*
  call void @llvm.lifetime.start.p0i8(i64 16, i8* nonnull %0) #5
  %a.sroa.0.0.a.sroa.0.0. = load i8 addrspace(200)*, i8 addrspace(200)** %a.sroa.0, align 16
  store i8 addrspace(200)* %a.sroa.0.0.a.sroa.0.0., i8 addrspace(200)** %b, align 16
  call void @_ZmiInnEv1jIT_ERS0_IT0_E(i64 inreg 0, i64 inreg 0, %class.j* nonnull dereferenceable(16) %tmpcast)
  call void @llvm.lifetime.end.p0i8(i64 16, i8* nonnull %0) #5
  call void @llvm.lifetime.end.p0i8(i64 16, i8* nonnull %a.sroa.0.0..sroa_cast6)
  ret void
}

attributes #0 = { nounwind }
attributes #1 = { argmemonly nounwind }
attributes #2 = { nounwind }
