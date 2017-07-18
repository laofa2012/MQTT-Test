//
//  ViewController.m
//  BabyTestProject
//
//  Created by ZTELiuyw on 16/3/11.
//  Copyright © 2016年 liuyanwei. All rights reserved.
//

#import "ViewController.h"
#import "BabyBluetooth.h"

#define MainPeripheralName @"HF-BL100-CL"

@interface ViewController ()

@property (strong, nonatomic) BabyBluetooth *baby;

@property (strong, nonatomic) CBCharacteristic *writeCharacteristic;

@property (strong, nonatomic) CBPeripheral *writePeripheral;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"BLE";
    
    float width = 200.0f;
    float height = 70.0f;
    UIButton *button = [[UIButton alloc] init];
    button.frame = CGRectMake((self.view.frame.size.width - width) / 2, (self.view.frame.size.height - height) / 2, width, height);
    [button addTarget:self action:@selector(sendAction) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Send" forState:UIControlStateNormal];
    button.backgroundColor = [UIColor blueColor];
    [self.view addSubview:button];
    
    // 初始化蓝牙库
    _baby = [BabyBluetooth shareBabyBluetooth];
    // 设置蓝牙委托
    [self babyDelegate];
    // 关闭所有的连接
    [_baby cancelAllPeripheralsConnection];
    // 设置委托后直接可以使用，无需等待CBCentralManagerStatePoweredOn状态
    _baby.scanForPeripherals().begin();
}

// 设置蓝牙委托
- (void)babyDelegate
{
    // 用于在block内进行一些操作
    __weak typeof(self) weakSelf = self;
    
    // 返回CBCentralManager实例的状态(手机蓝牙的状态，开、关等)
    [_baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        switch (central.state) {
            case CBCentralManagerStatePoweredOn:
                NSLog(@"手机蓝牙状态: 打开");
                break;
            case CBCentralManagerStatePoweredOff:
                NSLog(@"手机蓝牙状态: 关闭");
                break;
            default:
                break;
        }
    }];
    
# pragma mark 扫描/链接/硬件状态
    
    // 过滤:哪些可以扫到
    [_baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSLog(@"Discover peripheralName: %@", peripheralName);
        if ([peripheralName isEqualToString:MainPeripheralName])
        {
            return YES;
        }
        return NO;
    }];

    // 搜索到设备后的回调
    [_baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSLog(@"搜索到设备: %@           %@", peripheral.name, advertisementData);
        if ([peripheral.name isEqualToString:MainPeripheralName])
        {
            NSLog(@"1111111111111111");
            _writePeripheral = peripheral;
            weakSelf.baby.having(peripheral).connectToPeripherals().discoverServices().discoverCharacteristics().readValueForCharacteristic().begin();
        }
    }];
    
    // 硬件链接成功的回调
    [_baby setBlockOnConnected:^(CBCentralManager *central, CBPeripheral *peripheral) {
        NSLog(@"设备：%@--连接成功",peripheral.name);
        // 读取RSSI
        [peripheral readRSSI];
    }];
    
    // 硬件断开链接的回调
    [_baby setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@--连接断开",peripheral.name);
    }];
    
    // 读取RSSI的回调(peripheral要先调用readRSSI方法)
    [_baby setBlockOnDidReadRSSI:^(NSNumber *RSSI, NSError *error) {
        NSLog(@"RSSI:%@",RSSI);
    }];
    
# pragma mark 读取硬件数据(「服务」「特征」「Descriptor」)的回调
    
    // 发现硬件「服务」后的回调, 这个block中是不返回「特征」的
    [_baby setBlockOnDiscoverServices:^(CBPeripheral *peripheral, NSError *error) {
        NSLog(@"发现设备%@有%lu个服务",peripheral.name ,peripheral.services.count);
//        [peripheral.services enumerateObjectsUsingBlock:^(CBService * _Nonnull service, NSUInteger idx, BOOL * _Nonnull stop) {
//            NSLog(@"设备%@的第%lu个服务是:%@", peripheral.name, (unsigned long)idx, service);
//        }];
    }];
    
    // 发现硬件「特征」后的回调
    [_baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        [peripheral.services enumerateObjectsUsingBlock:^(CBService * _Nonnull service, NSUInteger idx, BOOL * _Nonnull stop) {
            NSLog(@"设备%@的第%lu个服务有%lu个“特征”", peripheral.name, (unsigned long)idx, (unsigned long)service.characteristics.count);
            
            // 特征
            [service.characteristics enumerateObjectsUsingBlock:^(CBCharacteristic * _Nonnull characteristic, NSUInteger idx, BOOL * _Nonnull stop) {
                NSLog(@"这个服务的 characteristic name:%@ value is:%@", characteristic.UUID, characteristic.value);
                // 负责各种操作的characteristic
                if ([characteristic.UUID.UUIDString isEqualToString:@"2B13"])
                {
                    weakSelf.writeCharacteristic = characteristic;
                    [weakSelf setNotify];
                    if (characteristic.properties & CBCharacteristicPropertyWrite) {
                        Byte b = 0X01;
                        NSData *data = [NSData dataWithBytes:&b length:sizeof(b)];
                        [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                    }
                }
            }];
        }];
    }];
    
# pragma mark 写入数据的回调
    
    [_baby setBlockOnDidWriteValueForCharacteristic:^(CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"UUID:%@ 已经写入数据", characteristic.UUID);
    }];
}

- (void)setNotify
{
    if (_writeCharacteristic.properties & CBCharacteristicPropertyNotify) {
        NSLog(@"notifying........");
        [_writePeripheral setNotifyValue:YES forCharacteristic:_writeCharacteristic];
        
        [_baby notify:_writePeripheral characteristic:_writeCharacteristic block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
            NSLog(@"notify block");
            NSLog(@"new value %@",characteristics.value);
        }];
    }
}

- (void)sendAction
{
    Byte b = 0x01;
    NSData *testData = [NSData dataWithBytes:&b length:sizeof(b)];
    [_writePeripheral writeValue:testData forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithResponse];
}

@end
