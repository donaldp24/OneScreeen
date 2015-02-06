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



@implementation SensorDataWithSaltName

- (BOOL)isEqual:(id)object {
    if ([super isEqual:object])
        return YES;
    
    SensorDataWithSaltName *b = (SensorDataWithSaltName *)object;
    if (b == nil || ![b isKindOfClass:[SensorDataWithSaltName class]])
        return NO;
    
    if ([b.ssn isEqualToString:self.ssn] &&
        [b.date compare:self.date] == NSOrderedSame)
        return YES;
    return NO;
}

@end

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

- (void)addCalcheckToSyncList:(NSString *)ssn rh:(float)rh temp:(float)temp salt_name:(NSString *)salt_name date:(NSDate *)date {
    [self.lock lock];
    SensorDataWithSaltName *entry = [[SensorDataWithSaltName alloc] init];
    if (![self.queue containsObject:entry])
        [self.queue addObject:entry];
    [self.lock unlock];
}

- (void)run:(id)obj {
    while (!self.done) {
        if ([[OSServerManager sharedInstance] hasConnectivity] &&
            [[OSServerManager sharedInstance] isLoggedIn]) {
            
            [self.lock lock];
            // get a cal check from the list
            SensorDataWithSaltName *entry = nil;
            if (self.queue.count == 0) {
                entry = nil;
            }
            else {
                entry = [self.queue objectAtIndex:0];
                [self.queue removeObject:entry];
            }
            
            if (entry == nil) {
                [NSThread sleepForTimeInterval:2.0f];
            }
            else {
                // try to store this cal check on server
                NSLog(@"storing cal check : %@ (%@)", entry.ssn, entry.date);
                
                [[OSServerManager sharedInstance] storeCalCheck:entry.ssn
                                                             rh:entry.rh
                                                           temp:entry.temp
                                                      salt_name:entry.salt_name
                                                           date:entry.date
                                                       complete:^(BOOL success, ErrorType errorType) {
                    if (success) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [[OSModelManager sharedInstance] setStoredOnServerForSensor:entry.ssn date:entry.date stored_on_server:YES];
                        }];
                    }
                    else {
                        // add it to last one of the queue
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [self addCalcheckToSyncList:entry.ssn rh:entry.rh temp:entry.temp salt_name:entry.salt_name date:entry.date];
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
