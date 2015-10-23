//
//  meetup5AppDelegate.h
//  meetup5
//
//  Created by Denis on 10/22/10.
//  Copyright 2010 Scientist of Fortune. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface meetup5AppDelegate : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    UINavigationController *navigationController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

-(IBAction) findPeers:(id)sender;

@end

