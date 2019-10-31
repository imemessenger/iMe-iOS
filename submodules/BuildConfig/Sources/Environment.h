//
//  Environment.h
//  BuildConfig
//
//  Created by Valeriy Mikholapov on 09/09/2019.
//  Copyright © 2019 Telegram LLP. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Environment : NSObject

+ (Environment * _Nonnull)sharedInstance;

@property (nonatomic, readonly) int32_t apiId;
@property (nonatomic, readonly, nonnull) NSString *apiHash;
@property (nonatomic, readonly, nonnull) NSString *hockeyAppId;

@end

NS_ASSUME_NONNULL_END
