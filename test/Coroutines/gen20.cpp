// RUN: %clang_cc1 -triple x86_64-unknown-linux-gnu -fcoroutines -emit-llvm %s -o - -std=c++14 -O3 | FileCheck %s
#include "Inputs/generator.h"

generator<int> range(int from, int n) {
  for (int i = from; i < n; ++i)
    co_yield i;
}

// CHECK-LABEL: @main
int main() {
   int sum = 0;
   for (auto v: range(1, 20))
      sum += v;
// CHECK: ret i32 190    
   return sum;
}
