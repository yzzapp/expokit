//
//  YZZDatabase.h
//  yzzdb
//
//  Created by 石戬, 姚勤(还没有对象的87) on on 13-3-26.
//  Copyright (c) 2013年 YzzApp.com. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * YZZ_K_DB_FILE_NAME = @"e2013.sqlite3";
static NSString * YZZ_K_DB_IN_BUNDLE = @"expo2013.sqlite3";

@interface YZZDatabase : NSObject

+ (NSString *) execSQL : (NSString *)sql;
+ (NSMutableArray *) execSelect : (NSString *)sql;

@end
