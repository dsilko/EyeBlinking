//
//  VideoCamera.m
//  EyeBlinking
//
//  Created by o.koval on 12/28/15.
//  Copyright © 2015 axondevgroup. All rights reserved.
//

#import "VideoCamera.h"

@implementation VideoCamera

@synthesize customPreviewLayer = _customPreviewLayer;

- (void)updateOrientation
{
    // nop
}

- (void)layoutPreviewLayer
{
    if (self.parentView != nil) {
        CALayer* layer = self.customPreviewLayer;
        CGRect bounds = self.customPreviewLayer.bounds;
        layer.position = CGPointMake(self.parentView.frame.size.width/2., self.parentView.frame.size.height/2.);
        layer.bounds = bounds;
    }
}
@end
