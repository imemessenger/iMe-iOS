//
//  Environment.m
//  BuildConfig
//
//  Created by Valeriy Mikholapov on 09/09/2019.
//  Copyright © 2019 Telegram LLP. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Environment.h"

@implementation Environment

static Environment * shared;

+ (Environment * _Nonnull)sharedInstance {
    if (shared == nil) {
        shared = [[Environment alloc] init];
    }
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadConfig];
    }
    return self;
}

- (void)loadConfig {
    NSURL *envUrl = [[NSBundle mainBundle] URLForResource:@"Environment" withExtension:@"plist"];
    NSDictionary<NSString*, NSString*> *dict = [[NSMutableDictionary alloc] initWithContentsOfURL:envUrl];

    if (dict[@"APP_CONFIG_API_ID"] == nil || dict[@"APP_CONFIG_API_HASH"] == nil || dict[@"APP_CONFIG_HOCKEYAPP_ID"] == nil) {
        NSMutableString *errorDescription = [NSMutableString new];
        [errorDescription appendString:@"Failed to load one or more values from Environment.plist file. "];
        [errorDescription appendString:@"'APP_CONFIG_API_ID', 'APP_CONFIG_API_HASH', 'APP_CONFIG_HOCKEYAPP_ID' keys must be provided."];

        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                        reason:errorDescription
                                      userInfo:nil];
    }

    _apiId = dict[@"APP_CONFIG_API_ID"].intValue;
    _apiHash = dict[@"APP_CONFIG_API_HASH"];
    _hockeyAppId = dict[@"APP_CONFIG_HOCKEYAPP_ID"];
}

@end
