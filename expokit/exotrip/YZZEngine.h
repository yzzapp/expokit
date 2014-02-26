//
//  YZZEngine.h
//  cherry
//
//  Created by 石戬, 姚勤(还没有对象的87) on on 13-2-19.
//  Copyright (c) 2013年 北京云指针科技有限公司. All rights reserved.
//

//#import "YZZGalleryWallVC.h"

@interface YZZEngine : MKNetworkEngine

//typedef void (^CurrencyResponseBlock)(NSArray * contentArray, UITableView * tableView);
typedef void (^CurrencyResponseBlock)(double dbr);

#pragma mark - Coiii REQUESTs

-(MKNetworkOperation*)ExpoPost:(NSString *)postString
                            vc:(UIViewController *)vc;

-(MKNetworkOperation*)ExpoCreate:(NSString *)sql
                              vc:(UIViewController *)vc;

@end
