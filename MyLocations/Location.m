#import "Location.h"


@implementation Location

@dynamic latitude;
@dynamic longitude;
@dynamic date;
@dynamic locationDescription;
@dynamic category;
@dynamic placemark;

-(CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
}

-(NSString *)title
{
    if([self.locationDescription length] > 0){
        return self.locationDescription;
    }else {
        return @"(No Description)";
    }
}

-(NSString *) subtitle
{
    return self.category;
}

@end
