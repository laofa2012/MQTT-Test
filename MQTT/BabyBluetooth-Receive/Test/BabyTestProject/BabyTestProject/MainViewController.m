//
//  MainViewController.m
//  BabyTestProject
//
//  Created by Faney on 16/11/1.
//  Copyright © 2016年 liuyanwei. All rights reserved.
//

#import "MainViewController.h"
#import "BabyBluetooth.h"
#import "SVProgressHUD.h"
#import "GCHDeviceCalculation.h"

#define MainPeripheralName @"HF-BL100-CL"
#define WriteCharacteristicUUID @"2B11"
#define ReadCharacteristicUUID @"2B10"

@interface MainViewController ()

@property (strong, nonatomic) BabyBluetooth *baby;

@property (strong, nonatomic) CBPeripheral *mainPeripheral;

@property (strong, nonatomic) CBCharacteristic *writeCharacteristic;

@property (strong, nonatomic) CBCharacteristic *readCharacteristic;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"BLE";
    
    float width = 200.0f;
    float height = 60.0f;
    UIButton *button = [[UIButton alloc] init];
    button.frame = CGRectMake((self.view.frame.size.width - width) / 2, (self.view.frame.size.height - height) / 2, width, height);
    [button addTarget:self action:@selector(sendAction) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Send" forState:UIControlStateNormal];
    button.backgroundColor = [UIColor blueColor];
    [self.view addSubview:button];
    
    // 初始化BabyBluetooth 蓝牙库
    _baby = [BabyBluetooth shareBabyBluetooth];
    //停止之前的连接
    [_baby cancelAllPeripheralsConnection];
    // 设置蓝牙委托
    [self babyDelegate];
    //设置委托后直接可以使用，无需等待CBCentralManagerStatePoweredOn状态。
    _baby.scanForPeripherals().begin();
    //baby.scanForPeripherals().begin().stop(10);
}

# pragma
# pragma - 蓝牙配置和操作

// 蓝牙网关初始化和委托方法设置
-(void)babyDelegate
{
    __weak typeof(self) weakSelf = self;
    [_baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        if (central.state == CBCentralManagerStatePoweredOn)
            NSLog(@"手机蓝牙状态: 打开");
        else
            NSLog(@"手机蓝牙状态: 关闭");
    }];
    
    //设置扫描到设备的委托
    [_baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSLog(@"搜索到了设备:%@",peripheral.name);
        if ([peripheral.name isEqualToString:MainPeripheralName])
        {
            _mainPeripheral = peripheral;
            
            //停止扫描
            [weakSelf.baby cancelScan];
            
            // 开始连接
            [weakSelf startConnection];
        }
    }];
}

# pragma
# pragma - 连接

// 开始连接
- (void)startConnection
{
    [self connectDelegate];
    
    _baby.having(_mainPeripheral).connectToPeripherals().discoverServices().discoverCharacteristics().readValueForCharacteristic().begin();
}

// 连接委托
- (void)connectDelegate
{
    __weak typeof(self)weakSelf = self;
    BabyRhythm *rhythm = [[BabyRhythm alloc]init];
    
    // 硬件链接成功的回调
    [_baby setBlockOnConnected:^(CBCentralManager *central, CBPeripheral *peripheral) {
        [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"设备：%@--连接成功",peripheral.name]];
    }];
    
    //设置设备连接失败的委托
    [_baby setBlockOnFailToConnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@--连接失败",peripheral.name);
        [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"设备：%@--连接失败",peripheral.name]];
    }];
    
    //设置设备断开连接的委托
    [_baby setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@--断开连接",peripheral.name);
        [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"设备：%@--断开失败",peripheral.name]];
    }];
    
    //设置发现设备的Services的委托
    [_baby setBlockOnDiscoverServices:^(CBPeripheral *peripheral, NSError *error) {
        NSLog(@"发现设备%@有%u个服务",peripheral.name ,peripheral.services.count);
        [rhythm beats];
    }];
    
    //设置发现设service的Characteristics的委托
    [_baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        // NSLog(@"===service name:%@",service.UUID);
        
        for (CBCharacteristic * _Nonnull characteristic in service.characteristics)
        {
            // NSLog(@"uuid:%@ properties:%d", characteristic.UUID.UUIDString, characteristic.properties);
            
            // 写特征
            if ([characteristic.UUID.UUIDString isEqualToString:WriteCharacteristicUUID])
            {
                if (characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse)
                {
                    weakSelf.writeCharacteristic = characteristic;
                    [weakSelf writeDelegate];
                }
            }
            // 读特征
            if ([characteristic.UUID.UUIDString isEqualToString:ReadCharacteristicUUID])
            {
                if (characteristic.properties & CBCharacteristicPropertyNotify)
                {
                    weakSelf.readCharacteristic = characteristic;
                    [weakSelf.mainPeripheral setNotifyValue:YES forCharacteristic:weakSelf.readCharacteristic];
                    [weakSelf readDelegate];
                } 
            }
        }
    }];
    
    //扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    /*连接选项->
     CBConnectPeripheralOptionNotifyOnConnectionKey :当应用挂起时，如果有一个连接成功时，如果我们想要系统为指定的peripheral显示一个提示时，就使用这个key值。
     CBConnectPeripheralOptionNotifyOnDisconnectionKey :当应用挂起时，如果连接断开时，如果我们想要系统为指定的peripheral显示一个断开连接的提示时，就使用这个key值。
     CBConnectPeripheralOptionNotifyOnNotificationKey:
     当应用挂起时，使用该key值表示只要接收到给定peripheral端的通知就显示一个提
     */
    NSDictionary *connectOptions = @{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnNotificationKey:@YES};
    [_baby setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:connectOptions scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];
}

# pragma
# pragma - 读写

- (void)readDelegate
{
    [_baby notify:self.mainPeripheral characteristic:self.readCharacteristic block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        NSData *getData = characteristics.value;
        NSLog(@"notify block");
        NSLog(@"getData %@",getData);
        
        if (getData.length > 0)
        {
            NSString *getSring = [NSString stringWithUTF8String:getData.bytes];
            NSLog(@"getSring %@",getSring);
        }
    }];
}

- (void)writeDelegate
{
    [_baby setBlockOnDidWriteValueForCharacteristic:^(CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"UUID:%@ 已经写入数据", characteristic.UUID);
    }];
}

# pragma
# pragma - 界面点击

- (void)sendAction
{
    NSData *sendData = [@"12" dataUsingEncoding:NSASCIIStringEncoding];
    NSLog(@"sendData:%@", sendData);
    [_mainPeripheral writeValue:sendData forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

@end

/*
 NSData *bodyData = [@"VER?" dataUsingEncoding:NSASCIIStringEncoding];
 // Main Send Data
 NSMutableData *writeData = [[NSMutableData alloc] init];
 // Body Length
 [writeData appendData:[GCHDeviceCalculation decimalToDataNoChange:bodyData.length + 3]];
 // Start
 Byte start = 0x0E;
 [writeData appendData:[NSData dataWithBytes:&start length:1]];
 // Body
 [writeData appendData:bodyData];
 // End
 Byte end1 = 0x0D;
 Byte end2 = 0x0A;
 [writeData appendData:[NSData dataWithBytes:&end1 length:1]];
 [writeData appendData:[NSData dataWithBytes:&end2 length:1]];
 NSLog(@"writeData:%@", writeData);
 
 //    // Main Send Data
 //    NSMutableData *writeData = [[NSMutableData alloc] init];
 //    Byte input_byte[8];
 //    input_byte[0] = 0x07;
 //    input_byte[1] = 0x0E;
 //    input_byte[2] = 0x4D;
 //    input_byte[3] = 0x41;
 //    input_byte[4] = 0x43;
 //    input_byte[5] = 0x3F;
 //    input_byte[6] = 0x0D;
 //    input_byte[7] = 0x0A;
 //    [writeData appendData:[NSData dataWithBytes:input_byte length:8]];
 //    NSLog(@"writeData:%@", writeData);
 */
