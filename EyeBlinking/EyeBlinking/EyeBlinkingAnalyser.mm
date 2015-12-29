//
//  EyeBlinkingAnalyser.m
//  EyeBlinking
//
//  Created by o.koval on 12/28/15.
//  Copyright © 2015 axondevgroup. All rights reserved.
//

#import "EyeBlinkingAnalyser.h"
#import <opencv2/objdetect/objdetect.hpp>
#import <opencv2/opencv.hpp>

static const NSString *kCascadeFrontalFaceFileName = @"haarcascade_frontalface_alt2";
static const NSString *kCascadeEyeFileName = @"haarcascade_eye";

using namespace cv;

@interface EyeBlinkingAnalyser ()

@property (nonatomic, retain) dispatch_queue_t queue;
@property (assign) BOOL inProgress;
@property (assign) Mat *image;
@property (assign) CascadeClassifier *eyeCascade;
@property (assign) CascadeClassifier *faceCascade;

@end

@implementation EyeBlinkingAnalyser

- (instancetype)init
{
    self = [super init];
    if (nil != self)
    {
        self.queue = dispatch_queue_create("", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        self.eyeCascade = new CascadeClassifier();
        self.faceCascade = new CascadeClassifier();
        NSString *eyeCascadePath = [[NSBundle mainBundle] pathForResource:(NSString *)kCascadeEyeFileName ofType:@"xml"];
        self.eyeCascade->load([eyeCascadePath UTF8String]);
        NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:(NSString *)kCascadeFrontalFaceFileName ofType:@"xml"];
        self.faceCascade->load([faceCascadePath UTF8String]);
        self.state = EyeBlinkingStateNoFace;
        self.inProgress = NO;
    }
    return self;
}

- (void)dealloc
{
    delete(self.eyeCascade);
    delete(self.faceCascade);
}

- (void)processImage:(Mat&)imageOriginal
{
    if (!self.inProgress)
    {
        self.inProgress = YES;
        self.image = new Mat(imageOriginal.clone());
        dispatch_async(self.queue, ^{
            Mat tmpMat;
            UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
            BOOL isInLandScapeMode = NO;
            BOOL rotation = 1;
            
            //Rotate cv::Mat to the portrait orientation
            if(orientation == UIDeviceOrientationLandscapeRight)
            {
                isInLandScapeMode = YES;
                rotation = 1;
            }
            else if(orientation == UIDeviceOrientationLandscapeLeft)
            {
                isInLandScapeMode = YES;
                rotation = 0;
            }
            else if(orientation == UIDeviceOrientationPortraitUpsideDown)
            {
                cv::transpose(*self.image, tmpMat);
                cv::flip(tmpMat, *self.image, rotation);
                cv::transpose(*self.image, tmpMat);
                cv::flip(tmpMat, *self.image, rotation);
                cvtColor(*self.image, *self.image, CV_BGR2BGRA);
                cvtColor(*self.image, *self.image, CV_BGR2RGB);
            }
            
            if(isInLandScapeMode)
            {
                cv::transpose(*self.image, tmpMat);
                cv::flip(tmpMat, *self.image, rotation);
                cvtColor(*self.image, *self.image, CV_BGR2BGRA);
                cvtColor(*self.image, *self.image, CV_BGR2RGB);
            }
            
            std::vector<cv::Rect> faces;
            Mat frame_gray;
            
            cvtColor(*self.image, frame_gray, CV_BGRA2GRAY);
            equalizeHist(frame_gray, frame_gray);
            if(self.state == EyeBlinkingStateNoFace)
            {
                std::vector<cv::Rect> faces;
                self.faceCascade->detectMultiScale(frame_gray, faces, 1.1, 2, 0 | CV_HAAR_SCALE_IMAGE, cv::Size(50, 50), cv::Size(150, 150));
                if (faces.size() > 0)
                {
                    std::vector<cv::Rect> eyes;
                    self.eyeCascade->detectMultiScale(frame_gray, eyes, 1.1, 2, 0 | CV_HAAR_SCALE_IMAGE, cv::Size(10, 10), cv::Size(50, 50));
                    if (eyes.size() > 0)
                    {
                        self.state = EyeBlinkingStateEyeDetected;
                        if (self.didChangeState)
                        {
                            self.didChangeState(@1);
                        }
                    }
                    else
                    {
                        self.state = EyeBlinkingStateEyeNotDetected;
                        if (self.didChangeState)
                        {
                            self.didChangeState(@0);
                        }
                    }
                }
            }
            
            else if (self.state == EyeBlinkingStateEyeNotDetected)
            {
                std::vector<cv::Rect> eyes;
                self.eyeCascade->detectMultiScale(frame_gray, eyes, 1.1, 2, 0 | CV_HAAR_SCALE_IMAGE, cv::Size(10, 10), cv::Size(50, 50));
                if (eyes.size() > 0)
                {
                    self.state = EyeBlinkingStateEyeDetected;
                    if (self.didChangeState)
                    {
                        self.didChangeState(@1);
                    }
                }
                else
                {
                    std::vector<cv::Rect> faces;
                    self.faceCascade->detectMultiScale(frame_gray, faces, 1.1, 2, 0 | CV_HAAR_SCALE_IMAGE, cv::Size(50, 50), cv::Size(150, 150));
                    if (faces.size() == 0)
                    {
                        self.state = EyeBlinkingStateNoFace;
                        if (self.didChangeState)
                        {
                            self.didChangeState(@-1);
                        }
                    }
                }
            }
            
            else if (self.state == EyeBlinkingStateEyeDetected)
            {
                std::vector<cv::Rect> eyes;
                self.eyeCascade->detectMultiScale(frame_gray, eyes, 1.1, 2, 0 | CV_HAAR_SCALE_IMAGE, cv::Size(10, 10), cv::Size(50, 50));
                if (eyes.size() == 0)
                {
                    self.state = EyeBlinkingStateEyeNotDetected;
                    if (self.didChangeState)
                    {
                        self.didChangeState(@0);
                    }
                }
            }
            delete (self.image);
            self.inProgress = NO;
        });
    }
}

@end
