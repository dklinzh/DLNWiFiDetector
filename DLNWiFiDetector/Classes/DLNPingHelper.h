//
//  DLNPingHelper.h
//  Pods
//
//  Created by Linzh on 8/30/16.
//  Copyright © 2016 Daniel. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^DLNPingResultBlock)(BOOL responded);

@interface DLNPingHelper : NSObject

- (void)pingAddress:(NSString *)address onResult:(DLNPingResultBlock)block;
@end
