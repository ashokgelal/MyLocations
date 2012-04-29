#import "CategoryPickerViewController.h"

@implementation CategoryPickerViewController {
    NSArray *categories;
    NSIndexPath *selectedIndexPath;
}

@synthesize delegate, selectedCategoryName;


- (void)viewDidLoad
{
    [super viewDidLoad];
    categories = [NSArray arrayWithObjects:
                  @"No Category", 
                  @"Apple Store", 
                  @"Bar", 
                  @"Bookstore", 
                  @"Club", 
                  @"Grocery Store", 
                  @"Historic Building", 
                  @"House", 
                  @"Icecream Vendor", 
                  @"Landmark", 
                  @"Park", 
                  nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    categories = nil;
    selectedIndexPath = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [categories count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSString *categoryName = [categories objectAtIndex:indexPath.row];
    cell.textLabel.text = categoryName;
    
    if([categoryName isEqualToString:selectedCategoryName]){
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        selectedIndexPath = indexPath;
    } else{
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row != selectedIndexPath.row){
        UITableViewCell *newCell = [tableView cellForRowAtIndexPath:indexPath];
        newCell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:selectedIndexPath];
        oldCell.accessoryType = UITableViewCellAccessoryNone;
        
        selectedIndexPath = indexPath;
    }
    NSString *categoryName = [categories objectAtIndex:indexPath.row];
    [self.delegate categoryPicker:self didPickCategory:categoryName];
}

@end
