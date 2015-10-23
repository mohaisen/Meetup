//
//  RootViewController.m
//  meetup5
//
//  Created by Denis on 10/22/10.
//  Copyright 2010 Scientist of Fortune. All rights reserved.
//

#import "RootViewController.h"

#define kPeerSessionID @"gkpeer"

@implementation RootViewController

@synthesize sessionID;
@synthesize state;
@synthesize receivedFilename;
@synthesize status;
@synthesize peerSession;
@synthesize deviceArray;
@synthesize managedObjectContext;


#pragma mark -
#pragma mark Peer Picker Related Methods

-(void)startPicker {
	GKPeerPickerController*		picker;
    
	picker = [[GKPeerPickerController alloc] init]; // note: picker is released in various picker delegate methods when picker use is done.
	picker.delegate = self;
	[picker show]; // show the Peer Picker
}

#pragma mark GKPeerPickerControllerDelegate Methods

- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker { 
	// Peer Picker automatically dismisses on user cancel. No need to programmatically dismiss.
    
	// autorelease the picker. 
	picker.delegate = nil;
    [picker autorelease]; 
} 

/*
 *	Note: No need to implement -peerPickerController:didSelectConnectionType: delegate method since this app does not support multiple connection types.
 *		- see reference documentation for this delegate method and the GKPeerPickerController's connectionTypesMask property.
 */

//
// Provide a custom session that has a custom session ID. This is also an opportunity to provide a session with a custom display name.
//
- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type { 
	GKSession *session = [[GKSession alloc] initWithSessionID:kPeerSessionID displayName:nil sessionMode:GKSessionModePeer]; 
	return [session autorelease]; // peer picker retains a reference, so autorelease ours so we don't leak.
}

- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session { 
	// Remember the current peer.
	self.sessionID = peerID;  // copy
    status.text = peerID;  // Display the ID in the status
    
    // Peer network session with a remote node.
    // Once we hear from them, we set up the connection here.
    self.peerSession = session;
    self.peerSession.delegate = self;
    [self.peerSession setDataReceiveHandler:self withContext:NULL];
    
    
	// Done with the Peer Picker so dismiss it.
	[picker dismiss];
	picker.delegate = nil;
	[picker autorelease];
	
} 



- (IBAction) findpeers:(id)sender{
    //self.string = @"Finding peers...";
    //textField.text = self.string;
    [self startPicker];
    self.state = @"Idle";
    
}



- (IBAction) advertise:(id)sender{
    
    // Sends out all 3 files in the ~/smash/self directory
    //unsigned char stuff[20000];// TODO:  Fix this
    
    // Specifies the directory
    NSString * theFolder = [[NSString alloc] initWithFormat:@"/var/mobile/smash/self" ];//[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    // Counts the number of files in the directory to generate the test number
    //NSError *error = [NSError defaultError];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray * filesInFolderStringArray = [fileManager contentsOfDirectoryAtPath:theFolder error:NULL];
    
    // Checks if we have everything we need to send out
    if (filesInFolderStringArray.count != 3) {
        // TODO:  Notify the user that the information was not sent
        return;// There's something wrong with our identity directory, bail out of here
    }

    // --------------------------------------------------------
    // Loads and sends the first file (the cert)

    // Send the filename
    NSString * theFileName = [filesInFolderStringArray objectAtIndex:0];
    NSData * theData = [NSData dataWithBytes:[theFileName UTF8String] length:[theFileName length]];
    //[self sendNetworkPacket:peerSession packetID:0 withData:theData ofLength:[theData length] ];
    [self.peerSession sendData:theData toPeers:[NSArray arrayWithObject:self.sessionID] withDataMode:GKSendDataUnreliable error:nil];

    // Loads and sends the first file (the cert)
    theFileName = [theFolder stringByAppendingPathComponent:[filesInFolderStringArray objectAtIndex:0]];
    theData = [fileManager contentsAtPath:theFileName];
    //[self sendNetworkPacket:peerSession packetID:1 withData:theData ofLength:[theData length] ];
    [peerSession sendData:theData toPeers:[NSArray arrayWithObject:sessionID] withDataMode:GKSendDataUnreliable error:nil];

    // Loads and sends the second file (the photo)
    theFileName = [theFolder stringByAppendingPathComponent:[filesInFolderStringArray objectAtIndex:1]];
    theData = [fileManager contentsAtPath:theFileName];
    //[self sendNetworkPacket:peerSession packetID:2 withData:theData ofLength:[theData length] ];
    [peerSession sendData:theData toPeers:[NSArray arrayWithObject:sessionID] withDataMode:GKSendDataUnreliable error:nil];

    // Loads and sends the third file (the signature)
    theFileName = [theFolder stringByAppendingPathComponent:[filesInFolderStringArray objectAtIndex:2]];
    theData = [fileManager contentsAtPath:theFileName];
    //[self sendNetworkPacket:peerSession packetID:3 withData:theData ofLength:[theData length] ];
    [peerSession sendData:theData toPeers:[NSArray arrayWithObject:sessionID] withDataMode:GKSendDataUnreliable error:nil];
    
    // Clean up -- causes some crashes right now.
    //[theFileName release];
    //[theData release];
    
    // ----------------------------------------------------------
    
    self.state = @"Sent";
    
}



- (void)sendNetworkPacket:(GKSession *)session packetID:(int)packetID withData:(void *)data ofLength:(int)length {
	//static unsigned char networkPacket[20000];// TODO:  avoid statically allocated buffers
	//const unsigned int packetHeaderSize = sizeof(int); // We can use a 1 int header to make the transfer more robust...eventually
    
    //memcpy( networkPacket, packetID, packetHeaderSize ); 
    //memcpy( networkPacket, data, length ); // If we use a header, shift this appropriately to avoid stomping on the header
    
    //NSData *packet = [NSData dataWithBytes: networkPacket length: (length+sizeof(int))];
    //NSData *packet = [NSData dataWithBytes: networkPacket length: length];
    NSData *packet = [NSData dataWithBytes: data length: length];
    [session sendData:packet toPeers:[NSArray arrayWithObject:sessionID] withDataMode:GKSendDataUnreliable error:nil];
    
}


- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context { 
    
    // We are receiving 4 packets
    // 1) The file name, which is also the nickname of the device
    // 2) The certificate data
    // 3) The photo
    // 4) The signature that the photo is real
    
    //NSString * theFolder = [[NSString alloc] initWithFormat:@"/var/mobile/smash/devices" ];
    NSString * theFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    //unsigned char *incomingPacket = (unsigned char *)[data bytes];
    //int incomingPacketLen = data.length;
    
    // TODO: for now, we rely on the order that the files were sent in
    //       For a more robust mechanism, we can use the packet ID
    
    if ([self.state compare:@"Idle"] == NSOrderedSame) {
        // This is the first transmission
        // It's the filename
        self.receivedFilename = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        
        self.state = @"Got filename";
    } else if ([self.state compare:@"Got filename"] == NSOrderedSame) {
        // This is the second transmission
        // It's the certificate
        NSString *theFileName = [theFolder stringByAppendingPathComponent:self.receivedFilename];
        [data writeToFile:theFileName atomically:FALSE];
        
        self.state = @"Got certificate";
    } else if ([self.state compare:@"Got certificate"] == NSOrderedSame) {
        // This is the third transmission
        // It's the photo
        NSString *theFileName = [theFolder stringByAppendingPathComponent:[[NSString alloc] initWithFormat:@"%@.jpg",self.receivedFilename]];
        [data writeToFile:theFileName atomically:FALSE];
                
        self.state = @"Got photo";
    } else if ([self.state compare:@"Got photo"] == NSOrderedSame) {
        // This is the fourth transmission
        // It's the signature
        NSString *theFileName = [theFolder stringByAppendingPathComponent:[[NSString alloc] initWithFormat:@"%@.signed",self.receivedFilename]];
        [data writeToFile:theFileName atomically:FALSE];
        
        
        self.state = @"Idle";
    }
    
    
    
    /*    
    if ([self.state compare:@"Sent"] == NSOrderedSame) {
                        
        //NSString *filemessage = [[NSString alloc] initWithFormat:@"Bytes received: %d", incomingPacketLen];
        //status.text = filemessage;
        //[filemessage release];
        self.state = @"Idle";
        
    }else {
        NSString *filemessage = [[NSString alloc] initWithFormat:@"Bytes received: %d, sending ACK.", incomingPacketLen];
        status.text = filemessage;
        [filemessage release];
        unsigned char stuff[20];
        [self sendNetworkPacket:peerSession packetID:0 withData:&stuff ofLength:20 ];
    }
    */
    
}


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
	/*
	 Fetch previously seen devices.
	 Create a fetch request, add a sort descriptor, then execute the fetch.
	 */
    /*
    
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Device" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	// Order the events by creation date, most recent first.
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nickName" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	[sortDescriptor release];
	[sortDescriptors release];
	
	// Execute the fetch -- create a mutable copy of the result.
	NSError *error = nil;
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil) {
		// Handle the error.
	}
	
	// Set self's events array to the mutable array, then clean up.
	[self setEventsArray:mutableFetchResults];
	[mutableFetchResults release];
	[request release];
    */
}


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */


#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    //retrieve the number of devices seen here
    // Specifies the directory
    NSString * theFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    // NSString * theFolder = [[NSString alloc] initWithFormat:@"/var/mobile/smash/devices" ];//[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    // Counts the number of files in the directory to generate the test number
    //NSError *error = [NSError defaultError];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray * filesInFolderStringArray = [fileManager contentsOfDirectoryAtPath:theFolder error:NULL];
    int numDevices = filesInFolderStringArray.count/3;


    //[theFolder release];
    //[fileManager release];
    //[filesInFolderStringArray release];
    
    
    return numDevices;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
  
    // Get the appropriate filenames to display
    // Specifies the directory
    NSString * theFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    //NSString * theFolder = [[NSString alloc] initWithFormat:@"/var/mobile/smash/devices" ];//[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    // Counts the number of files in the directory to generate the test number
    //NSError *error = [NSError defaultError];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray * filesInFolderStringArray = [fileManager contentsOfDirectoryAtPath:theFolder error:NULL];

    // configure the cell
    cell.textLabel.text = [filesInFolderStringArray objectAtIndex:(indexPath.row*3)];
    cell.imageView.image = [UIImage imageWithContentsOfFile:[theFolder stringByAppendingPathComponent:[filesInFolderStringArray objectAtIndex:(1 + (indexPath.row * 3))]]];
    
    /*
    // Old hack-------------------------
    // Configure the cell.
    switch (indexPath.row) {
        case 2:
            cell.textLabel.text = [NSString stringWithFormat:@"R2"];
            cell.imageView.image = [UIImage imageWithContentsOfFile:@"/var/mobile/smash/r2.jpg"];
            break;
        case 1:
            cell.textLabel.text = [NSString stringWithFormat:@"geekPhone"];
            cell.imageView.image = [UIImage imageWithContentsOfFile:@"/var/mobile/smash/geekPhone.jpg"];
            break;
        case 0:
            cell.textLabel.text = [NSString stringWithFormat:@"R3x"];
            cell.imageView.image = [UIImage imageWithContentsOfFile:@"/var/mobile/smash/r3x.jpg"];
            break;
        default:
            cell.textLabel.text = [NSString stringWithFormat:@"Row %d", indexPath.row];
            break;
    }
    // End old hack----------------------
     */
    
    
    //[theFolder release];
    //[fileManager release];
    //[filesInFolderStringArray release];
    
    // Return the name of each user (or device) as received here
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end

