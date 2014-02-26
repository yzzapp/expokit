//
//  YZZHotelDownloadVC.h
//  expokit
//
//  Created by 石戬, 姚勤(还没有对象的87) on on 13-4-30.
//  Copyright (c) 2013年 YzzApp.com. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * hotelPlanTablePrefix = @"HOTELPLANE";

@interface YZZHotelDownloadVC : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSMutableArray        * m_citys;
@property (strong, nonatomic) NSMutableDictionary   * m_cityFiles;
@property (strong, nonatomic) NSString              * m_querying_city;

@property (strong, nonatomic) NSMutableArray        * m_fetchRateNoneFirstTimeHotels;
@property (strong, nonatomic) NSMutableArray        * m_fetchRateNoneSecondTimeHotels;


@property (strong, nonatomic) NSMutableDictionary   * m_recommendHotelsForExpo;
@property (strong, nonatomic) NSMutableDictionary   * m_code2hotel;
@property (strong, nonatomic) NSMutableDictionary   * m_recommendedDicResult;

@property (strong, nonatomic) NSMutableArray        * m_sqlToPost;

- (IBAction)RunOnce:(id)sender;

@property (strong, nonatomic) IBOutlet UIProgressView *m_ratePV;
@end
