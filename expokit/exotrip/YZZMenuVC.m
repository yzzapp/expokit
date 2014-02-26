//
//  YZZMenuVC.m
//  expokit
//
//  Created by 石戬, 姚勤(还没有对象的87) on on 13-4-26.
//  Copyright (c) 2013年 YzzApp.com. All rights reserved.
//

#import "YZZMenuVC.h"
#import "YZZUtil.h"
#import "YZZDatabase.h"

#import <CommonCrypto/CommonDigest.h>
#import <CoreLocation/CoreLocation.h>
#import "GDataXMLNode.h"
#import "NSString+HTML.h"

#import "OTA_PingOTA_Ping.h"
#import "OTA_HotelSearchOTA_HotelSearch.h"
#import "OTA_HotelDescriptiveInfoOTA_HotelDescriptiveInfo.h"
#import "OTA_HotelRatePlanOTA_HotelRatePlan.h"

#import "YZZHotelDownloadVC.h"
#import "YZZHotelPubVC.h"
#import "YZZPlaneDataVC.h"
#import "YZZPlanePubVC.h"

#define YZZ_LOCAL_TEST  YES

@interface YZZMenuVC ()
@property (strong, nonatomic) NSMutableArray * m_citys;
@property (strong, nonatomic) NSMutableDictionary * m_local_hotel_city_dic;

@end

@implementation YZZMenuVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self dataInit];
}

- (void)dataInit
{
    self.m_citys = [[NSMutableArray alloc] init];
    [self.m_citys addObjectsFromArray:@[
     @{@"title":@"北京"},
     @{@"title":@"上海"},
     @{@"title":@"成都"},
     @{@"title":@"广州"},
     @{@"title":@"深圳"},
  ]];
    
    self.m_local_hotel_city_dic = [[NSMutableDictionary alloc] init];
    [self.m_local_hotel_city_dic setDictionary:@{
      @"北京" : @[@"1",  @"expo_hotels_bj.txt"],
      @"上海" : @[@"2",  @"expo_hotels_sh.txt"],
      @"广州" : @[@"32", @"expo_hotels_gz.txt"],
      @"成都" : @[@"28", @"expo_hotels_cd.txt"],
      @"深圳" : @[@"30", @"expo_hotels_sz.txt"],
      }];
}

- (IBAction)actionHotelForCities:(id)sender {
    UIStoryboard * sb = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    YZZHotelDownloadVC * downVC = [sb instantiateViewControllerWithIdentifier:@"YZZHotelDownloadVC"];
    downVC.m_citys = self.m_citys;
    downVC.m_cityFiles = self.m_local_hotel_city_dic;
    [self.navigationController pushViewController:downVC animated:YES];
}

- (IBAction)actionHotelPublish:(id)sender {
    UIStoryboard * sb = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    YZZHotelPubVC * hotelPublishVC = [sb instantiateViewControllerWithIdentifier:@"YZZHotelPubVC"];
    [self.navigationController pushViewController:hotelPublishVC animated:YES];
}

- (IBAction)actionFlightForCities:(id)sender {
    UIStoryboard * sb = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    YZZPlaneDataVC * planeDataVC = [sb instantiateViewControllerWithIdentifier:@"YZZPlaneDataVC"];
    [self.navigationController pushViewController:planeDataVC animated:YES];
}

- (IBAction)actionFlightPublish:(id)sender {
    UIStoryboard * sb = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    YZZPlanePubVC * planePubVC = [sb instantiateViewControllerWithIdentifier:@"YZZPlanePubVC"];
    [self.navigationController pushViewController:planePubVC animated:YES];
}

- (IBAction)actionPing:(id)sender {
    //
}

@end
