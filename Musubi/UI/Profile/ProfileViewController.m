/*
 * Copyright 2012 The Stanford MobiSocial Laboratory
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "ProfileViewController.h"
#import "MIdentity.h"
#import "FeedManager.h"
#import "MFeed.h"
#import "ProfileNamePictureCell.h"
#import "Musubi.h"
#import "FeedViewController.h"

@interface ProfileViewController ()

@end

@implementation ProfileViewController

@synthesize identity = _identity;

@synthesize feedManager = _feedManager;
@synthesize delegate = _delegate;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _feedManager = [[FeedManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    }
    
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    
    feeds = [_feedManager acceptedFeedsFromIdentity:_identity];
    
    self.title = @"Profile";//_identity.name;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 1;
        case 1:
            return 1;
        case 2:
            return feeds.count;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            return 90;
        }
        default: {
            return 44;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            static NSString *CellIdentifier = @"ProfileNamePictureCell";
            ProfileNamePictureCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            if (cell == nil) {
                cell = [[ProfileNamePictureCell alloc]
                        initWithStyle:UITableViewCellStyleDefault 
                        reuseIdentifier:CellIdentifier];
            }
            
            if(_identity.musubiName) {
                cell.name.text = _identity.musubiName;
            } else if(_identity.name) {
                cell.name.text = _identity.name;
            } else if(_identity.principal) {
                cell.name.text = _identity.principal;
            } else {
                cell.name.text = @"Unknown";
            }
            
            cell.principal.text = _identity.principal;
            if(_identity.musubiThumbnail) {
                cell.picture.image = [UIImage imageWithData:_identity.musubiThumbnail];
            }
            else if (_identity.thumbnail) {
                cell.picture.image = [UIImage imageWithData:_identity.thumbnail];
            }
            if(cell.picture.image == nil) {
                cell.picture.image = [UIImage imageNamed:@"missing.png"];
            }
            
            return cell;
        }
        case 1: {
            UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
            }
            
            [[cell textLabel] setText: @"New Conversation"];
            
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            return cell;

        }
        case 2: {
            UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
            }
            
            MFeed* feed = (MFeed*)[feeds objectAtIndex:indexPath.row];
            NSString* feedTitle = [_feedManager identityStringForFeed:feed];
            [[cell textLabel] setText: feedTitle];
            NSString* timestamp = [NSDate dateWithTimeIntervalSince1970:feed.latestRenderableObjTime];
             
            //[[cell detailTextLabel] setText: timestamp];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            return cell;
        }
    }
    
    return nil;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
    switch (section) {
        case 0:
            return @"Profile";
        case 1:
            return @"Actions";
        case 2:
            return @"Conversations";
    }
    
    return nil;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            break;
        }
        case 1: {
            [_delegate newConversation:_identity];
            break;
        }
        case 2: {
            MFeed* feed = [feeds objectAtIndex:indexPath.row];
            [_delegate selectedFeed:feed];
            break;
        }
    }
}

@end
