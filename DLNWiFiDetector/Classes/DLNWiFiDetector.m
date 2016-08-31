//
//  DLNWiFiDetector.m
//  Pods
//
//  Created by Linzh on 8/24/16.
//  Copyright © 2016 Daniel. All rights reserved.
//

#import "DLNWiFiDetector.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <ifaddrs.h>
#import "DLNPingHelper.h"

#import <sys/param.h>
#import <sys/file.h>
#import <sys/socket.h>
#import <sys/sysctl.h>

#import <net/if.h>
#import <net/if_dl.h>

#if (TARGET_IPHONE_SIMULATOR)
#import <net/if_types.h>
#import <net/route.h>
#import <netinet/if_ether.h>
#else
#import "if_types.h"
#import "route.h"
#import "if_ether.h"
#endif

#import <netinet/in.h>

#import <arpa/inet.h>

#import <err.h>
#import <errno.h>
#import <netdb.h>
#import <paths.h>
#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import <unistd.h>

#define ROUNDUP(a) ((a) > 0 ? (1 + (((a) - 1) | (sizeof(long) - 1))) : sizeof(long))

@interface DLNWiFiDetector () <DLNWiFiDetectorDelegate>
@property (nonatomic, strong) NSString *netMask;
@property (nonatomic, strong) NSString *baseAddress;
@property (nonatomic, assign) NSInteger currentHostAddress;
@property (nonatomic, assign) NSInteger baseAddressEnd;
@property (nonatomic, strong) NSTimer *pingTimer;
@property (nonatomic, assign) NSInteger timerCount;
@property (nonatomic, copy) DLNSearchResultBlock searchResultBlock;
@end

@implementation DLNWiFiDetector

#pragma mark - DLNWiFiDetectorDelegate
- (void)wifiDetectorSearchOutIP:(NSString *)ip withHost:(NSString *)host {
}

- (void)wifiDetectorSearchFinished {
    NSLog(@"%s %@", __FUNCTION__, [NSThread currentThread]);
    NSString *mac = [self searchMacByIp:[self getOwnIp]];
    if (self.searchResultBlock) {
        self.searchResultBlock(mac);
    }
}

#pragma mark - Public

- (void)searchMacOnResult:(DLNSearchResultBlock)block {
    self.searchResultBlock = block;
    
    self.delegate = self;
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"%s %@", __FUNCTION__, [NSThread currentThread]);
        [self startScanning];
//    });
}

- (void)startScanning {
    NSLog(@"%s", __FUNCTION__);
    
    NSString *ip = [self getOwnIp];
    if (!ip || !self.netMask) {
        if ([self.delegate respondsToSelector:@selector(wifiDetectorSearchFinished)]) {
            [self.delegate wifiDetectorSearchFinished];
        }
        return;
    }
    NSArray<NSString *> *p1 = [ip componentsSeparatedByString:@"."];
    NSArray<NSString *> *p2 = [self.netMask componentsSeparatedByString:@"."];
    for (int i = 0; i<p1.count; i++) {
        long and = p1[i].integerValue & p2[i].integerValue;
        if (!self.baseAddress.length) {
            self.baseAddress = [NSString stringWithFormat:@"%ld", and];
        } else {
            self.baseAddress = [self.baseAddress stringByAppendingFormat:@".%ld", and];
            self.currentHostAddress = and;
            self.baseAddressEnd = and;
        }
    }
    self.pingTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(ping) userInfo:nil repeats:YES];
}

- (void)stopScanning {
    NSLog(@"%s", __FUNCTION__);
    
    [self.pingTimer invalidate];
}

- (void)ping {
    self.currentHostAddress++;
    NSLog(@"ping: %@, host: %ld", self.baseAddress, (long)self.currentHostAddress);
    NSString *address = [self.baseAddress stringByAppendingFormat:@"%ld", (long)self.currentHostAddress];
    __weak __typeof(self)weakSelf = self;
    [[DLNPingHelper alloc] pingAddress:address onResult:^(BOOL responded) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf.timerCount++;
        if (responded) {
            NSString *ip = [[[address stringByReplacingOccurrencesOfString:@".0" withString:@"."] stringByReplacingOccurrencesOfString:@".00" withString:@"."] stringByReplacingOccurrencesOfString:@".." withString:@".0."];
            NSString *host = [strongSelf searchHostByIp:address];
            if ([strongSelf.delegate respondsToSelector:@selector(wifiDetectorSearchOutIP:withHost:)]) {
                [strongSelf.delegate wifiDetectorSearchOutIP:ip withHost:host];
            }
            if (strongSelf.timerCount + strongSelf.baseAddressEnd >= 254) {
                if ([strongSelf.delegate respondsToSelector:@selector(wifiDetectorSearchFinished)]) {
                    [strongSelf.delegate wifiDetectorSearchFinished];
                }
            }
        }
    }];
    
    if (self.currentHostAddress >= 254) {
        [self stopScanning];
    }
}

- (NSString *)searchHostByIp:(NSString *)ip {
    const char *ipAddress = [ip cStringUsingEncoding:NSASCIIStringEncoding];
    
    NSString *host = nil;
    int error;
    struct addrinfo *results = NULL;
    
    error = getaddrinfo(ipAddress, NULL, NULL, &results);
    if (error != 0) {
        NSLog (@"can not get any info of the ip address");
        return nil;
    }
    
    for (struct addrinfo *r = results; r; r = r->ai_next) {
        char hostname[NI_MAXHOST] = {0};
        error = getnameinfo(r->ai_addr, r->ai_addrlen, hostname, sizeof hostname, NULL, 0 , 0);
        if (error != 0) {
            continue;
        } else {
            NSLog (@"host: %s", hostname);
            host = [NSString stringWithFormat:@"%s", hostname];
            freeaddrinfo(results);
            break;
        }
    }
    
    return host;
}

- (NSString *)searchMacByIp:(NSString *)ip {
    NSString *ret = nil;
    in_addr_t addr = inet_addr(ip.UTF8String);
    NSLog(@"addr: %u", addr);
    
    size_t needed;
    char *buf, *next;
    
    struct rt_msghdr *rtm;
    struct sockaddr_inarp *sin;
    struct sockaddr_dl *sdl;
    
    int mib[6];
    
    mib[0] = CTL_NET;
    mib[1] = PF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_INET;
    mib[4] = NET_RT_FLAGS;
    mib[5] = RTF_LLINFO;
    
    if (sysctl(mib, sizeof(mib) / sizeof(mib[0]), NULL, &needed, NULL, 0) < 0)
        err(1, "route-sysctl-estimate");
    
    if ((buf = (char*)malloc(needed)) == NULL)
        err(1, "malloc");
    
    if (sysctl(mib, sizeof(mib) / sizeof(mib[0]), buf, &needed, NULL, 0) < 0)
        err(1, "retrieval of routing table");
    
    for (next = buf; next < buf + needed; next += rtm->rtm_msglen) {
        
        rtm = (struct rt_msghdr *)next;
        sin = (struct sockaddr_inarp *)(rtm + 1);
        sdl = (struct sockaddr_dl *)(sin + 1);
        
        NSLog(@"sin_addr.s_addr: %u", sin->sin_addr.s_addr);
        if (addr != sin->sin_addr.s_addr || sdl->sdl_alen < 6) {
            continue;
        }
        
        u_char *cp = (u_char*)LLADDR(sdl);
        
        ret = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
               cp[0], cp[1], cp[2], cp[3], cp[4], cp[5]];
        NSLog(@"mac: %@, ip: %s", ret, inet_ntoa(sin->sin_addr));
        break;
    }
    
    free(buf);
    
    NSLog(@"MAC: %@", ret);
    return ret;
}

- (NSString *)getRouteIp {
    NSString* res = nil;
    
    size_t needed;
    char *buf, *next;
    
    struct rt_msghdr *rtm;
    struct sockaddr * sa;
    struct sockaddr * sa_tab[RTAX_MAX];
    int i = 0;
    
    int mib[] = {CTL_NET, PF_ROUTE, 0, AF_INET, NET_RT_FLAGS, RTF_GATEWAY};
    
    if (sysctl(mib, sizeof(mib) / sizeof(mib[0]), NULL, &needed, NULL, 0) < 0)
    {
        NSLog(@"error in route-sysctl-estimate");
        return nil;
    }
    
    if ((buf = (char*)malloc(needed)) == NULL)
    {
        NSLog(@"error in malloc");
        return nil;
    }
    
    if (sysctl(mib, sizeof(mib) / sizeof(mib[0]), buf, &needed, NULL, 0) < 0)
    {
        NSLog(@"retrieval of routing table");
        return nil;
    }
    
    for (next = buf; next < buf + needed; next += rtm->rtm_msglen)
    {
        rtm = (struct rt_msghdr *)next;
        sa = (struct sockaddr *)(rtm + 1);
        for(i = 0; i < RTAX_MAX; i++)
        {
            if(rtm->rtm_addrs & (1 << i))
            {
                sa_tab[i] = sa;
                sa = (struct sockaddr *)((char *)sa + ROUNDUP(sa->sa_len));
            }
            else
            {
                sa_tab[i] = NULL;
            }
        }
        
        if(((rtm->rtm_addrs & (RTA_DST|RTA_GATEWAY)) == (RTA_DST|RTA_GATEWAY))
           && sa_tab[RTAX_DST]->sa_family == AF_INET
           && sa_tab[RTAX_GATEWAY]->sa_family == AF_INET)
        {
            if(((struct sockaddr_in *)sa_tab[RTAX_DST])->sin_addr.s_addr == 0)
            {
                char ifName[128];
                if_indextoname(rtm->rtm_index,ifName);
                
                if(strcmp("en0",ifName) == 0)
                {
                    struct in_addr temp;
                    temp.s_addr = ((struct sockaddr_in *)(sa_tab[RTAX_GATEWAY]))->sin_addr.s_addr;
                    res = [NSString stringWithUTF8String:inet_ntoa(temp)];
                }
            }
        }
    }
    
    free(buf);
    
    NSLog(@"Route IP: %@", res);
    return res;
}

- (NSString *)getOwnIp {
    NSString *address = nil;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"] || [[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"pdp_ip0"]) {
//                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    self.netMask = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    
    NSLog(@"Self IP: %@", address);
    return address;
}

- (NSDictionary *)currentNetworkInfo {
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    NSDictionary * info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        NSLog(@"%@ => %@", ifnam, info);
        if (info && [info count]) { break; }
    }
    return info;
}

- (BOOL)isWiFiConnected {
    return [[self currentNetworkInfo] objectForKey:@"SSID"] ? YES : NO;
}
@end
