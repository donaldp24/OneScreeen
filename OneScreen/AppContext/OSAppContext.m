//
//  OSAppContext.m
//  OneScreen
//
//  Created by Xiaoxue Han on 10/17/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSAppContext.h"
#import "OSModelManager.h"

static OSAppContext *_sharedAppContext = nil;

@interface OSAppContext ()

@end

@implementation OSAppContext

+ (OSAppContext *)sharedInstance
{
    if (_sharedAppContext == nil)
        _sharedAppContext = [[OSAppContext alloc] init];
    return _sharedAppContext;
}

- (id)init
{
    self = [super init];
    [self load];
    return self;
}

- (void)setIsJobStarted:(BOOL)isJobStarted
{
    _isJobStarted = isJobStarted;
    [self save];
}

- (void)setCurrentJob:(CDJob *)currentJob
{
    _currentJob = currentJob;
    [self save];
}

- (void)save
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:_isJobStarted forKey:@"isstarted"];
    if (_currentJob != nil)
        [userDefaults setObject:_currentJob.uid forKey:@"jobuid"];
    
    [userDefaults synchronize];
}

- (void)load
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *uid = [userDefaults objectForKey:@"jobuid"];
    if (uid == nil)
        _currentJob = nil;
    else
    {
        _currentJob = [[OSModelManager sharedInstance] getJobWithUid:uid];
    }
    
    _isJobStarted = [userDefaults boolForKey:@"isstarted"];
    
    if (_isJobStarted)
        _currentJob.isdeleted = @(NO);
}

@end
