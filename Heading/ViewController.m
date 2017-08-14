//
//  ViewController.m
//  Heading
//
//  Created by yike on 2017/8/11.
//  Copyright © 2017年 yike. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSInteger, LocationHeading) {
    LocationHeadingNorth,
    LocationHeadingNorthEast,
    LocationHeadingEast,
    LocationHeadingSouthEast,
    LocationHeadingSouth,
    LocationHeadingSouthWest,
    LocationHeadingWest,
    LocationHeadingNorthWest
};
#define ratio 2 * M_PI / 360
@interface ViewController () <CLLocationManagerDelegate, CAAnimationDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>{
    NSInteger loopNum;
    CGFloat previousA, currentA;
    CLLocationCoordinate2D coordinate;
}
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) LocationHeading locationDirection;
@property (nonatomic, strong) UILabel *directionL;
@property (nonatomic, strong) UIView *directionAnimationL;
@property (nonnull, copy)NSNumber *previousAngle;
@property (nonatomic, strong)UIImagePickerController *imagePicker;
@property (nonatomic, strong )UIView *container;
@end

@implementation ViewController
#pragma mark - Setter And Getter
- (UIImagePickerController *)imagePicker {
    if (!_imagePicker) {
        _imagePicker = [[UIImagePickerController alloc]init];
        _imagePicker.delegate = self;
        _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        //sourcetype must is UIImagePickerControllerSourceTypeCamera
        _imagePicker.showsCameraControls = NO;
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        float aspectRatio = 4.0/3.0;
        float scale = screenSize.height/screenSize.width * aspectRatio;
        _imagePicker.cameraViewTransform = CGAffineTransformMakeScale(scale, scale);
        
        
    }
    return _imagePicker;
}
#pragma mark - Private
- (void)handleDirection: (CLLocationDirection )location {
    double result = location / 90;
    
    if (result == 0) {// north
        _locationDirection = LocationHeadingNorth;
        NSLog(@"North");
        _directionL.text = @"North";
    } else if (result > 0 && result < 1) {// East And North
        _locationDirection = LocationHeadingNorthEast;
        NSLog(@"NorthEast");
        _directionL.text = @"NorthEast";
    } else if (result == 1) {// east
        _locationDirection = LocationHeadingEast;
        NSLog(@"East");
        _directionL.text = @"East";
    } else if (result > 1 && result < 2) {// East And South
        _locationDirection = LocationHeadingSouthEast;
        NSLog(@"SouthEast");
        _directionL.text = @"SouthEast";
    } else if (result == 2) {// south
        _locationDirection = LocationHeadingSouth;
        NSLog(@"South");
        _directionL.text = @"South";
    } else if (result > 2 && result < 3) {// West And South
        _locationDirection = LocationHeadingSouthWest;
        NSLog(@"SouthWest");
        _directionL.text = @"SouthWest";
    } else if (result == 3) {// west
        _locationDirection = LocationHeadingWest;
        NSLog(@"West");
        _directionL.text = @"West";
    } else if (result > 3 && result < 4) {// West And North
        _locationDirection = LocationHeadingNorthWest;
        NSLog(@"NorthWest");
        _directionL.text = @"NorthWest";
    }
    
    [_directionL sizeToFit];
    _directionL.center = _container.center;
    
    [self handleAnimation:location];
}

- (void)handleAnimation: (CLLocationDirection)direction {
    
    if (direction - previousA > 300) {
        loopNum --;
    } else if(direction - previousA < -300) {
        loopNum ++;
    }
    
    NSNumber *angle = @(-(ratio * ( direction + loopNum * 360) ));
    
    CGAffineTransform transform = CGAffineTransformIdentity;;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.fromValue = _previousAngle;
    animation.toValue = angle;
    animation.delegate = self;
    [_directionAnimationL.layer addAnimation:animation forKey:@"rotate_label"];
    transform = CGAffineTransformRotate(CGAffineTransformIdentity, angle.floatValue);
    _directionAnimationL.transform = transform;
    
    _previousAngle = angle;
    previousA = direction;
    
}
#pragma mark - UIImagePickerDelegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
}
#pragma mark - CABasicAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    for (CALayer *layer in _directionAnimationL.layer.sublayers) {
        [layer removeAllAnimations];
    }
}
#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    CLLocationDirection direction = [newHeading magneticHeading];
    [self handleDirection:direction];
    
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = locations[0];
    coordinate = location.coordinate;
    
}
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
}
#pragma mark - Setter And Getter
- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc]init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.distanceFilter = kCLLocationAccuracyBest;
        [_locationManager requestAlwaysAuthorization];
    }
    return _locationManager;
}
#pragma mark -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _directionL = [UILabel new];
    _directionL.textColor = [UIColor colorWithRed:238 / 255.0 green:216 / 255.0 blue:174 / 255.0 alpha:1];
    _directionL.font = [UIFont systemFontOfSize:40];
    
    
    UIImage *image = [UIImage imageNamed:@"compass.png"];
    
    _directionAnimationL = [UIView new];
    _directionAnimationL.layer.contents = (__bridge id _Nullable)(image.CGImage);
    _directionAnimationL.layer.frame = CGRectMake(0, 0, image.size.height * .3, image.size.height * .3);
    _previousAngle = @0;
    [self.locationManager startUpdatingHeading];
    [self.locationManager startUpdatingLocation];
    
    _container = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    _container.backgroundColor = [UIColor clearColor];
    _directionAnimationL.center = _container.center;
    _directionAnimationL.frame = CGRectMake(_directionAnimationL.frame.origin.x, 100, _directionAnimationL.frame.size.width, _directionAnimationL.frame.size.height);
    [_container addSubview:_directionL];
    [_container addSubview:_directionAnimationL];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        //cameraOverlayView have a must condition what sourceType of imagepicker must is UIImagePickerControllerSourceTypeCamera
        self.imagePicker.cameraOverlayView = _container;
        //self.navigationController not nil
        [self presentViewController:self.imagePicker animated:YES completion:^{
            
        }];
    }
    // Do any additional setup after loading the view, typically from a nib.
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

@implementation ImagePickerVC

- (void) viewDidLoad {
    [super viewDidLoad];
    
}

@end
