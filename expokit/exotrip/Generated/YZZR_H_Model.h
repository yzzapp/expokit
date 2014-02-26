//
//  YZZR_H_Model.h
//  expokit
//
//  Created by 石戬, 姚勤(还没有对象的87) on on 13-5-3.
//  Copyright (c) 2013年 YzzApp.com. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * yzz_ref_big_price = @"598.00f";
static NSString * yzz_ref_biz_price = @"388.00f";
static NSString * yzz_ref_exp_price = @"231.00f";

@interface YZZR_H_Model : NSObject

@property (strong,nonatomic) NSMutableArray * m_expressHotels;
@property (strong,nonatomic) NSMutableArray * m_bizHotels;
@property (strong,nonatomic) NSMutableArray * m_bigHotels;

-(void)trainRoom:(NSDictionary *)room forHotel:(NSMutableDictionary *)hotel;
-(void)trainPrint:(NSMutableDictionary *)hotel;
-(NSMutableDictionary *)recommend:(NSMutableArray *)hotels forHall:(NSMutableDictionary *)hallDic;

@end
