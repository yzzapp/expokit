//
//  YZZR_H_Model.m
//  expokit
//
//  Created by 石戬, 姚勤(还没有对象的87) on on 13-5-3.
//  Copyright (c) 2013年 YzzApp.com. All rights reserved.
//
#import "YZZDatabase.h"
#import "YZZUtil.h"

#import "YZZR_H_Model.h"
#import "YZZHotelDownloadVC.h"

@implementation YZZR_H_Model


/*
 algorithm
 
 1.按房型价位分组酒店房型，级别3+1组,含淘汰高低价组:
 1.1 房型：经济组,商务组,豪华组;允许重叠
 最终价位 0-219,220-330,331-449,450-599,600-1200
 1.2 对酒店房型分布跨区做统计，例如10种房型：(0,3,5,2,0)
 1.3 为酒店做自动评价：快捷酒店，宾馆酒店，大酒店
 
 2.各组 挑选房型,2,3,2,个酒店
 
 90317:浦江之星（上海世博园店）,287126:标房(内宾)(2), '268.00'¥
 90317:浦江之星（上海世博园店）,287128:高级大床房(内宾)(2), '248.00'¥
 90317:浦江之星（上海世博园店）,287129:大床房A(内宾)(2), '228.00'¥
 90317:浦江之星（上海世博园店）,287132:大床房B(内宾)(2), '208.00'¥
 90317:浦江之星（上海世博园店）,287133:特价房(内宾)(1), '138.00'¥
 
 (0,0,0,2,6)
 18552:上海利嘉宾馆,15062:商务套房(2), '820.00'¥
 18552:上海利嘉宾馆,15063:行政套房(2), '980.00'¥
 18552:上海利嘉宾馆,17838:高级房(2), '530.00'¥
 18552:上海利嘉宾馆,149870:豪华房(2), '720.00'¥
 18552:上海利嘉宾馆,1347205:高级房(提前7天预订)(2), '500.00'¥
 18552:上海利嘉宾馆,1347206:豪华房(提前7天预订)(2), '660.00'¥
 18552:上海利嘉宾馆,1347211:商务套房(提前7天预订)(2), '750.00'¥
 18552:上海利嘉宾馆,1895259:行政套房(提前7天预订)(2), '890.00'¥
 
 (0,1,4,1,6) 性价比！大酒店
 9476:上海光大会展中心国际大酒店,8368:商务套房(2), '1200.00'¥
 9476:上海光大会展中心国际大酒店,123309:行政房(2), '780.00'¥
 9476:上海光大会展中心国际大酒店,324409:商务房(2), '580.00'¥
 9476:上海光大会展中心国际大酒店,336252:商务房(提前14天预订)(2), '348.00'¥
 9476:上海光大会展中心国际大酒店,447668:豪华房(2), '680.00'¥
 9476:上海光大会展中心国际大酒店,447670:行政套房(2), '1800.00'¥
 9476:上海光大会展中心国际大酒店,486580:商务套房(特惠)(2), '720.00'¥
 9476:上海光大会展中心国际大酒店,518731:豪华房(提前14天预订)(2), '408.00'¥
 9476:上海光大会展中心国际大酒店,518737:豪华房(限量特惠)(2), '442.00'¥
 9476:上海光大会展中心国际大酒店,518739:商务房(限量特惠)(2), '377.00'¥
 9476:上海光大会展中心国际大酒店,552319:四间套房(3), '2600.00'¥
 9476:上海光大会展中心国际大酒店,1142512:商务房(限时特惠)(2), '298.00'¥
 
 //大床？双床？
 //特价？
 //酒店总体价位，
 //房间基本条件，图片
 
 // 特价折扣比
 
 // 品牌偏好
 
 //recommend model
 // air off
 
 // hotel
 // Lev.1
 // Hotel Lev2
 // Room 3
 // Bed Big/Two
 // More : +1 lower;
 // Lev.2
 // Hotel Lev3-4
 // Room 4
 // Bed Big/Two
 // Off Lev4-Off-40%+
 // More : +2 hotel;
 // Lev.3
 // Hotel Lev4-5
 // Room 5
 // Bed Big
 // More : +1 hotel;
 // air back
 
 */

//room = {
//    0503 = "880.00";
//    0504 = "880.00";
//    0505 = "880.00";
//    0506 = "880.00";
//    0507 = "880.00";
//    0508 = "880.00";
//    0509 = "880.00";
//    0510 = "880.00";
//    0511 = "880.00";
//    0512 = "880.00";
//    0513 = "880.00";
//    0514 = "880.00";
//    0515 = "880.00";
//    0516 = "880.00";
//    0517 = "880.00";
//    0518 = "880.00";
//    0519 = "880.00";
//    0520 = "880.00";
//    0521 = "880.00";
//    0522 = "880.00";
//    0523 = "880.00";
//    0524 = "880.00";
//    0525 = "880.00";
//    0526 = "880.00";
//    0527 = "880.00";
//    0528 = "880.00";
//    0529 = "880.00";
//    0530 = "880.00";
//    0531 = "880.00";
//    0601 = "880.00";
//    0602 = "880.00";
//    0603 = "880.00";
//    0604 = "880.00";
//    0605 = "880.00";
//    0606 = "880.00";
//    0607 = "880.00";
//    0608 = "880.00";
//    0609 = "880.00";
//    0610 = "880.00";
//    0611 = "880.00";
//    0612 = "880.00";
//    0613 = "880.00";
//    0614 = "880.00";
//    0615 = "880.00";
//    0616 = "880.00";
//    0617 = "880.00";
//    BEDS = 2;
//    HOTELCODE = 20535;
//    HOTELNAME = "\U5317\U4eac\U8d35\U56fd\U9152\U5e97";
//    ROOMCODE = 23582;
//    ROOMNAME = "\U5546\U52a1\U5957\U95f4";
//}

//hotel = {
//    address = "\U5de6\U5bb6\U5e841\U53f7";
//    code = 20535;
//    image = "http://Images4.c-ctrip.com/target/hotel/21000/20535/75E4241B-E5F4-4EA5-9718-0F11B69AE3BE_100_75.jpg";
//    lat = "39.95759";
//    long = "116.43688";
//    name = "\U5317\U4eac\U8d35\U56fd\U9152\U5e97";
//}

//最终价位 0-219,220-330,331-449,450-599,600-1200
static NSString * YZZRoomLev0 = @"RoomLev0-0-219";
static NSString * YZZRoomLev1 = @"RoomLev0-220-330";
static NSString * YZZRoomLev2 = @"RoomLev0-331-449";
static NSString * YZZRoomLev3 = @"RoomLev0-450-599";
static NSString * YZZRoomLev4 = @"RoomLev0-600-1200";
static NSString * YZZRoomLevE = @"RoomLev0-1201-99999";

-(void)trainRoom:(NSDictionary *)room forHotel:(NSMutableDictionary *)hotel
{
    //NSLog(@"room = %@ , hotel = %@",room,hotel);
//    NSString * hname = [hotel valueForKey:@"name"];
//    NSString * hcode = [hotel valueForKey:@"code"];
//    NSString * rname = [room valueForKey:@"ROOMNAME"];
//    NSString * rcode = [room valueForKey:@"ROOMCODE"];
    
    //NSLog(@"#Train# hotel(%@:%@) room(%@:%@) refPrice(%@)",hname,hcode,rname,rcode,refPrice);

    if (![hotel objectForKey:YZZRoomLev0]) [hotel setValue:[[NSMutableArray alloc] init] forKey:YZZRoomLev0];
    if (![hotel objectForKey:YZZRoomLev1]) [hotel setValue:[[NSMutableArray alloc] init] forKey:YZZRoomLev1];
    if (![hotel objectForKey:YZZRoomLev2]) [hotel setValue:[[NSMutableArray alloc] init] forKey:YZZRoomLev2];
    if (![hotel objectForKey:YZZRoomLev3]) [hotel setValue:[[NSMutableArray alloc] init] forKey:YZZRoomLev3];
    if (![hotel objectForKey:YZZRoomLev4]) [hotel setValue:[[NSMutableArray alloc] init] forKey:YZZRoomLev4];
    [self mergeRoom:room forHotel:hotel];
}

-(void)trainPrint:(NSMutableDictionary *)hotel
{
    NSString * hname = [hotel valueForKey:@"name"];
    NSLog(@"%@ (%d,%d,%d,%d,%d)",
          hname,
          [[hotel valueForKey:YZZRoomLev0] count],
          [[hotel valueForKey:YZZRoomLev1] count],
          [[hotel valueForKey:YZZRoomLev2] count],
          [[hotel valueForKey:YZZRoomLev3] count],
          [[hotel valueForKey:YZZRoomLev4] count]);
}

- (void)mergeRoom:(NSDictionary *)room forHotel:(NSMutableDictionary *)hotel;
{
    float price = [self QueryRefPrice:room];
    // 最终价位 0-219,220-330,331-449,450-599,600-1200
    NSString * rangeName = YZZRoomLevE;
    if (price <=219 && price >= 49)     rangeName = YZZRoomLev0;
    if (price >=220 && price <= 330)    rangeName = YZZRoomLev1;
    if (price >=331 && price <= 449)    rangeName = YZZRoomLev2;
    if (price >=450 && price <= 559)    rangeName = YZZRoomLev3;
    if (price >= 600 && price <= 1200)  rangeName = YZZRoomLev4;
    NSMutableArray * arr  = [hotel valueForKey:rangeName];
    [arr addObject:room];
    [hotel setValue:arr forKey:rangeName];
}

- (float )QueryRefPrice:(NSDictionary *)room
{
    NSString * futureTwoDayMMDD = [YZZUtil DATE_FORMAT_MMDD:[YZZUtil DATE_DAY_CAL:[YZZUtil DATE_TODAY_STRING]
                                                                          intDays:+2]];
    NSString * refPrice = [room valueForKey:futureTwoDayMMDD];
    return [refPrice floatValue];
}

-(NSMutableDictionary *)recommend:(NSMutableArray *)hotels forHall:(NSMutableDictionary *)hallDic
{
    NSString * hall_name = [hallDic valueForKey:@"NAME"];

    if (self.m_expressHotels == nil) {
        self.m_expressHotels = [[NSMutableArray alloc] init];
    } else {
        [self.m_expressHotels removeAllObjects];
    }
    
    if (self.m_bizHotels == nil) {
        self.m_bizHotels = [[NSMutableArray alloc] init];
    } else {
        [self.m_bizHotels removeAllObjects];
    }
    
    if (self.m_bigHotels == nil) {
        self.m_bigHotels = [[NSMutableArray alloc] init];
    } else {
        [self.m_bigHotels removeAllObjects];
    }
    
    NSMutableDictionary * result = [[NSMutableDictionary alloc] init];
    NSLog(@"recommend: start~~~ (%@)",hall_name);
    for (NSDictionary * h in hotels) {
        NSString * hname = [h valueForKey:@"name"];
        NSString * hrate = [h valueForKey:@"rate"];
        
        int lev0 = [[h valueForKey:YZZRoomLev0] count];
        int lev1 = [[h valueForKey:YZZRoomLev1] count];
        int lev2 = [[h valueForKey:YZZRoomLev2] count];
        int lev3 = [[h valueForKey:YZZRoomLev3] count];
        int lev4 = [[h valueForKey:YZZRoomLev4] count];
                
        NSString * toLog = @"================== =what? =======";
        
        BOOL is_not_recommend_rooms = ((lev1 + lev2 + lev3 ==0)
                                   || (float)lev0/(float)(lev0+lev1+lev2+lev3+lev4) > 0.51f);
        if (is_not_recommend_rooms) {
            toLog = @"= is_not_recommend_rooms";
            //NSLog(@"      %@:(%d,%d,%d,%d,%d),result(%@)",hname,lev0,lev1,lev2,lev3,lev4,toLog);
            continue;
        }

        BOOL is_big_hotel = ((lev0==0)
                             && (lev1==0)
                             && (lev2 + lev3 > 0)
                             && (lev4>0));
        if (is_big_hotel) {
            toLog = @"= is_big_hotel";
            NSLog(@"#R# 3 %@(%@):(%d,%d,%d,%d,%d),result(%@)",hname,hrate,lev0,lev1,lev2,lev3,lev4,toLog);
            [self.m_bigHotels addObject:h];
            continue;
        }
        
        BOOL is_express_hotel = ( (float)lev1/(float)(lev0+lev1+lev2+lev3+lev4) > 0.30f);
        if (is_express_hotel) {
            toLog = @"= is_express_hotel";
            NSLog(@"#R# 1 %@(%@):(%d,%d,%d,%d,%d),result(%@)",hname,hrate,lev0,lev1,lev2,lev3,lev4,toLog);
            [self.m_expressHotels addObject:h];
            continue;
        }
 
        BOOL is_biz_hotel = (lev2>0);
        if (is_biz_hotel) {
            toLog = @"= is_biz_hotel";
            NSLog(@"#R# 2 %@(%@):(%d,%d,%d,%d,%d),result(%@)",hname,hrate,lev0,lev1,lev2,lev3,lev4,toLog);
            [self.m_bizHotels addObject:h];
            continue;
        }
        NSLog(@"#R#   %@(%@):(%d,%d,%d,%d,%d),result(%@)",hname,hrate,lev0,lev1,lev2,lev3,lev4,toLog);
    }
        
    [result setValue:self.m_expressHotels   forKey:@"express"];
    [result setValue:self.m_bizHotels       forKey:@"biz"];
    [result setValue:self.m_bigHotels       forKey:@"big"];
    
    NSMutableDictionary * dic3choice = [self recommendRoomChoice];

    NSLog(@"recommend: end~~~ exp(%d),biz(%d),big(%d) hotels\n",
          [self.m_expressHotels count],
          [self.m_bizHotels count],
          [self.m_bigHotels count]);
    return dic3choice;
}

- (NSMutableDictionary *)recommendRoomChoice
{
    NSMutableArray * harr = [[NSMutableArray alloc] init];
    [harr addObjectsFromArray:self.m_bigHotels];
    [harr addObjectsFromArray:self.m_bizHotels];
    [harr addObjectsFromArray:self.m_expressHotels];
    NSMutableArray * roomArr = [[NSMutableArray alloc] init];
    for (NSMutableDictionary * h in harr) {
        for (NSMutableDictionary * r in [h valueForKey:YZZRoomLev3]) {
            NSMutableDictionary * rDic = [[NSMutableDictionary alloc] initWithDictionary:r];
            [rDic setValue:[h valueForKey:@"rate"] forKey:@"HOTELRATE"];
            [rDic setValue:[h valueForKey:@"image"] forKey:@"HOTELIMAGE"];
            [rDic setValue:[h valueForKey:@"lat"] forKey:@"HOTELLAT"];
            [rDic setValue:[h valueForKey:@"long"] forKey:@"HOTELLONG"];
            [rDic setValue:[h valueForKey:@"address"] forKey:@"ADDRESS"];
            [roomArr addObject:rDic];
        }
        for (NSMutableDictionary * r in [h valueForKey:YZZRoomLev2]) {
            NSMutableDictionary * rDic = [[NSMutableDictionary alloc] initWithDictionary:r];
            [rDic setValue:[h valueForKey:@"rate"] forKey:@"HOTELRATE"];
            [rDic setValue:[h valueForKey:@"image"] forKey:@"HOTELIMAGE"];
            [rDic setValue:[h valueForKey:@"lat"] forKey:@"HOTELLAT"];
            [rDic setValue:[h valueForKey:@"long"] forKey:@"HOTELLONG"];
            [rDic setValue:[h valueForKey:@"address"] forKey:@"ADDRESS"];
            [roomArr addObject:rDic];
        }
        for (NSMutableDictionary * r in [h valueForKey:YZZRoomLev1]) {
            NSMutableDictionary * rDic = [[NSMutableDictionary alloc] initWithDictionary:r];
            [rDic setValue:[h valueForKey:@"rate"] forKey:@"HOTELRATE"];
            [rDic setValue:[h valueForKey:@"image"] forKey:@"HOTELIMAGE"];
            [rDic setValue:[h valueForKey:@"lat"] forKey:@"HOTELLAT"];
            [rDic setValue:[h valueForKey:@"long"] forKey:@"HOTELLONG"];
            [rDic setValue:[h valueForKey:@"address"] forKey:@"ADDRESS"];
            [roomArr addObject:rDic];
        }
    }
    NSLog(@"arr has %d hotels %d rooms totally.",[harr count],[roomArr count]);
    
    NSMutableDictionary * expRoomDic = [[NSMutableDictionary alloc] init];
    NSMutableDictionary * bizRoomDic = [[NSMutableDictionary alloc] init];
    NSMutableDictionary * bigRoomDic = [[NSMutableDictionary alloc] init];

    float deta = 9999.0f;
    for (NSMutableDictionary * r in roomArr) {
        float roomRefPrice = [self QueryRefPrice:r];
        if ( fabsf(roomRefPrice - [yzz_ref_big_price floatValue]) < deta ) {
            deta = fabsf(roomRefPrice - [yzz_ref_big_price floatValue]);
            bigRoomDic = r;
        }
    }
    
    deta = 9999.0f;
    for (NSMutableDictionary * r in roomArr) {
        float roomRefPrice = [self QueryRefPrice:r];
        if ( fabsf(roomRefPrice - [yzz_ref_biz_price floatValue]) < deta ) {
            deta = fabsf(roomRefPrice - [yzz_ref_biz_price floatValue]);
            bizRoomDic = r;
        }
    }

    deta = 9999.0f;
    for (NSMutableDictionary * r in roomArr) {
        float roomRefPrice = [self QueryRefPrice:r];
        if ( fabsf(roomRefPrice - [yzz_ref_exp_price floatValue]) < deta && roomRefPrice > [yzz_ref_exp_price floatValue] ) {
            deta = fabsf(roomRefPrice - [yzz_ref_exp_price floatValue]);
            expRoomDic = r;
        }
    }
    
    NSMutableDictionary * array3choice = @{
                               @"big":bigRoomDic,
                               @"biz":bizRoomDic,
                               @"exp":expRoomDic};
    return array3choice;
}

@end
