//
//  DLNViewController.m
//  DLNWiFiDetector
//
//  Created by Daniel on 08/22/2016.
//  Copyright (c) 2016 Daniel. All rights reserved.
//

#import "DLNViewController.h"
#import <DLNWiFiDetector/DLNWiFiDetector.h>

@interface DLNViewController () <DLNWiFiDetectorDelegate>
@property (weak, nonatomic) IBOutlet UILabel *hostLabel;
@property (weak, nonatomic) IBOutlet UILabel *ipLabel;
@property (weak, nonatomic) IBOutlet UILabel *macLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searchIndicator;

@property (nonatomic, strong) DLNWiFiDetector *detector;
@end

@implementation DLNViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.detector = [[DLNWiFiDetector alloc] init];
    
    self.macLabel.text = @"MAC: searching...";
    [self.searchIndicator startAnimating];
    __weak __typeof(self)weakSelf = self;
    [self.detector searchMacOnResult:^(NSString *mac) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf.macLabel.text = [NSString stringWithFormat:@"MAC: %@", mac];
        [strongSelf.searchIndicator stopAnimating];
    }];
    
    NSString *ip = [self.detector getOwnIp];
    self.ipLabel.text = [NSString stringWithFormat:@"IP: %@", ip];
    
    NSString *host = [self.detector searchHostByIp:ip];
    self.hostLabel.text = [NSString stringWithFormat:@"HOST: %@", host];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - DLNWiFiDetectorDelegate
- (void)wifiDetectorSearchOutIP:(NSString *)ip withHost:(NSString *)host {
    NSLog(@"%s, ip: %@, host: %@", __FUNCTION__, ip, host);
}

- (void)wifiDetectorSearchFinished {
    NSLog(@"%s", __FUNCTION__);
}
@end
