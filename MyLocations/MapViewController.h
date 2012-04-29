#import <UIKit/UIKit.h>

@interface MapViewController : UIViewController<MKMapViewDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) IBOutlet MKMapView *mapView;

-(IBAction)showUser;
-(IBAction)showLocations;

@end
