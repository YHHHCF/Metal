/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of the cross-platform view controller.
*/

#import "AAPLViewController.h"
#import "AAPLRenderer.h"

@implementation AAPLViewController
{
    MTKView *_view;

    AAPLRenderer *_renderer;
}

// viewDidLoad happens once before view is loaded
- (void)viewDidLoad
{
    [super viewDidLoad];

    _view = (MTKView *)self.view; // create a view
    
    // the view only updates when needed (eg. resized)
    _view.enableSetNeedsDisplay = YES;
    
    // get the GPU device
    _view.device = MTLCreateSystemDefaultDevice();
    
    // create color (red, green, blue, alpha)
    _view.clearColor = MTLClearColorMake(0.0, 0.5, 1.0, 1.0);
    
    // a delegate of the view that (1) captures view change (eg. resize)
    // (2) draw when resize happens
    _renderer = [[AAPLRenderer alloc] initWithMetalKitView:_view];

    if(!_renderer)
    {
        NSLog(@"Renderer initialization failed");
        return;
    }

    // Initialize the renderer with the view size.
    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];

    // set the view's delegate
    _view.delegate = _renderer;
}

@end
