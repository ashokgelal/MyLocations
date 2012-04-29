#import "MapViewController.h"
#import "Location.h"
#import "LocationDetailsViewController.h"

@implementation MapViewController
{
    NSArray *locations;
}

@synthesize managedObjectContext;
@synthesize mapView;

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self updateLocactions];
    if ([locations count] > 0) {
        [self showLocations];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                        selector:@selector(contextDidChange:) 
                                        name:NSManagedObjectContextDidSaveNotification 
                                        object:self.managedObjectContext];
}

-(void)contextDidChange:(NSNotification *)notification
{
    [self updateLocactions];
}

-(void)viewDidUnload
{
    [super viewDidUnload];
    self.mapView = nil;
    locations = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:self.managedObjectContext];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:self.managedObjectContext];
}

-(IBAction)showUser
{
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.coordinate, 1000, 1000);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
}

-(MKCoordinateRegion)regionForAnnotations:(NSArray *)annotations
{
    MKCoordinateRegion region;
    if ([annotations count] == 0) {
        region = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.coordinate, 1000, 1000);
    }else if ([annotations count] == 1) {
        id<MKAnnotation> annotation = [annotations lastObject];
        region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 1000, 1000);
    }else {
        CLLocationCoordinate2D topLeftCoord;
        topLeftCoord.latitude = -90;
        topLeftCoord.longitude = 180;
        
        CLLocationCoordinate2D bottomRightCoord;
        bottomRightCoord.latitude = 90;
        bottomRightCoord.longitude = -180;
        
        for(id<MKAnnotation> annotation in annotations){
            topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude);
            topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude);
            bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude);
            bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude);
        }
        
        const double extraSpace = 1.1;
        region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude + bottomRightCoord.latitude)/2.0;
        region.center.longitude = topLeftCoord.longitude - (topLeftCoord.longitude + bottomRightCoord.longitude)/2.0;
        region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * extraSpace;
        region.span.longitudeDelta = fabs(topLeftCoord.longitude - bottomRightCoord.longitude) * extraSpace;
    }
    return [self.mapView regionThatFits:region];
}

-(IBAction)showLocations    
{
    MKCoordinateRegion region = [self regionForAnnotations:locations];
    [self.mapView setRegion:region animated:YES];
}

-(void)updateLocactions{
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Location" inManagedObjectContext:self.managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *foundObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (foundObjects == nil) {
        FATAL_CORE_DATA_ERROR(error);
        return;
    }
    if(locations != nil){
        [self.mapView removeAnnotations:locations];
    }
    
    locations = foundObjects;
    [self.mapView addAnnotations:locations];
}

#pragma mark - MKMapViewDelegate

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if([annotation isKindOfClass:[Location class]]){
        static NSString *identifier = @"Location";
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if(annotationView == nil){
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.animatesDrop = NO;
            annotationView.pinColor = MKPinAnnotationColorGreen;
            
            UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            [rightButton addTarget:self action:@selector(showLocationDetails:) forControlEvents:UIControlEventTouchUpInside];
            annotationView.rightCalloutAccessoryView = rightButton;
        }else {
            annotationView.annotation = annotation;
        }
        
        UIButton *button = (UIButton *)annotationView.rightCalloutAccessoryView;
        button.tag = [locations indexOfObject:(Location *)annotation];
        
        return annotationView;
    }
    
    return nil;
}

-(void)showLocationDetails:(UIButton *)button
{
    [self performSegueWithIdentifier:@"EditLocation" sender:button];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"EditLocation"]){
        UINavigationController *navigationController = segue.destinationViewController;
        LocationDetailsViewController *controller = (LocationDetailsViewController *) navigationController.topViewController;
        controller.managedObjectContext = self.managedObjectContext;
        
        Location *location = [locations objectAtIndex:((UIButton *)sender).tag];
        controller.locationToEdit = location;
    }
}

@end