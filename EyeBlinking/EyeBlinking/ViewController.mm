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
using namespace cv;

static const NSTimeInterval kEyeBlinkingSessionTimeInterval = 10.f;
static const NSTimeInterval kBlinkDetectedLabelTimeInterval = 1.f;

@interface ViewController () <CvVideoCameraDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) UIView *videoCaptureView;
@property (nonatomic, strong) VideoCamera *videoCamera;
@property (nonatomic, strong) NSTimer *sessionTimer;
@property (nonatomic, assign) NSUInteger blinksCount;
@property (nonatomic, strong) UIAlertController *alertController;
@property (nonatomic, weak) IBOutlet UILabel *blinkDetectedLabel;
@property (nonatomic, strong) NSTimer *blinkLabelTimer;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.videoCaptureView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.videoCaptureView];
    [self.videoCaptureView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.leading.equalTo(self.view);
        make.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    self.videoCaptureView.backgroundColor = [UIColor blueColor];
    [self.view sendSubviewToBack:self.videoCaptureView];
    [self initCapture];
    [self resetSession];
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    float rotation;
    
    if (toInterfaceOrientation==UIInterfaceOrientationPortrait) {
        rotation = 0;
    } else
        if (toInterfaceOrientation==UIInterfaceOrientationLandscapeLeft) {
            rotation = M_PI/2;
        } else
            if (toInterfaceOrientation==UIInterfaceOrientationLandscapeRight) {
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
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    [self.videoCamera adjustLayoutToInterfaceOrientation:UIInterfaceOrientationPortrait];
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.delegate = self;
    [self.videoCamera start];
}

- (void)processImage:(cv::Mat&)image
{
    
}


- (void)sessionTimerAlarm:(NSTimer *)timer
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Eye blinks" message:@"0" preferredStyle:UIAlertControllerStyleAlert];
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
