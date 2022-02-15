/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class to manage all of the Metal objects this app creates.
*/

#import "MetalAdder.h"

// The number of floats in each array, and the size of the arrays in bytes.
const unsigned int arrayLength = 1e5;
const unsigned int bufferSize = arrayLength * sizeof(float);

@implementation MetalAdder
{
    id<MTLDevice> _mDevice;

    // The compute pipeline generated from the compute kernel in the .metal shader file.
    id<MTLComputePipelineState> _mAddFunctionPSO;

    // The command queue used to pass commands to the device.
    id<MTLCommandQueue> _mCommandQueue;

    // Buffers to hold data.
    id<MTLBuffer> _mBufferA;
    id<MTLBuffer> _mBufferB;
    id<MTLBuffer> _mBufferResult;
    
    // timer
    double _intervalUS;
    
}

// Inits device (GPU), PSO (executable shader) and CommandQueue (to send commands to device)
- (instancetype) initWithDevice: (id<MTLDevice>) device
{
    self = [super init];
    if (self)
    {
        mach_timebase_info_data_t info;
        mach_timebase_info(&info);
        _intervalUS = (double)info.numer * 1e-3 / (double)info.denom;
        
        _mDevice = device;

        NSError* error = nil;

        // Load the shader files with a .metal file extension in the project
        uint64_t t1 = mach_continuous_time();
        id<MTLLibrary> defaultLibrary = [_mDevice newDefaultLibrary];
        if (defaultLibrary == nil)
        {
            NSLog(@"Failed to find the default library.");
            return nil;
        }
        uint64_t t2 = mach_continuous_time();
        
        // search the shader named "add_arrays" at runtime (instead of compile time)
        // if no search result, return nil at runtime
        // addFunction is a proxy to "add_arrays" shader, but not the executable code
        id<MTLFunction> addFunction = [defaultLibrary newFunctionWithName:@"add_arrays"];
        if (addFunction == nil)
        {
            NSLog(@"Failed to find the adder function.");
            return nil;
        }
        uint64_t t3 = mach_continuous_time();

        // Create a compute (because we use a compute shader) pipeline state object (PSO)
        // PSO is used to convert addFunction (proxy) to add_arrays (executable) by
        // synchronously compiling add_arrays on the given device (GPU)
        // One PSO corresponds to one MTLFunction
        _mAddFunctionPSO = [_mDevice newComputePipelineStateWithFunction: addFunction error:&error];
        if (_mAddFunctionPSO == nil)
        {
            //  If the Metal API validation is enabled, you can find out more information about what
            //  went wrong.  (enabled by default when a debug build is run from Xcode)
            NSLog(@"Failed to created pipeline state object, error %@.", error);
            return nil;
        }
        
        uint64_t t4 = mach_continuous_time();
        
        // CommandQueue is used to send command to device
        _mCommandQueue = [_mDevice newCommandQueue];
        if (_mCommandQueue == nil)
        {
            NSLog(@"Failed to find the command queue.");
            return nil;
        }
        uint64_t t5 = mach_continuous_time();
        NSLog(@"debug 3: %.2f, %.2f, %.2f, %.2f us", (t2 - t1) * _intervalUS
              , (t3 - t2) * _intervalUS, (t4 - t3) * _intervalUS, (t5 - t4) * _intervalUS);
    }

    return self;
}

- (void) prepareData
{
    // Allocate three buffers to hold our initial data and the result.
    // MTLResourceStorageModeShared specifies the mode (that both CPU and GPU can access)
    uint64_t t1 = mach_continuous_time();
    _mBufferA = [_mDevice newBufferWithLength:bufferSize options:MTLResourceStorageModeShared];
    uint64_t t2 = mach_continuous_time();
    _mBufferB = [_mDevice newBufferWithLength:bufferSize options:MTLResourceStorageModeShared];
    uint64_t t3 = mach_continuous_time();
    _mBufferResult = [_mDevice newBufferWithLength:bufferSize options:MTLResourceStorageModeShared];
    uint64_t t4 = mach_continuous_time();
    
    // access (write to) allocated MTLBuffers on CPU
    [self generateRandomFloatData:_mBufferA];
    uint64_t t5 = mach_continuous_time();
    [self generateRandomFloatData:_mBufferB];
    uint64_t t6 = mach_continuous_time();
    NSLog(@"debug 4: %.2f, %.2f, %.2f, %.2f, %.2f us", (t2 - t1) * _intervalUS, (t3 - t2) * _intervalUS
          , (t4 - t3) * _intervalUS, (t5 - t4) * _intervalUS, (t6 - t5) * _intervalUS);
}

- (void) sendComputeCommand
{
    uint64_t t1 = mach_continuous_time();
    // Create a command buffer to hold commands.
    id<MTLCommandBuffer> commandBuffer = [_mCommandQueue commandBuffer];
    assert(commandBuffer != nil);
    
    uint64_t t2 = mach_continuous_time();
    // A command encoder encodes command for the command buffer
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    assert(computeEncoder != nil);
    
    uint64_t t3 = mach_continuous_time();
    // command encoder specifies the compute pass by setting:
    // (1) PSO (executable function), (2) corresponding function arguments,
    // (3) thread dispatch logic
    [self encodeAddCommand:computeEncoder];
    
    uint64_t t4 = mach_continuous_time();
    // End the compute pass.
    [computeEncoder endEncoding];
    
    uint64_t t5 = mach_continuous_time();
    // Commit the commands to the queue
    [commandBuffer commit];
    
    uint64_t t6 = mach_continuous_time();

    // blocks until the commandBuffer is completed (processed all commands)
    // during this periord, GPU works asynchronously
    [commandBuffer waitUntilCompleted]; // this is the time consuming part
    
    uint64_t t7 = mach_continuous_time();

    [self verifyResults];
    uint64_t t8 = mach_continuous_time();
    NSLog(@"debug 5: %.2f, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f us", (t2 - t1) * _intervalUS,
          (t3 - t2) * _intervalUS, (t4 - t3) * _intervalUS, (t5 - t4) * _intervalUS,
          (t6 - t5) * _intervalUS, (t7 - t6) * _intervalUS, (t8 - t7) * _intervalUS);
}

- (void)encodeAddCommand:(id<MTLComputeCommandEncoder>)computeEncoder {

    // bind PSO to encoder
    [computeEncoder setComputePipelineState:_mAddFunctionPSO];
    
    // bind shared buffer to add_arrays shader parameters
    // offset specifies from which point of the MTLBuffer we want to start
    // atIndex specifies parameter index of add_arrays
    // index parameter is handled by Metal
    [computeEncoder setBuffer:_mBufferA offset:0 atIndex:0];
    [computeEncoder setBuffer:_mBufferB offset:0 atIndex:1];
    [computeEncoder setBuffer:_mBufferResult offset:0 atIndex:2];
    
    // gridSize represents how many (software) threads in total
    // is needed by the work, in this case a 1d size that equals arrayLength
    MTLSize gridSize = MTLSizeMake(arrayLength, 1, 1);

    // a threadgroup maps to both sw threads (work) and hw threads (compute resource)
    // 1. from sw perspective, it maps to a subset of the total sw threads
    // defined above and divdes sw threads into consecutive smaller pieces
    // 2. from hw perspective, it maps to a piece of GPU hw processing unit
    // that is able to run the subset sw threads contained in this threadgroup
    // in parallel and share resources (eg. cache) that are accessible among threads
    NSUInteger threadGroupSize = _mAddFunctionPSO.maxTotalThreadsPerThreadgroup;
    if (threadGroupSize > arrayLength)
    {
        threadGroupSize = arrayLength;
    }
    MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);

    // Encode the compute command.
    // dispatchThreads: specify sw work
    // threadsPerThreadgroup: specifies how to divide and map sw work to hw resources
    [computeEncoder dispatchThreads:gridSize
              threadsPerThreadgroup:threadgroupSize];
}

- (void) generateRandomFloatData: (id<MTLBuffer>) buffer
{
    float* dataPtr = buffer.contents; // the ptr to head of array

    for (unsigned long index = 0; index < arrayLength; index++)
    {
        dataPtr[index] = (float)rand()/(float)(RAND_MAX);
    }
}

// CPU code to verify the results from GPU
- (void) verifyResults
{
    float* a = _mBufferA.contents;
    float* b = _mBufferB.contents;
    float* result = _mBufferResult.contents;

    for (unsigned long index = 0; index < arrayLength; index++)
    {
        if (result[index] != (a[index] + b[index]))
        {
            printf("Compute ERROR: index=%lu result=%g vs %g=a+b\n",
                   index, result[index], a[index] + b[index]);
            assert(result[index] == (a[index] + b[index]));
        }
    }
    printf("Compute results as expected\n");
}
@end
