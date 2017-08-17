//
//  ViewController.m
//  Heading
//
//  Created by yike on 2017/8/11.
//  Copyright © 2017年 yike. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
typedef NS_ENUM(NSInteger, BubbleType) {
    BubbleTypeUp,
    BubbleTypeDown,
    BubbleTypeLeft,
    BubbleTypeRight
};
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
@interface DotView:UIView
@property (nonatomic, copy)NSString * name;
@end
@interface BubbleView : UIView
+ (void)showInView:(UIView *)view;
@property (nonatomic, strong)NSMutableArray *bubbleArr;
@property (nonatomic, assign)BubbleType type;
@end
typedef void(^TouchUpBubble)(void);
@interface DotAddressView : UIView
@property (nonatomic, copy)TouchUpBubble block;
@property (nonatomic, assign)CLLocationDistance distance;
@property (nonatomic, copy)NSDictionary *dataDic;
@property (nonatomic, strong)UILabel *nameL;
@property (nonatomic, strong)UIButton *iconBtn;
@property (nonatomic, assign)BOOL dotIsHidden;
@end
#define ratio 2 * M_PI / 360
#define bubbleSep 5
#define bubbleAng 10
@interface ViewController () <CLLocationManagerDelegate, CAAnimationDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>{
    NSInteger loopNum;
    CGFloat previousA, currentA;
    CLLocationCoordinate2D coordinate;
    BOOL isLocationFinish;
    CGFloat separateLine;
}
@property (nonatomic, strong)UIActivityIndicatorView *indicateView;
@property (nonatomic, copy)NSString *searchQuery;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) LocationHeading locationDirection;
@property (nonatomic, strong) UILabel *directionL;
@property (nonatomic, strong) UIView *directionAnimationL;
@property (nonatomic, strong) UITextField *inputAddressText;
@property (nonatomic, strong) UIView *radarView;
@property (nonnull, copy)NSNumber *previousAngle;
@property (nonatomic, strong)UIImagePickerController *imagePicker;
@property (nonatomic, strong )UIView *container;
@property (nonatomic, strong)NSMutableArray *locationArr;
@property (nonatomic, strong)NSMutableArray *dotViewArr;
@property (nonatomic, strong)NSMutableArray *dotAddViewArr;
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
- (void)keyboardFrameHide:(NSNotification *)noti {
    [UIView animateWithDuration:.05 animations:^{
        _inputAddressText.frame =  CGRectMake(10, [UIScreen mainScreen].bounds.size.height - 50, [UIScreen mainScreen].bounds.size.width - 20, 40);
    }];
    
}
- (void)keyboardFrameChange:(NSNotification *)noti {
    CGRect rect = {{1, 1}, {1, 1}};
    CGPoint point = {1, 1};
    CGSize size = {100 , 100};
    NSDictionary *userInfo = noti.userInfo;
    id keyboardObj = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    NSValue *value = keyboardObj;
    CGRect keyboardRect = value.CGRectValue;
    [UIView animateWithDuration:.1 animations:^{
        _inputAddressText.frame = CGRectMake(_inputAddressText.frame.origin.x, keyboardRect.origin.y - _inputAddressText.frame.size.height - 5, _inputAddressText.frame.size.width, _inputAddressText.frame.size.height);
    }];
    
    
}
- (void)searchAddress {
    if (![_inputAddressText.text isEqualToString:_searchQuery]) {
        _searchQuery = _inputAddressText.text;
        _inputAddressText.placeholder = _searchQuery;
        [_inputAddressText resignFirstResponder];
        [_indicateView startAnimating];
        
        [_locationArr removeAllObjects];
        for (DotView *view in _dotViewArr) {
            [view removeFromSuperview];
        }
        [_dotViewArr removeAllObjects];
        for (DotAddressView *view in _dotAddViewArr) {
            [view removeFromSuperview];
        }
        [_dotAddViewArr removeAllObjects];
        isLocationFinish = NO;
        [_locationManager startUpdatingLocation];
    }
}

- (void)initLocationView {
    for (NSDictionary *dic in _locationArr) {
        DotAddressView *view = [[DotAddressView alloc]initWithFrame:CGRectMake(-200, -200, 50, 50)];
        view.dataDic = dic;
        
        [_dotAddViewArr addObject:view];
        [_container addSubview:view];
    }
}
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
    [self handleAllAddress];
}
- (DotAddressView *)getDotAddressViewFromDot:(DotView *)dot {
    for (DotAddressView *dotA in _dotAddViewArr) {
        if ([dotA.dataDic[@"address"] isEqualToString:dot.name]) {
            return dotA;
        }
    }
    return nil;
}
- (void)stopIndicate {
    if ([_indicateView isAnimating]) {
    [_indicateView stopAnimating];
    }
}
- (void)getSoundLocationInfo {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate,100, 100);
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc]init];
    request.region = region;
    request.naturalLanguageQuery = _searchQuery;
    
    MKLocalSearch *localSearch = [[MKLocalSearch alloc]initWithRequest:request];
    [localSearch startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error){
        if (!error) {
            NSArray *tmp = response.mapItems;
            [_locationArr removeAllObjects];
            [_dotAddViewArr removeAllObjects];
            
            [self performSelector:@selector(stopIndicate) withObject:nil afterDelay:10];
            
            for (MKMapItem *item in tmp) {
                CLGeocoder *geo = [[CLGeocoder alloc]init];
                [geo geocodeAddressString:item.name completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                    CLPlacemark *place = placemarks[0];
                    if (!place) return;
                    NSDictionary *dic = place.addressDictionary;
                    NSString *tmpStr = [NSString stringWithFormat:@"%@%@%@", dic[@"State"], dic[@"SubLocality"] ? dic[@"SubLocality"] : @"", dic[@"City"]];
                    
                    
                    if (place.name.length > tmpStr.length) {
                    [_locationArr addObject:@{@"address":[place.name substringFromIndex:tmpStr.length], @"coordinate":place.location}];
                    } else {
                        [_locationArr addObject:@{@"address":place.name , @"coordinate":place.location}];
                    }
                    if (_locationArr.count == tmp.count ){
                        [_indicateView stopAnimating];
                        [self initDotView];
                        [self initLocationView];
                 
                    }
                }];
            }
            
            
            //do something.
        }else{

            //do something.
        }
    }];
}

- (void)handleAllAddress {
    int i = 0;
    for (DotView *dot in _dotViewArr) {
        CGRect convertRect = [_radarView convertRect:dot.frame toView:_container];
        CGPoint convertPoint = convertRect.origin;
        

        CGFloat radarX = CGRectGetMaxX(_radarView.frame) - _radarView.frame.size.height;

        CGFloat radarY = CGRectGetMaxY(_radarView.frame) - _radarView.frame.size.height;
        CGFloat radarV = _radarView.frame.size.height;
        
        DotAddressView *view  = [self getDotAddressViewFromDot:dot];
        
        if (convertPoint.y < separateLine) {
            NSLog(@"%@", dot.name);
                view.dotIsHidden = NO;

            NSDictionary *dic = _locationArr[i];
            CLLocation *loc = dic[@"coordinate"];
            CGPoint point = CGPointMake(loc.coordinate.longitude - coordinate.longitude, loc.coordinate.latitude - coordinate.latitude);
            CLLocation *tmpLocation = [[CLLocation alloc]initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
            CLLocationDistance distance = [loc distanceFromLocation:tmpLocation];
            view.distance = distance;
//            CGRect tmp = CGRectMake([UIScreen mainScreen].bounds.size.width / radarV * (_radarView.frame.size.width / 2 + point.x * 1000) - view.frame.size.width,  [UIScreen mainScreen].bounds.size.height / radarV * (_radarView.frame.size.height / 2 - point.y * 1000), 100, 50);
            CGRect tmp = CGRectMake(([UIScreen mainScreen].bounds.size.width + view.frame.size.width) / radarV * (convertPoint.x - radarX) - view.frame.size.width / 2,  [UIScreen mainScreen].bounds.size.height / radarV * 2  * (convertPoint.y - radarY), 100, 50);
            view.frame =tmp;
        } else {
                view.dotIsHidden = YES;
        }
        i++;
    }
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
    [_radarView.layer addAnimation:animation forKey:@"rotate_label"];
    transform = CGAffineTransformRotate(CGAffineTransformIdentity, angle.floatValue);
    _directionAnimationL.transform = transform;
    _radarView.transform = transform;
    
    _previousAngle = angle;
    previousA = direction;
    
}

- (void)handleLocation:(CLLocation *)location {
    
    if (isLocationFinish) return;
    isLocationFinish = YES;
    
    [self getSoundLocationInfo];
    [self.locationManager startUpdatingHeading];
//    [self initLocationView];
    

    
}

- (void)initDotView {
    for (int i = 0; i < _locationArr.count; i++) {
        NSDictionary *dic = _locationArr[i];
        CLLocation *loc = dic[@"coordinate"];
        CGPoint point = CGPointMake(loc.coordinate.longitude - coordinate.longitude, loc.coordinate.latitude - coordinate.latitude);
        
        DotView *dot = [[DotView alloc] initWithFrame:CGRectMake(_radarView.frame.size.width / 2 + point.x * 1000, _radarView.frame.size.height / 2 - point.y * 1000, 4, 4)];
        dot.name = dic[@"address"];
        [_radarView addSubview:dot];
        [_dotViewArr addObject:dot];
    }
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
    [self handleLocation:location];
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
//观音山118.204646,24.501317
//厦门司法局118.156209,24.510129
//加州商业广场118.160377,24.486413
//奥林匹克博物馆118.198969,24.485007
- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardFrameChange:) name:UIKeyboardDidChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardFrameHide:) name:UIKeyboardWillHideNotification object:nil];
_searchQuery = @"Park";
//    CLLocation *loc1 = [[CLLocation alloc]initWithLatitude:24.501317 longitude:118.204646];
//    CLLocation *loc2 = [[CLLocation alloc]initWithLatitude:24.510129 longitude:118.156209];
//    CLLocation *loc3 = [[CLLocation alloc]initWithLatitude:24.486413 longitude:118.160377];
//    CLLocation *loc4 = [[CLLocation alloc]initWithLatitude:24.485007 longitude:118.198969];
//    _locationArr = @[@{@"address":@"观音山", @"coordinate":loc1}, @{@"address":@"厦门司法局", @"coordinate":loc2}, @{@"address":@"加州商业广场", @"coordinate":loc3}, @{@"address":@"奥林匹克博物馆", @"coordinate":loc4}].mutableCopy;
    _locationArr = @[].mutableCopy;
    _dotViewArr = @[].mutableCopy;
    _dotAddViewArr = @[].mutableCopy;
    
    _indicateView = [[UIActivityIndicatorView alloc]init];
    _indicateView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:_indicateView];
    _indicateView.center = window.center;

    
    
    
    _inputAddressText = [[UITextField alloc]initWithFrame:CGRectMake(10, [UIScreen mainScreen].bounds.size.height - 50, [UIScreen mainScreen].bounds.size.width - 20, 40)];
    _inputAddressText.borderStyle = UITextBorderStyleNone;
    _inputAddressText.layer.borderColor = [UIColor clearColor].CGColor;
    _inputAddressText.layer.borderWidth = .5;
    _inputAddressText.layer.cornerRadius = 5;
    _inputAddressText.backgroundColor = [UIColor whiteColor];
    _inputAddressText.placeholder = _searchQuery;
    
    UIButton *searchBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 40, 40)];
    [searchBtn setTitle:@"搜索" forState:UIControlStateNormal];
    searchBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    [searchBtn setTitleColor:[UIColor colorWithRed:100 / 255.0 green:100 / 255.0 blue:100 / 255.0 alpha:1] forState:UIControlStateNormal];
    [searchBtn addTarget:self action:@selector(searchAddress) forControlEvents:UIControlEventTouchUpInside];
    
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 10, 10)];
    
    _inputAddressText.leftView = view;
    _inputAddressText.leftViewMode = UITextFieldViewModeAlways;
    
    _inputAddressText.rightViewMode = UITextFieldViewModeAlways;
    _inputAddressText.rightView = searchBtn;
    
    
    
    _directionL = [UILabel new];
    _directionL.textColor = [UIColor colorWithRed:238 / 255.0 green:216 / 255.0 blue:174 / 255.0 alpha:1];
    _directionL.font = [UIFont systemFontOfSize:40];
    
    
    UIImage *image = [UIImage imageNamed:@"compass.png"];
    UIImage *image1 = [UIImage imageNamed:@"radar.png"];
    
    _directionAnimationL = [UIView new];
    _directionAnimationL.layer.contents = (__bridge id _Nullable)(image.CGImage);
    _directionAnimationL.layer.frame = CGRectMake(0, 0, image.size.height * .3, image.size.height * .3);
    
    _radarView = [UIView new];
    _radarView.layer.contents = (__bridge id _Nullable)(image1.CGImage);
    _radarView.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - image1.size.width * .12 + 10 , 0, image1.size.width * .12, image1.size.height * .12);
    separateLine = CGRectGetMaxY(_radarView.frame) - _radarView.frame.size.height / 2;
    
    
    _previousAngle = @0;

    [self.locationManager startUpdatingLocation];
//    [self getSoundLocationInfo];

    
    _container = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    _container.backgroundColor = [UIColor clearColor];
    _directionAnimationL.center = _container.center;
    _directionAnimationL.frame = CGRectMake(_directionAnimationL.frame.origin.x, 100, _directionAnimationL.frame.size.width, _directionAnimationL.frame.size.height);
    //    [_container addSubview:_directionL];
//    [_container addSubview:_directionAnimationL];
    [_container addSubview:_radarView];
    [_container insertSubview:_inputAddressText atIndex:10];



    
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

@implementation DotView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef content = UIGraphicsGetCurrentContext();
    
    CGContextAddArc(content, rect.size.width / 2, rect.size.width / 2, rect.size.width / 2, 0, M_PI * 2, 0);
    [[UIColor greenColor]set];
    CGContextDrawPath(content, kCGPathFill);
    
}

@end

@implementation DotAddressView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
//        self.backgroundColor = [UIColor redColor];
        [self addSubview:self.iconBtn];
        [self addSubview:self.nameL];
    }
    return self;
}
- (void)showAddressInfo {
    CGFloat viewW = 100, viewH = 100;
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
    
    [BubbleView showInView:self];

}
- (UIButton *)iconBtn {
    if (!_iconBtn) {
        _iconBtn = [UIButton new];
        _iconBtn.titleLabel.font = [UIFont systemFontOfSize:11];
        [_iconBtn addTarget:self action:@selector(showAddressInfo) forControlEvents:UIControlEventTouchUpInside];
    }
    return _iconBtn;
}
- (UILabel *)nameL {
    if (!_nameL) {
        _nameL = [UILabel new];
        _nameL.textColor = [UIColor colorWithRed:238 / 255.0 green:100 / 255.0 blue:174 / 255.0 alpha:1];
        _nameL.font = [UIFont systemFontOfSize:13];
        _nameL.textAlignment = NSTextAlignmentCenter;
    }
    return _nameL;
}
- (void)setDataDic:(NSDictionary *)dataDic {
    _dataDic = [dataDic copy];
    self.nameL.text = _dataDic[@"address"];
    self.nameL.adjustsFontSizeToFitWidth  = YES;
    
}

- (void)setDistance:(CLLocationDistance)distance {
    _distance = distance;
    [self.iconBtn setTitle:[NSString stringWithFormat:@"%.2fkm", _distance / 1000] forState:UIControlStateNormal];
}
- (void)setDotIsHidden:(BOOL)dotIsHidden {
    _dotIsHidden = dotIsHidden;
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView animateWithDuration:.5 animations:^{
        self.iconBtn.alpha = _dotIsHidden ? 0 : 1;
        self.nameL.alpha = _dotIsHidden ? 0 : 1;
        
    }];
    
    
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.iconBtn.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height * 2 / 3);
    self.nameL.frame = CGRectMake(0, CGRectGetMaxY(self.iconBtn.frame), self.frame.size.width, self.frame.size.height / 3);
}
@end
#define Bubble_W 100
#define Bubble_H 100
@implementation BubbleView

+ (instancetype)shareInstance {
    static BubbleView *bubbleView = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bubbleView = [BubbleView new];
    });
    return bubbleView;
}
- (void)showInSuperView:(UIView *)superView {
    
    BubbleView *bubbleView = [BubbleView shareInstance];
    
        [superView addSubview:bubbleView];
}
+ (void)showInView:(UIView *)view {
    [[BubbleView shareInstance]showInSuperView:view];
    
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}
- (void)setType:(BubbleType)type {
    _type = type;
    [self setNeedsDisplay];
}
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    switch (_type) {
        case BubbleTypeUp:
            CGContextMoveToPoint(context, 0, 0);
            CGContextAddLineToPoint(context, rect.size.width, 0);
            CGContextAddLineToPoint(context, rect.size.width, rect.size.height - bubbleSep);
            CGContextAddLineToPoint(context, rect.size.width / 2 + bubbleAng / 2, rect.size.height - bubbleSep);
            CGContextAddLineToPoint(context, rect.size.width / 2, rect.size.height);
            CGContextAddLineToPoint(context, rect.size.width / 2 - bubbleAng / 2, rect.size.height - bubbleSep);
            CGContextAddLineToPoint(context, 0, rect.size.height - bubbleSep);
            CGContextAddLineToPoint(context, 0, 0);
            CGContextClosePath(context);

            break;
            
        default:
            break;
    }
    
}

@end
