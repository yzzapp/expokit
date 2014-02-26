//
//  YZZMenuVC.h
//  expokit
//
//  Created by 石戬, 姚勤(还没有对象的87) on on 13-4-26.
//  Copyright (c) 2013年 YzzApp.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YZZMenuVC : UIViewController

//1. GET HOTELS NEAR BY AND RATING GOOD ENOUGH!
//get city list                     (from local db EXPO.CITY)
//each city
//  query hotel list in city        (via Net-Request(+5)/Local-Test)
//  get hall list in city           (from local db EXPO.CITY.HALL)
//  each hall
//      get hotel list near hall    (distance filter)
//      remove hotel by rating      (rating filter)
//      hall_step1                  (save db)

//2. GET PRICE FOR HOTELS BY "DATE PLAN" IN FUTURE DATE RANGE.
//make a date range future 30/45 days.
//each hall
//each hotel
//query hotel price rate by date.   (or merge query in group maxium up to 5/more per query)
//or parallal query?
//hotel_step2                       (save db)

//3. MAKING RECOMMEND
//each hall
//algorithm recommend for 5 choice  (3+2)

//4. PUBLISH TO SERVER
//every day
//db synchronizing in table
//record pubish time                (time stamp for check updating and out-time)

//Server Developping Tornado
//recommend hotels for hall (algorithm!)

- (IBAction)actionHotelForCities:(id)sender;
- (IBAction)actionHotelPublish:(id)sender;

- (IBAction)actionFlightForCities:(id)sender;
- (IBAction)actionFlightPublish:(id)sender;

- (IBAction)actionPing:(id)sender;

@end
