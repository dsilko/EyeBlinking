//
//  EyeBlinkingAnalyser.h
//  EyeBlinking
//
//  Created by o.koval on 12/28/15.
//  Copyright © 2015 axondevgroup. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/videoio/cap_ios.h>

enum EyeBlinkingState
{
    EyeBlinkingStateNoFace,
    EyeBlinkingStateEyeDetected,
    EyeBlinkingStateEyeNotDetected
};

@interface EyeBlinkingAnalyser : NSObject <CvVideoCameraDelegate>

@property (assign) EyeBlinkingState state;
@property (nonatomic, copy) void (^didChangeState)(EyeBlinkingState state);

@end
