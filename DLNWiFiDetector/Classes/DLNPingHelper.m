//
//  DLNPingHelper.m
//  Pods
//
//  Created by Linzh on 8/30/16.
//  Copyright © 2016 Daniel. All rights reserved.
//

#import "DLNPingHelper.h"
#import "SimplePing.h"

@interface DLNPingHelper () <SimplePingDelegate>
@property (nonatomic, strong) SimplePing *simplePing;
@property (nonatomic, copy) DLNPingResultBlock pingResultBlock;

@end

@implementation DLNPingHelper
#pragma mark - Public
- (void)pingAddress:(NSString *)address onResult:(DLNPingResultBlock)block {
    self.pingResultBlock = block;
    
    self.simplePing = [[SimplePing alloc] initWithHostName:address];
    self.simplePing.delegate = self;
//    self.simplePing.addressStyle = SimplePingAddressStyleAny;
    [self.simplePing start];
    
    [self performSelector:@selector(stopPingInResult:) withObject:@(NO) afterDelay:1]; //ping timeout
}

#pragma mark - Private
- (void)stopPingInResult:(BOOL)responded {
    if (self.simplePing) {
        [self.simplePing stop];
        self.simplePing = nil;
        if (self.pingResultBlock) {
            self.pingResultBlock(responded);
        }
    }
}

#pragma mark - SimplePingDelegate
- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address {
    [self.simplePing sendPingWithData:nil];
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
    
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error {
    [self stopPingInResult:NO];
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(nonnull NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
    [self stopPingInResult:YES];
}

- (void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet {
    [self stopPingInResult:NO];
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error {
    [self stopPingInResult:NO];
}
@end
