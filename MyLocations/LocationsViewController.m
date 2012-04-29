#import "LocationsViewController.h"
#import "LocationDetailsViewController.h"
#import "Location.h"
#import "LocationCell.h"

@implementation LocationsViewController{
    NSFetchedResultsController *fetchedResultsController;
}

@synthesize managedObjectContext;

-(NSFetchedResultsController *)fetchedResultsController
{
    if(fetchedResultsController == nil){
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc]init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Location" inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        NSSortDescriptor *sortDescriptor1 = [NSSortDescriptor sortDescriptorWithKey:@"category" ascending:YES];
        NSSortDescriptor *sortDescriptor2 = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
        
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor1, sortDescriptor2, nil]];
        
        [fetchRequest setFetchBatchSize:20];
        
        fetchedResultsController = [[NSFetchedResultsController alloc] 
                                    initWithFetchRequest:fetchRequest 
                                    managedObjectContext:self.managedObjectContext 
                                    sectionNameKeyPath:@"category" 
                                    cacheName:@"Locations"];
        
        fetchedResultsController.delegate = self;
    }
    return fetchedResultsController;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self performFetch];
}

-(void) performFetch
{
    NSError *error;
    if(![self.fetchedResultsController performFetch:&error]){
        FATAL_CORE_DATA_ERROR(error);
        return;
    }
}
-(void)viewDidUnload
{
    [super viewDidUnload];
    fetchedResultsController.delegate = nil;
    fetchedResultsController = nil;
}


-(void)dealloc
{
    fetchedResultsController.delegate = nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"EditLocation"]){
        UINavigationController *navigationController = segue.destinationViewController;
        LocationDetailsViewController *controller = (LocationDetailsViewController *)navigationController.topViewController; 
        controller.managedObjectContext = self.managedObjectContext;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        Location *location = [self.fetchedResultsController objectAtIndexPath:indexPath];
        controller.locationToEdit = location;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

-(void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    LocationCell *locationCell = (LocationCell *)cell;
    Location *location = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if([location.locationDescription length]>0){
        locationCell.descriptionLabel.text = location.locationDescription;
    }else {
        locationCell.descriptionLabel.text = @"(No Description)";
    }
    
    if(location.placemark != nil){
        locationCell.addressLabel.text = [NSString stringWithFormat:@"%@ %@, %@",
                                          location.placemark.subThoroughfare,
                                          location.placemark.thoroughfare,
                                          location.placemark.locality];
    }else{
        locationCell.addressLabel.text = [NSString stringWithFormat:@"Lat:%.8f, Long:%.8f",
                                          [location.latitude doubleValue],
                                          [location.longitude doubleValue]];
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Location"];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo name];
}

#pragma mark - NSFetchedResultsControllerDelegate

-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    NSLog(@"** controllerWillChangeContent");
    [self.tableView beginUpdates];
}

-(void) controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            NSLog(@"** controllerDidChangeobject - Insert");
            [self.tableView insertRowsAtIndexPaths: [NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
            case NSFetchedResultsChangeDelete:
            NSLog(@"*** change section - delete");
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
            case NSFetchedResultsChangeUpdate:
            NSLog(@"*** change object - update");
            [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
            case NSFetchedResultsChangeMove:
            NSLog(@"change object - move");
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

-(void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type    
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            NSLog(@"** change section - insert");
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
             break;
            
        case NSFetchedResultsChangeDelete:
            NSLog(@"** change section - delete");
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    NSLog(@"** controller did change content");
    [self.tableView endUpdates];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete){
        Location *location = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [self.managedObjectContext deleteObject:location];
        
        NSError *error;
        if(![self.managedObjectContext save:&error]){
            FATAL_CORE_DATA_ERROR(error);
            return;
        }
    }
}
@end