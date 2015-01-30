//
//  OSSyncManager.m
//  OneScreen
//
//  Created by Xiaoxue Han on 1/28/15.
//  Copyright (c) 2015 wagnermeter. All rights reserved.
//

#import "OSSyncManager.h"
#import "OSServerManager.h"
#import "OSModelManager.h"

static OSSyncManager *_sharedSyncManager = nil;

@interface OSSyncManager ()

@property (nonatomic, retain) NSMutableArray *queue;
@property (nonatomic, retain) NSThread *thread;
@property (nonatomic) BOOL done;
@property (nonatomic, strong) NSLock *lock;

@end

@implementation OSSyncManager

+ (OSSyncManager *)sharedInstance {
    if (_sharedSyncManager == nil) {
        _sharedSyncManager = [[OSSyncManager alloc] init];
    }
    return _sharedSyncManager;
}

- (id)init {
    self = [super init];
    if (self) {
        self.queue = [[NSMutableArray alloc] init];
        self.done = NO;
        self.lock = [[NSLock alloc] init];
        self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(run:) object:nil];
        [self.thread start];
    }
    return self;
}

- (void)addCalcheckToSyncList:(CDCalCheck *)calCheck {
    if (calCheck == nil)
        return;
    
    [self.lock lock];
    [self.queue addObject:calCheck];
    [self.lock unlock];
}

- (void)run:(id)obj {
    while (!self.done) {
        if ([[OSServerManager sharedInstance] hasConnectivity]) {
            [self.lock lock];
            // get a cal check from the list
            CDCalCheck *calCheck = nil;
            if (self.queue.count == 0) {
                calCheck = nil;
            }
            else {
                calCheck = [self.queue objectAtIndex:0];
                [self.queue removeObject:calCheck];
            }
            if (calCheck == nil) {
                [NSThread sleepForTimeInterval:2.0f];
            }
            else {
                CDCalCheck *finalCalCheck = calCheck;
                // try to store this cal check on server
                NSLog(@"storing cal check : %@ (%@)", finalCalCheck.ssn, finalCalCheck.date);
                
                [[OSServerManager sharedInstance] storeCalCheck:finalCalCheck.ssn rh:[finalCalCheck.rh floatValue] temp:[finalCalCheck.temp floatValue] salt_name:finalCalCheck.salt_name date:finalCalCheck.date complete:^(BOOL success) {
                    if (success) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [[OSModelManager sharedInstance] setStoredOnServerForCalCheck:finalCalCheck stored_on_server:YES];
                        }];
                    }
                    else {
                        // add it to last one of the queue
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [self addCalcheckToSyncList:finalCalCheck];
                        }];
                    }
                }];
                
                [NSThread sleepForTimeInterval:2.0f];
            }
            [self.lock unlock];
        }
        else {
            [NSThread sleepForTimeInterval:2.0f];
        }
    }
}

@end
