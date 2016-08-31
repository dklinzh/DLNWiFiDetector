//
//  DLNWiFiDetector.h
//  Pods
//
//  Created by Linzh on 8/24/16.
//  Copyright © 2016 Daniel. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DLNWiFiDetectorDelegate <NSObject>

@optional
- (void)wifiDetectorSearchOutIP:(NSString *)ip withHost:(NSString *)host;
- (void)wifiDetectorSearchFinished;

@end

typedef void(^DLNSearchResultBlock)(NSString *mac);

@interface DLNWiFiDetector : NSObject
@property (nonatomic, weak) id<DLNWiFiDetectorDelegate> delegate;

- (NSDictionary *)currentNetworkInfo;

- (NSString *)getRouteIp;

- (NSString *)getOwnIp;

- (NSString *)searchMacByIp:(NSString *)ip;

- (NSString *)searchHostByIp:(NSString *)ip;

- (void)startScanning;

- (void)stopScanning;

- (void)searchMacOnResult:(DLNSearchResultBlock)block;

@end
