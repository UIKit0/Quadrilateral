//
//  ViewController.m
//  Quadrilateral
//
//  Created by Zakk Hoyt on 7/11/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//
// See http://stackoverflow.com/questions/13269432/perspective-transform-crop-in-ios-with-opencv
// One more to try: http://stackoverflow.com/questions/13523837/find-corner-of-papers/13532779#13532779



#import "ViewController.h"
#import "PointView.h"

#include <opencv2/opencv.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <iostream>

// Not sure if Pnt/Quadrilateral are defined somewehere in OpenCV... I made my own to meet the signatures
struct Pnt{
    float x;
    float y;
};


struct Quadrilateral{
    Pnt topLeft;
    Pnt topRight;
    Pnt bottomLeft;
    Pnt bottomRight;
};



@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>{
    CGFloat startX;
    CGFloat startY;
}


@property (strong, nonatomic) UIImageView *imageView;
@property (weak, nonatomic) IBOutlet PointView *topLeftView;
@property (weak, nonatomic) IBOutlet PointView *topRightView;
@property (weak, nonatomic) IBOutlet PointView *bottomRightView;
@property (weak, nonatomic) IBOutlet PointView *bottomLeftView;
@property (nonatomic) CGRect original;

@property (weak, nonatomic) IBOutlet UIButton *distortButton;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@end

@implementation ViewController

#pragma mark UIViewController
            
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupImage:nil];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.original = self.imageView.layer.frame;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Private methods
-(void)setupImage:(UIImage*)image{
    // Cleanup
    if(self.imageView){
        [self.imageView removeGestureRecognizer:self.panGesture];
        [self.imageView removeFromSuperview];
    }
    
    // Default image
    if(image == nil){
        image = [UIImage imageNamed:@"skew"];
    }
    self.imageView = [[UIImageView alloc]initWithImage:image];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.frame = self.view.bounds;
    self.imageView.backgroundColor = [UIColor greenColor];
    

    [self.view addSubview:self.imageView];

    // We just covered everything. Bring them to the front.
    [self.view bringSubviewToFront:self.topLeftView];
    [self.view bringSubviewToFront:self.topRightView];
    [self.view bringSubviewToFront:self.bottomLeftView];
    [self.view bringSubviewToFront:self.bottomRightView];
    [self.view bringSubviewToFront:self.resetButton];
    [self.view bringSubviewToFront:self.distortButton];
    [self.view bringSubviewToFront:self.cameraButton];
    
}

-(void)showCamera{
    
    UIImagePickerController *picker = [[UIImagePickerController alloc]init];
    
    if([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]){
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    }
    
    picker.allowsEditing = NO;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:^{}];
}


#pragma mark IBActions
-(void)panHandler:(UIPanGestureRecognizer*)recognizer{
    CGPoint translation = [recognizer translationInView:recognizer.view.superview];
    if(recognizer.state == UIGestureRecognizerStateBegan){
        startX = recognizer.view.center.x;
        startY = recognizer.view.center.y;
    }
    
    
    self.imageView.center = CGPointMake(startX + translation.x,
                                         startY + translation.y);
}


- (IBAction)cameraButtonTouchUpInside:(id)sender {
    [self showCamera];
    self.panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panHandler:)];
    [self.view addGestureRecognizer:self.panGesture];

}

- (IBAction)resetButtonAction:(id)sender {
    [self setupImage:nil];
}


- (IBAction)buttonAction:(id)sender {
    
    Quadrilateral quadFrom;
    float scale = 1.0;
    quadFrom.topLeft.x = self.topLeftView.center.x / scale;
    quadFrom.topLeft.y = self.topLeftView.center.y / scale;
    quadFrom.topRight.x = self.topRightView.center.x / scale;
    quadFrom.topRight.y = self.topRightView.center.y / scale;
    quadFrom.bottomLeft.x = self.bottomLeftView.center.x / scale;
    quadFrom.bottomLeft.y = self.bottomLeftView.center.y / scale;
    quadFrom.bottomRight.x = self.bottomRightView.center.x / scale;
    quadFrom.bottomRight.y = self.bottomRightView.center.y / scale;
    
    Quadrilateral quadTo;
    CGFloat xOffset = self.view.bounds.size.width / 2.0;
    CGFloat yOffset = self.view.bounds.size.height / 2.0;
    quadTo.topLeft.x = self.view.bounds.origin.x - xOffset;
    quadTo.topLeft.y = self.view.bounds.origin.y - yOffset;
    quadTo.topRight.x = self.view.bounds.origin.x + self.view.bounds.size.width  - xOffset;
    quadTo.topRight.y = self.view.bounds.origin.y - yOffset;
    quadTo.bottomLeft.x = self.view.bounds.origin.x - xOffset;
    quadTo.bottomLeft.y = self.view.bounds.origin.y + self.view.bounds.size.height - yOffset;
    quadTo.bottomRight.x = self.view.bounds.origin.x + self.view.bounds.size.width - xOffset;
    quadTo.bottomRight.y = self.view.bounds.origin.y + self.view.bounds.size.height - yOffset;

    CATransform3D t = [self transformQuadrilateral:quadFrom toQuadrilateral:quadTo];
//    t = CATransform3DScale(t, 0.5, 0.5, 1.0);
    self.imageView.layer.anchorPoint = CGPointZero;
    [UIView animateWithDuration:1.0 animations:^{
        self.imageView.layer.transform = t;
    }];

}





#pragma mark OpenCV stuff...
-(CATransform3D)transformQuadrilateral:(Quadrilateral)origin toQuadrilateral:(Quadrilateral)destination {
    
    CvPoint2D32f *cvsrc = [self openCVMatrixWithQuadrilateral:origin];
    CvMat *src_mat = cvCreateMat( 4, 2, CV_32FC1 );
    cvSetData(src_mat, cvsrc, sizeof(CvPoint2D32f));
    

    CvPoint2D32f *cvdst = [self openCVMatrixWithQuadrilateral:destination];
    CvMat *dst_mat = cvCreateMat( 4, 2, CV_32FC1 );
    cvSetData(dst_mat, cvdst, sizeof(CvPoint2D32f));
    
    CvMat *H = cvCreateMat(3,3,CV_32FC1);
    cvFindHomography(src_mat, dst_mat, H);
    cvReleaseMat(&src_mat);
    cvReleaseMat(&dst_mat);
    
    CATransform3D transform = [self transform3DWithCMatrix:H->data.fl];
    cvReleaseMat(&H);
    
    return transform;
}

- (CvPoint2D32f*)openCVMatrixWithQuadrilateral:(Quadrilateral)origin {
    
    CvPoint2D32f *cvsrc = (CvPoint2D32f *)malloc(4*sizeof(CvPoint2D32f));
    cvsrc[0].x = origin.topLeft.x;
    cvsrc[0].y = origin.topLeft.y;
    cvsrc[1].x = origin.topRight.x;
    cvsrc[1].y = origin.topRight.y;
    cvsrc[2].x = origin.bottomRight.x;
    cvsrc[2].y = origin.bottomRight.y;
    cvsrc[3].x = origin.bottomLeft.x;
    cvsrc[3].y = origin.bottomLeft.y;

    return cvsrc;
}

-(CATransform3D)transform3DWithCMatrix:(float *)matrix {
    CATransform3D transform = CATransform3DIdentity;
    
    transform.m11 = matrix[0];
    transform.m21 = matrix[1];
    transform.m41 = matrix[2];
    
    transform.m12 = matrix[3];
    transform.m22 = matrix[4];
    transform.m42 = matrix[5];
    
    transform.m14 = matrix[6];
    transform.m24 = matrix[7];
    transform.m44 = matrix[8];
    
    return transform; 
}


#pragma   mark SMImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
    UIImage *image = [info objectForKey:@"UIImagePickerControllerEditedImage"];
    if(image == nil){
        image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    }
    
    [self setupImage:image];
    [picker dismissViewControllerAnimated:YES completion:^{
    }];
    
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
    
}

@end
