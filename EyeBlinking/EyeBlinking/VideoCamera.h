//
//  VideoCamera.h
//  EyeBlinking
//
//  Created by o.koval on 12/28/15.
//  Copyright © 2015 axondevgroup. All rights reserved.
//

#import <opencv2/videoio/cap_ios.h>

@interface VideoCamera : CvVideoCamera
@property (nonatomic, strong) CALayer *customPreviewLayer;
- (void)updateOrientation;
- (void)layoutPreviewLayer;
@end
