//
//  GCHDeviceCalculation.h
//  CUBE
//
//  Created by Faney on 16/4/28.
//  Copyright © 2016年 Faney. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GCHDeviceCalculation : NSObject

// 2进制转10进制
+ (NSInteger)binaryToDecimal:(NSString *)binaryStr;

// 10进制转2进制
+ (NSString *)decimalToBinary:(NSInteger)input;

// 10进制转16进制
+ (NSString *)decimalToHex:(NSInteger)input;

// 16进制转2进制
+ (NSString *)hexToBinary:(NSString *)hexStr;

// 10进制转8位转Data
+ (NSData *)decimalToData:(NSInteger)input;

// 10进制转8位转Data不反转
+ (NSData *)decimalToDataNoChange:(NSInteger)input;

// 10进制转1位转Data
+ (NSData *)decimalToOneByteData:(NSInteger)input;

// 更改高地位,网络需要
+ (int)hBytesToInt:(Byte[])b;

// Bytes转Int
+ (int)lBytesToIntNoChange:(Byte[])b;

// Data转10进制
+ (int)dataToDecimal:(NSData *)input;

// Long型转换成Data
+ (NSData *)longToData:(long)input type:(int)type;

// String转nByte的Data(ASICI)
+ (NSData *)stringToData:(NSString *)input type:(int)type;

// String转nByte的Data(int)
+ (NSData *)intStringToData:(NSString *)input type:(int)type;

// 10进制转2Byte(4个16进制)转Data
+ (NSData *)decimalToTwoBytesData:(NSInteger)input;

// Sha256加密
+ (NSString *)sha256HashFor:(NSString *)input;

@end
