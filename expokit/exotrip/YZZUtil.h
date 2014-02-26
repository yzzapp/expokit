//
//  YZZUtil.h
//  exotrip
//
//  Created by 石戬, 姚勤(还没有对象的87) on on 13-4-20.
//  Copyright (c) 2013年 YzzApp.com. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * yzz_aid = @"1111";
static NSString * yzz_sid = @"111111";
static NSString * yzz_key = @"1AA11111-AAA1-11A1-1111-A11AAA11AA11";

@interface YZZUtil : NSObject

+ (NSString *)OTA_HEAD:(NSString *)requestType;
+ (NSString *)OTA_REQUEST:(NSString *)requestType body:(NSString *)body;
+ (NSString *)OTA_FLIGHT_REQUEST:(NSString *)requestType body:(NSString *)body;

+ (NSDictionary *) md5_ctrip:(NSString *)requestType;

+ (NSString *)DATE_TODAY_STRING;
+ (NSString *)DATE_DAY_CAL:(NSString *)dateString intDays:(int)intDay;
+ (NSString *)DATE_FORMAT_MMDD:(NSString *)dateString;

+ (NSString *)getTimeStampNow;
+ (NSString *)getTimeStampWithDate:(NSDate *)date;
+ (NSString *)getTimeStampWithString:(NSString *)string;

+ (NSString *)getCodeListForUIT;

#pragma mark - file
+ (void)WRITE_TO_FILE:(NSString *)content withName:(NSString *)name;
+ (NSString *)READ_FROM_FILE:(NSString *)name;

@end
