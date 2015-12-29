//
//  ViewController.m
//  EyeBlinking
//
//  Created by Denis on 16.12.15.
//  Copyright © 2015 axondevgroup. All rights reserved.
//

#import "ViewController.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Masonry/Masonry.h>
#import "VideoCamera.h"
#import "EyeBlinkingAnalyser.h"
#import <opencv2/videoio/cap_ios.h>

static const NSTimeInterval kEyeBlinkingSessionTimeInterval = 20.f;
static const NSTimeInterval kBlinkDetectedLabelTimeInterval = 1.f;

@interface ViewController () <UIAlertViewDelegate>
@property (nonatomic, strong) UIView *videoCaptureView;
@property (nonatomic, strong) VideoCamera *videoCamera;
@property (nonatomic, strong) NSTimer *sessionTimer;
@property (nonatomic, assign) NSUInteger blinksCount;
@property (nonatomic, strong) UIAlertController *alertController;
@property (nonatomic, weak) IBOutlet UILabel *blinkDetectedLabel;
@property (nonatomic, strong) NSTimer *blinkLabelTimer;
@property (nonatomic, strong) EyeBlinkingAnalyser *eyeBlinkAnalyser;
@property (nonatomic, strong) NSMutableArray *states;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.videoCaptureView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 480, 640)];
    [self.view addSubview:self.videoCaptureView];
    [self.videoCaptureView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@480);
        make.height.equalTo(@640);
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view);
    }];
    [self.view sendSubviewToBack:self.videoCaptureView];
    self.states = [NSMutableArray new];
    self.eyeBlinkAnalyser = [[EyeBlinkingAnalyser alloc] init];
    [self initCapture];
    [self resetSession];
}

- (void)appendState:(NSNumber *)state
{
    NSLog(@"state = %d", state.intValue);
    [self.states addObject:state];
    if ([self.states count] > 3)
    {
        [self.states removeObjectAtIndex:0];
        int first = [(NSNumber *)self.states[0] intValue];
        int second = [(NSNumber *)self.states[1] intValue];
        int third = [(NSNumber *)self.states[2] intValue];
        if((first == 1) && (second == 0) && (third == 1))
        {
            self.blinksCount++;
            [self showBlinkDetectedLabel];
        }
        
    }
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGFloat rotation = 0.f;
    
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait)
    {
        rotation = 0.f;
    }
    else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft)
    {
        rotation = M_PI/2;
    }
    else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        rotation = -M_PI/2;
    }
    [UIView animateWithDuration:duration animations:^{
        self.videoCaptureView.transform = CGAffineTransformMakeRotation(rotation);
        self.videoCaptureView.frame = self.view.frame;
    }];
    
}

- (void)resetSession
{
    [self.sessionTimer invalidate];
    self.blinksCount = 0;
    [self.states removeAllObjects];
    self.videoCamera.delegate = self.eyeBlinkAnalyser;
    __weak typeof(self) weakSelf = self;
    self.eyeBlinkAnalyser.didChangeState = ^(NSNumber *state)
    {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf performSelectorOnMainThread:@selector(appendState:) withObject:state waitUntilDone:NO];
    };
    [self.videoCamera start];
    self.sessionTimer = [NSTimer scheduledTimerWithTimeInterval:kEyeBlinkingSessionTimeInterval target:self selector:@selector(sessionTimerAlarm:) userInfo:nil repeats:NO];
}

- (void)showBlinkDetectedLabel
{
    self.blinkDetectedLabel.hidden = NO;
    [self.blinkLabelTimer invalidate];
    self.blinkLabelTimer = [NSTimer scheduledTimerWithTimeInterval:kBlinkDetectedLabelTimeInterval target:self selector:@selector(blinkTimerAlarm:) userInfo:nil repeats:NO];
}

- (void)initCapture
{
    self.videoCamera = [[VideoCamera alloc] initWithParentView:self.videoCaptureView];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetLow;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    [self.videoCamera adjustLayoutToInterfaceOrientation:UIInterfaceOrientationPortrait];
    self.videoCamera.defaultFPS = 30;
    [self.videoCamera start];
}

- (void)sessionTimerAlarm:(NSTimer *)timer
{
    self.eyeBlinkAnalyser.didChangeState = nil;
    self.videoCamera.delegate = nil;
    self.eyeBlinkAnalyser.state = EyeBlinkingStateNoFace;
    NSString *message = [NSString stringWithFormat:@"%lu",(unsigned long)self.blinksCount];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Eye blinks" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *restartAction = [UIAlertAction actionWithTitle:@"restart" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
        [self resetSession];
    }];
    [alertController addAction:restartAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)blinkTimerAlarm:(NSTimer *)timer
{
    self.blinkDetectedLabel.hidden = YES;
}
@end
