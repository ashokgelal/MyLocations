#import "CurrentLocationViewController.h"

@interface CurrentLocationViewController()
-(void)updateLabels;
-(void)startLocationManager;
-(void)stopLocationManager;
-(void)configureGetButton;
@end

@implementation CurrentLocationViewController{
    CLLocationManager *locationManager;
    CLLocation *location;
    BOOL updatingLocation;
    NSError *lastLocationError;
    
    CLGeocoder *geocoder;
    CLPlacemark *placemark;
    BOOL performingReverseGeocoding;
    NSError *lastGeocodingError;
}

@synthesize messsageLabel;
@synthesize latitudeLabel;
@synthesize longitudeLabel;
@synthesize addressLabel;
@synthesize tagButton;
@synthesize getButton;

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if((self=[super initWithCoder:aDecoder])){
        locationManager = [[CLLocationManager alloc] init];
        geocoder = [[CLGeocoder alloc] init];
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self updateLabels];
    [self configureGetButton];
}

-(void)viewDidUnload
{
    [super viewDidUnload];
    self.messsageLabel = nil;
    self.latitudeLabel = nil;
    self.longitudeLabel = nil;
    self.addressLabel = nil;
    self.tagButton = nil;
    self.getButton = nil;
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

-(IBAction)getLocation:(id)sender
{
    if(updatingLocation){
        [self stopLocationManager];
    }
    else{
        location = nil;
        lastLocationError = nil;
        placemark = nil;
        lastGeocodingError = nil;
        [self startLocationManager];
    }
    [self updateLabels];
    [self configureGetButton];
}

-(NSString *)stringFromPlacemark:(CLPlacemark *)thePlacemark
{
    return [NSString stringWithFormat:@"%@ %@\n%@ %@ %@",
            thePlacemark.subThoroughfare, thePlacemark.thoroughfare,
            thePlacemark.locality, thePlacemark.administrativeArea,
            thePlacemark.postalCode];
}

-(void)updateLabels{
    if(location != nil){
        self.messsageLabel.text = @"GPS Coordinates";
        self.latitudeLabel.text = [NSString stringWithFormat:@"%.8f", location.coordinate.latitude];
        self.longitudeLabel.text = [NSString stringWithFormat:@"%.8f", location.coordinate.longitude];
        self.tagButton.hidden = NO;
        
        if(placemark != nil){
            self.addressLabel.text = [self stringFromPlacemark:placemark];
        }else if (performingReverseGeocoding) {
            self.addressLabel.text = @"Searching for Address...";
        }else if (lastGeocodingError != nil) {
            self.addressLabel.text = @"Error Finding Address";
        }else {
            self.addressLabel.text = @"No Address Found";
        }
    }
    else{
        self.latitudeLabel.text = @"";
        self.longitudeLabel.text = @"";
        self.addressLabel.text = @"";
        self.tagButton.hidden = YES;
        
        NSString *statusMessage;
        if(lastLocationError != nil){
            if([lastLocationError.domain isEqualToString:kCLErrorDomain] && lastLocationError.code == kCLErrorDenied){
                statusMessage = @"Location ServicesDisabled";
            }
            else{
                statusMessage = @"Error Getting Location";
            }
        }
        else if(![CLLocationManager locationServicesEnabled]){
            statusMessage = @"Location Services Disabled";
        }
        else if(updatingLocation){
            statusMessage = @"Searching...";
        }
        else{
            statusMessage = @"Press the Button to Start";
        }
        self.messsageLabel.text = statusMessage;
    }
}

-(void)configureGetButton
{
    if(updatingLocation){
        [self.getButton setTitle:@"Stop" forState:UIControlStateNormal];
    }
    else{
        [self.getButton setTitle:@"Get My Location" forState:UIControlStateNormal];
    }
}

-(void)startLocationManager{
    if([CLLocationManager locationServicesEnabled]){
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        [locationManager startUpdatingLocation];
        updatingLocation = YES;
        
        [self performSelector:@selector(didTimeOut:) withObject:nil afterDelay:60];
    }
}

-(void) stopLocationManager{
    if(updatingLocation){
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(didTimeOut:) object:nil];
        
        [locationManager stopUpdatingLocation];
        locationManager.delegate = nil;
        updatingLocation = NO;
    }
}

-(void) didTimeOut:(id)obj
{
    NSLog(@"*** Timeout");
    if(location == nil){
        [self stopLocationManager];
        lastLocationError = [NSError errorWithDomain:@"MyLocationsErrorDomain" code:1 userInfo:nil];
        
        [self updateLabels];
        [self configureGetButton];
    }
}
#pragma mark - CLLocationManagerDelegate
-(void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError %@", error);
    if(error.code == kCLErrorLocationUnknown){
        return;
    }
    [self stopLocationManager];
    lastLocationError = error;
    [self updateLabels];
    [self configureGetButton];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"didUpdateToLocation %@", newLocation);
    
    if([newLocation.timestamp timeIntervalSinceNow] < -5.0){
        return;
    }
    if(newLocation.horizontalAccuracy < 0){
        return;
    }
    
    CLLocationDistance distance = MAXFLOAT;
    if(location != nil){
        distance = [newLocation distanceFromLocation:location];
    }
    
    if(location==nil || location.horizontalAccuracy > newLocation.horizontalAccuracy){
        lastLocationError  = nil;
        location = newLocation;
        [self updateLabels];
        
        if(newLocation.horizontalAccuracy <= locationManager.desiredAccuracy){
            NSLog(@"*** we're done!");
            [self stopLocationManager];
            [self configureGetButton];
            
            if(distance > 0){
                performingReverseGeocoding = NO;
            }
        }
        
        if(!performingReverseGeocoding){
            NSLog(@"** Going to geocode");
            performingReverseGeocoding = YES;
            
            [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error){
                NSLog(@"*** Found placemarks:%@, error:%@", placemark, error);
                lastGeocodingError = error;
                if(error == nil && [placemarks count] > 0){
                    placemark = [placemarks lastObject];
                }
                else {
                    placemark = nil;
                }
                performingReverseGeocoding = NO;
                [self updateLabels];
            }];
        }
    }else if(distance < 1.0){
        NSTimeInterval timeInterval = [newLocation.timestamp timeIntervalSinceDate:location.timestamp];
        if(timeInterval > 10){
            NSLog(@"*** Force done!");
            [self stopLocationManager];
            [self updateLabels];
            [self configureGetButton];
        }
    }
}

@end
