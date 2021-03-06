// REQUIRES: x86-registered-target
// REQUIRES: nvptx-registered-target

// Make sure we handle target overloads correctly.  Most of this is checked in
// sema, but special functions like constructors and destructors are here.
//
// RUN: %clang_cc1 -triple x86_64-unknown-linux-gnu \
// RUN:     -fcuda-target-overloads -emit-llvm -o - %s \
// RUN:     | FileCheck -check-prefix=CHECK-BOTH -check-prefix=CHECK-HOST %s
// RUN: %clang_cc1 -triple nvptx64-nvidia-cuda -fcuda-is-device \
// RUN:     -fcuda-target-overloads -emit-llvm -o - %s \
// RUN:     | FileCheck -check-prefix=CHECK-BOTH -check-prefix=CHECK-DEVICE \
// RUN:       -check-prefix=CHECK-DEVICE-STRICT %s

// Check target overloads handling with disabled call target checks.
// RUN: %clang_cc1 -DNOCHECKS -triple x86_64-unknown-linux-gnu -emit-llvm \
// RUN:    -fcuda-disable-target-call-checks -fcuda-target-overloads -o - %s \
// RUN:     | FileCheck -check-prefix=CHECK-BOTH -check-prefix=CHECK-HOST \
// RUN:    -check-prefix=CHECK-BOTH-NC -check-prefix=CHECK-HOST-NC %s
// RUN: %clang_cc1 -DNOCHECKS -triple nvptx64-nvidia-cuda -emit-llvm \
// RUN:    -fcuda-disable-target-call-checks -fcuda-target-overloads \
// RUN:    -fcuda-is-device -o - %s \
// RUN:     | FileCheck -check-prefix=CHECK-BOTH -check-prefix=CHECK-DEVICE \
// RUN:    -check-prefix=CHECK-BOTH-NC -check-prefix=CHECK-DEVICE-NC %s

#include "Inputs/cuda.h"

// Check constructors/destructors for D/H functions
int x;
struct s_cd_dh {
  __host__ s_cd_dh() { x = 11; }
  __device__ s_cd_dh() { x = 12; }
  __host__ ~s_cd_dh() { x = 21; }
  __device__ ~s_cd_dh() { x = 22; }
};

struct s_cd_hd {
  __host__ __device__ s_cd_hd() { x = 31; }
  __host__ __device__ ~s_cd_hd() { x = 32; }
};

// CHECK-BOTH: define void @_Z7wrapperv
#if defined(__CUDA_ARCH__)
__device__
#else
__host__
#endif
void wrapper() {
  s_cd_dh scddh;
  // CHECK-BOTH: call void @_ZN7s_cd_dhC1Ev(
  s_cd_hd scdhd;
  // CHECK-BOTH: call void @_ZN7s_cd_hdC1Ev

  // CHECK-BOTH: call void @_ZN7s_cd_hdD1Ev(
  // CHECK-BOTH: call void @_ZN7s_cd_dhD1Ev(
}
// CHECK-BOTH: ret void

// Now it's time to check what's been generated for the methods we used.

// CHECK-BOTH: define linkonce_odr void @_ZN7s_cd_dhC2Ev(
// CHECK-HOST:   store i32 11,
// CHECK-DEVICE: store i32 12,
// CHECK-BOTH: ret void

// CHECK-BOTH: define linkonce_odr void @_ZN7s_cd_hdC2Ev(
// CHECK-BOTH:   store i32 31,
// CHECK-BOTH: ret void

// CHECK-BOTH: define linkonce_odr void @_ZN7s_cd_hdD2Ev(
// CHECK-BOTH: store i32 32,
// CHECK-BOTH: ret void

// CHECK-BOTH: define linkonce_odr void @_ZN7s_cd_dhD2Ev(
// CHECK-HOST:   store i32 21,
// CHECK-DEVICE: store i32 22,
// CHECK-BOTH: ret void
