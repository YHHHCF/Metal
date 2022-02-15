/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An app that performs a simple calculation on a GPU.
*/

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MetalAdder.h"

// C version
void add_arrays(const float* inA,
                const float* inB,
                float* result,
                int length) {
    for (int index = 0; index < length ; ++index) {
        result[index] = inA[index] + inB[index];
    }
}

void generateRandomFloatData(float* array, int length) {
    for (unsigned long index = 0; index < length; ++index)
    {
        array[index] = (float)rand()/(float)(RAND_MAX);
    }
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        const unsigned int len = 1e5;
        uint64_t t;
        mach_timebase_info_data_t info;
        mach_timebase_info(&info);
        double intervalUS = (double)info.numer * 1e-3 / (double)info.denom;
        
        // 1. C version running on CPU
        float CPUA[len];
        float CPUB[len];
        float CPUres[len];
        generateRandomFloatData(CPUA, len);
        generateRandomFloatData(CPUB, len);
        
        t = mach_continuous_time();
        add_arrays(CPUA, CPUB, CPUres, len);
        NSLog(@"debug 1: %.2f us", (mach_continuous_time() - t) * intervalUS);
        
        // 2. Metal version running on GPU
        t = mach_continuous_time();
        // An abstract of GPU, MTLCreateSystemDefaultDevice() is time consuming
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        NSLog(@"debug 2: %.2f us", (mach_continuous_time() - t) * intervalUS);

        // adder inits, manages (and keep strong ref) objects used
        // to communicate with the GPU. The init happens once
        MetalAdder* adder = [[MetalAdder alloc] initWithDevice:device];

        // Create 3 MTLBufferss and writes to 2 of them on CPU
        [adder prepareData];
        
        // Send a command to the GPU to perform the calculation.
        [adder sendComputeCommand];

        NSLog(@"Execution finished");
    }
    return 0;
}
