//
//  RootViewController.h
//  meetup5
//
//  Created by Denis on 10/22/10.
//  Copyright 2010 Scientist of Fortune. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import <CoreData/CoreData.h>

@interface RootViewController : UITableViewController <GKPeerPickerControllerDelegate, GKSessionDelegate>{
    NSString *sessionID;
    NSString *state;
    NSString *receivedFilename;
    UILabel *status;
	GKSession *peerSession;    
    
    NSMutableArray *deviceArray;
    NSManagedObjectContext *managedObjectContext;	    

}

@property (nonatomic, copy) NSString *sessionID;
@property (nonatomic, copy) NSString *receivedFilename;
@property (nonatomic, copy) NSString *state;
@property (nonatomic, retain) IBOutlet UILabel *status;
@property (nonatomic, retain) GKSession	 *peerSession;
@property (nonatomic, retain) NSMutableArray *deviceArray;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;	    


-(IBAction) findpeers:(id)sender;
-(IBAction) advertise:(id)sender;
-(void)sendNetworkPacket:(GKSession *)session packetID:(int)packetID withData:(void *)data ofLength:(int)length;

@end
