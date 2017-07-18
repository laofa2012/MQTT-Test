//
//  ViewController.m
//  MQTTTest
//
//  Created by Faney on 16/12/3.
//  Copyright © 2016年 honeywell. All rights reserved.
//

#import "ViewController.h"
#import "MQTTKit.h"

//#define kMQTTServerHost @"iot.dressmedical.com"
//#define kMQTTServerHost @"iot.eclipse.org"
#define kMQTTServerHost @"192.168.8.101"

#define Client_Topic_Verify @"airclean"
#define Client_Topic_Report @"airquality"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *pushMessage;
@property (nonatomic, strong) MQTTClient *client;

@property (nonatomic, strong) NSString *deviceID;
@property (nonatomic, strong) NSString *longitude;
@property (nonatomic, strong) NSString *latitude;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *clientID = [UIDevice currentDevice].identifierForVendor.UUIDString;
    clientID = @"DGJFT00000001000000";
    NSLog(@"clientID:%@", clientID);
    self.client = [[MQTTClient alloc] initWithClientId:clientID];
    self.client.port = 1883;
//    self.client.username = @"Dgj2016";
//    self.client.password = @"Dgj2016pw";
    
    self.deviceID = @"DGJJQ00000001";
    self.longitude = @"121.76";
    self.latitude = @"31.05";
}

// 订阅
- (void)startSubscribeTopic
{
    [self.client subscribe:Client_Topic_Verify withCompletionHandler:^(NSArray *grantedQos) {
        NSLog(@"订阅%@:%@", Client_Topic_Verify, grantedQos);
    }];
    
    [self.client subscribe:Client_Topic_Report withCompletionHandler:^(NSArray *grantedQos) {
        NSLog(@"订阅%@:%@", Client_Topic_Report, grantedQos);
    }];
}

// 监听数据
- (void)startListen
{
    [self.client setMessageHandler:^(MQTTMessage* message)
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             NSLog(@"接收到数据%@:%@", message.topic, message.payloadString);
         });
     }];
}

- (IBAction)verify
{
    NSString* payload = [NSString stringWithFormat:@"%@|%@|%@", self.deviceID, self.longitude, self.latitude];
    [self.client publishString:payload
                       toTopic:Client_Topic_Verify
                       withQos:AtMostOnce
                        retain:YES
             completionHandler:nil];
    NSLog(@"verify：%@",payload);
}

- (IBAction)report
{
    NSString *time = @"30";             // 0 ~ 30
    NSString *dianzhi = @"10";          // 0 ~ 10
    NSString *diandao = @"20";          // 0 ~ 20
    NSString *hz = @"8";                // 1 ~ 8
    NSString *chaosheng = @"10";        // 0 ~ 10
    
    NSString* payload = [NSString stringWithFormat:@"%@|%@|%@|%@|%@|%@|%@|%@", self.deviceID, self.longitude, self.latitude, time, dianzhi, diandao, hz, chaosheng];
    [self.client publishString:payload
                       toTopic:Client_Topic_Report
                       withQos:AtMostOnce
                        retain:YES
             completionHandler:nil];
    NSLog(@"report：%@",payload);
}

- (IBAction)connect
{
    [self.client connectToHost:kMQTTServerHost completionHandler:^(MQTTConnectionReturnCode code) {
        if (code == ConnectionAccepted)
        {
            NSLog(@"登录服务器成功");
            
            // 订阅
            [self startSubscribeTopic];
            
            // 监听数据
            [self startListen];
        }
        else
        {
            NSLog(@"登录服务器出错了 code-->%ld",code);
        }
    }];
}

- (IBAction)disconnect
{
    [self.client disconnectWithCompletionHandler:^(NSUInteger code) {
        NSLog(@"MQTT client is disconnected");
    }];
    
    NSLog(@"disconnected");
}

@end
