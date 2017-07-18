//
//  ViewController.m
//  MQTTServer
//
//  Created by scinan on 15/10/16.
//  Copyright © 2015年 scinan. All rights reserved.
//

#import "ViewController.h"
#import "MQTTKit.h"

#define kMQTTServerHost @"iot.dressmedical.com"
//#define kMQTTServerHost @"iot.eclipse.org"

#define Client_Topic_Verify @"verify"
#define Client_Topic_Report @"report"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *pushMessage;
@property (nonatomic, strong) MQTTClient *client;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *clientID = @"DGJFT00000001000000";
    NSLog(@"clientID:%@", clientID);
    self.client = [[MQTTClient alloc] initWithClientId:clientID];
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
    NSString* payload = self.pushMessage.text;
    [self.client publishString:payload
                       toTopic:Client_Topic_Verify
                       withQos:AtMostOnce
                        retain:YES
             completionHandler:nil];
    NSLog(@"verify：%@",payload);
}

- (IBAction)report
{
    NSString* payload = self.pushMessage.text;
    [self.client publishString:payload
                       toTopic:Client_Topic_Report
                       withQos:AtMostOnce
                        retain:YES
             completionHandler:nil];
    NSLog(@"report：%@",payload);
}

- (IBAction)connect
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"服务器");
        [self.client connectToHost:kMQTTServerHost andName:@"Dgj2016" andPassword:@"Dgj2016pw" completionHandler:^(MQTTConnectionReturnCode code) {
            if (code == ConnectionAccepted)
            {
                NSLog(@"服务器启动成功");
                
                // 订阅
                //[self startSubscribeTopic];
                
                // 监听数据
                //[self startListen];
            }
            else
            {
                NSLog(@"出错了 code-->%ld",code);
            }
        }];
        NSLog(@"服务器111111");
    });
}

- (IBAction)disconnect
{
    [self.client disconnectWithCompletionHandler:^(NSUInteger code) {
        NSLog(@"MQTT client is disconnected");
    }];
    
    NSLog(@"disconnected");
}

@end
