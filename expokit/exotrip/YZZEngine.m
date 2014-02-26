//
//  YZZEngine.m
//  cherry
//
//  Created by 石戬, 姚勤(还没有对象的87) on on 13-2-19.
//  Copyright (c) 2013年 北京云指针科技有限公司. All rights reserved.
//

#import "YZZEngine.h"
#import "YZZDataHelper.h"

#define EXPO_CREATE_DATA_PATH @"/disscuss/"

@implementation YZZEngine 

-(MKNetworkOperation*)ExpoPost:(NSString *)postString
                            vc:(UIViewController *)vc
{
    MKNetworkOperation *op = [self operationWithPath:@"/maintain/update/hotels/"
                                              params:@{
                              @"mntn_pwd" : @"xxxxx",
                              @"date_off" : @"0601",
                              @"date_bck" : @"0604",
                              @"city_src" : @"北京",
                              @"city_dst" : @"上海",
                              @"expo_hll" : @"上海某展馆"
                              }
                                          httpMethod:@"POST"];
    
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        NSLog(@"POST and Responsed as:(%@)",[completedOperation responseString]);
        
        if([completedOperation isCachedResponse]) {
            DLog(@"POST cache data");
        }
        else {
            DLog(@"POST server data");
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [vc performSelector:@selector(Refresh)];
        });
    } errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
        //    errorBlock(error);
    }];
    [self enqueueOperation:op];
    return op;
}

-(MKNetworkOperation*)ExpoCreate:(NSString *)sql
                            vc:(UIViewController *)vc
{
    MKNetworkOperation *op = [self operationWithPath:EXPO_CREATE_DATA_PATH
                                              params:@{
                              @"mntn_pwd" : @"xxxxxx",
                              @"create_sqls" : sql
                              }
                                          httpMethod:@"POST"];
    
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        NSLog(@"POST and Responsed as:(%@)",[completedOperation responseString]);
        
        if([completedOperation isCachedResponse]) {
            DLog(@"POST cache data");
        }
        else {
            DLog(@"POST server data");
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [vc performSelector:@selector(Refresh)];
        });
    } errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
        //    errorBlock(error);
    }];
    [self enqueueOperation:op];
    return op;
}

@end
