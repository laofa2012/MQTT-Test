//
//  GCHDeviceCalculation.m
//  CUBE
//
//  Created by Faney on 16/4/28.
//  Copyright © 2016年 Faney. All rights reserved.
// 进制之间的转换

#import "GCHDeviceCalculation.h"
#import <CommonCrypto/CommonDigest.h>

@implementation GCHDeviceCalculation

// 2进制转10进制
+ (NSInteger)binaryToDecimal:(NSString *)binaryStr
{
    int zoneHour = 0;
    for (int i = (int)binaryStr.length - 1; i >= 0; i--)
    {
        NSString *a = [binaryStr substringWithRange:NSMakeRange(i, 1)];
        zoneHour += [a intValue] * pow(2, binaryStr.length - 1 - i);
    }
    return zoneHour;
}

// 10进制转2进制
+ (NSString *)decimalToBinary:(NSInteger)input
{
    if (input == 1 || input == 0)
    {
        return [NSString stringWithFormat:@"%d", (int)input];
    }
    else
    {
        return [NSString stringWithFormat:@"%@%d", [self decimalToBinary:input / 2], (int)input % 2];
    }
}

// 10进制转16进制
+ (NSString *)decimalToHex:(NSInteger)input
{
    NSString* str = [NSString stringWithFormat:@"0x%lx", (long)input];
    return str;
}

// 16进制转2进制
+ (NSString *)hexToBinary:(NSString *)hexStr
{
    NSMutableString *getStr = [[NSMutableString alloc] init];
    for (int f = 0; f < hexStr.length; f++)
    {
        switch([hexStr characterAtIndex:f])
        {
            case '0': [getStr appendString:@"0000"]; break;
            case '1': [getStr appendString:@"0001"]; break;
            case '2': [getStr appendString:@"0010"]; break;
            case '3': [getStr appendString:@"0011"]; break;
            case '4': [getStr appendString:@"0100"]; break;
            case '5': [getStr appendString:@"0101"]; break;
            case '6': [getStr appendString:@"0110"]; break;
            case '7': [getStr appendString:@"0111"]; break;
            case '8': [getStr appendString:@"1000"]; break;
            case '9': [getStr appendString:@"1001"]; break;
            case 'a':
            case 'A': [getStr appendString:@"1010"]; break;
            case 'b':
            case 'B': [getStr appendString:@"1011"]; break;
            case 'c':
            case 'C': [getStr appendString:@"1100"]; break;
            case 'd':
            case 'D': [getStr appendString:@"1101"]; break;
            case 'e':
            case 'E': [getStr appendString:@"1110"]; break;
            case 'f':
            case 'F': [getStr appendString:@"1111"]; break;
            default: [getStr appendString:@"0000"]; break;
                
        }
    }
    return getStr;
}

// 10进制转8位转Data
+ (NSData *)decimalToData:(NSInteger)input
{
    Byte input_byte[4];
    input_byte[0] = (Byte)((input >> 24) & 0xFF);
    input_byte[1] = (Byte)((input >> 16) & 0xFF);
    input_byte[2] = (Byte)((input >> 8) & 0xFF);
    input_byte[3] = (Byte)(input & 0xFF);
    // 转高低位
    for (int f = 0; f < 4; f++)
    {
        if (input_byte[0] == 0)
        {
            input_byte[0] = input_byte[1];
            input_byte[1] = input_byte[2];
            input_byte[2] = input_byte[3];
            input_byte[3] = 0;
        }
        else
        {
            break;
        }
    }
    
    return [NSData dataWithBytes:input_byte length:4];
}

// 10进制转8位转Data不反转
+ (NSData *)decimalToDataNoChange:(NSInteger)input
{
    Byte input_byte[1];
    input_byte[0] = (Byte)(input & 0xFF);
    
    return [NSData dataWithBytes:input_byte length:1];
}

// 10进制转1位转Data
+ (NSData *)decimalToOneByteData:(NSInteger)input
{
    Byte input_byte[1];
    input_byte[0] = input;
    return [NSData dataWithBytes:input_byte length:1];
}

// 将高位字节转换为int
+ (int)hBytesToInt:(Byte[])b
{
    int s = 0;
    for (int i = 0; i < 3; i++)
    {
        if (b[i] >= 0)
        {
            s = s + b[i];
        }
        else
        {
            s = s +256 + b[i];
        }
        s = s * 256;
        if (b[3] >= 0)
        {
            s = s + b[3];
        } else
        {
            s = s + 256 + b[3];
        }
    }
    return s;
}

// Bytes转Int
+ (int)lBytesToIntNoChange:(Byte [])b
{
    return b[3] + (b[2] << 8) + (b[1] << 16) + (b[0] << 24);
}

// Data转10进制
+ (int)dataToDecimal:(NSData *)input
{
    // 高低位转换
    NSData *returnData = nil;
    for (int f = (int)input.length - 1; f >= 0; f--)
    {
        if (input.length < f + 1) break;
        NSData *getData = [input subdataWithRange:NSMakeRange(f, 1)];
        Byte *inputBytes = (Byte *)getData.bytes;
        if (inputBytes[0] > 0)
        {
            long returnLength = returnData.length;
            long getLength = getData.length;
            
            uint8_t *returnBuffer = (uint8_t*)malloc(returnLength + getLength);
            memcpy(returnBuffer, [returnData bytes], returnLength);
            returnData = nil;
            
            memcpy(returnBuffer + returnLength, [getData bytes], getLength);
            returnData = [NSData dataWithBytes:returnBuffer length:returnLength + getLength];
            free(returnBuffer);
        }
    }
    
    // 计算值 [12,22] => 12 * 16 * 16 + 22 * 1
    int length = (int)returnData.length;
    Byte *inputBytes = (Byte *)returnData.bytes;
    int returnDecimal = 0;
    for (int f = 0; f < length; f++)
    {
        returnDecimal += inputBytes[f] * powl(16, (length - 1 - f) * 2);
    }
    
    return returnDecimal;
}

// Long型转换成Data
+ (NSData *)longToData:(long)input type:(int)type
{
    Byte input_byte[type];
    if (type == 4)
    {
        input_byte[0] = (Byte)((input >> 24) & 0xFF);
        input_byte[1] = (Byte)((input >> 16) & 0xFF);
        input_byte[2] = (Byte)((input >> 8) & 0xFF);
        input_byte[3] = (Byte)(input & 0xFF);
    }
    else if (type == 2)
    {
        input_byte[0] = (Byte)((input >> 8) & 0xFF);
        input_byte[1] = (Byte)(input & 0xFF);
    }
    
    return [NSData dataWithBytes:input_byte length:type];
}

// String转16/8Byte(32/16个16进制)转Data
+ (NSData *)stringToData:(NSString *)input type:(int)type
{
    NSMutableData *inputData = [[NSMutableData alloc] initWithLength:0];
    NSData *lastData = [input dataUsingEncoding:NSUTF8StringEncoding];
    [inputData appendData:lastData];
    // 补零
    int lastDataLength = (int)lastData.length;
    if (type - lastDataLength > 0)
    {
        Byte subByte[] = {0};
        for (int f = 0; f < (type - lastDataLength); f++)
        {
            [inputData appendData:[NSData dataWithBytes:subByte length:1]];
        }
    }
    return inputData;
}

// String转nByte的Data(int)
+ (NSData *)intStringToData:(NSString *)input type:(int)type
{
    NSMutableData *inputData = [[NSMutableData alloc] initWithLength:0];
    for (int f = 0; f < input.length; f++)
    {
        Byte subByte[] = {[[input substringWithRange:NSMakeRange(f, 1)] intValue]};
        [inputData appendData:[NSData dataWithBytes:subByte length:1]];
    }
    
    // 补零
    int lastDataLength = (int)inputData.length;
    if (type - lastDataLength > 0)
    {
        Byte subByte[] = {0};
        for (int f = 0; f < (type - lastDataLength); f++)
        {
            [inputData appendData:[NSData dataWithBytes:subByte length:1]];
        }
    }
    return inputData;
}

// 10进制转2Byte(4个16进制)转Data
+ (NSData *)decimalToTwoBytesData:(NSInteger)input
{
    Byte input_byte[2];
    input_byte[1] = (Byte)((input >> 8) & 0xFF);
    input_byte[0] = (Byte)(input & 0xFF);
    return [NSData dataWithBytes:input_byte length:2];
}

// Sha256加密
+ (NSString *)sha256HashFor:(NSString *)input
{
    const char* str = [input UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(str, (CC_LONG)strlen(str), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_SHA256_DIGEST_LENGTH; i++)
    {
        [ret appendFormat:@"%02x",result[i]];
    }
    if (ret.length > 6) ret = [NSMutableString stringWithString:[ret substringToIndex:6]];
    return ret;
}

@end
