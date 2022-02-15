/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A shader that adds two arrays of floats.
*/

#include <metal_stdlib>
using namespace metal;
// kernel keyword indicates this is a public GPU function, which means
// app can see but other shader functions cannot see
kernel void add_arrays(device const float* inA, // device addr space GPU can acess
                       device const float* inB,
                       device float* result,
                       uint index [[thread_position_in_grid]])
{
    result[index] = inA[index] + inB[index];
}
