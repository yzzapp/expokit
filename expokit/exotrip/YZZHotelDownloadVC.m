//
//  YZZHotelDownloadVC.m
//  expokit
//
//  Created by 石戬, 姚勤(还没有对象的87) on on 13-4-30.
//  Copyright (c) 2013年 YzzApp.com. All rights reserved.
//

#import "YZZHotelDownloadVC.h"
#import "YZZUtil.h"
#import "YZZDatabase.h"

#import "YZZR_H_Model.h"

#import <CommonCrypto/CommonDigest.h>
#import <CoreLocation/CoreLocation.h>
#import "GDataXMLNode.h"
#import "NSString+HTML.h"

#import "OTA_HotelSearchOTA_HotelSearch.h"
#import "OTA_HotelDescriptiveInfoOTA_HotelDescriptiveInfo.h"
#import "OTA_HotelRatePlanOTA_HotelRatePlan.h"

//1. Download:GET HOTELS
//get city list                 (from local db EXPO.CITY)
//each city
//query hotel list in city      (via Net-Request(+5)/Local-Test)

//2. Filter:HOTELS NEAR BY AND RATING GOOD ENOUGH!
//get hall list in city         (from local db EXPO.CITY.HALL)
//each hall
//get hotel list near hall      (distance filter)
//remove hotel by rating        (rating filter)
//hall_step1                    (save File)

#define YZZ_REF_STAR_MIN 3.85f
#define YZZ_REF_STAR_MAX 4.39f
#define YZZ_REF_NEAR_METER 1400.0f
#define YZZ_REF_HOTEL_TIME_DATES 75
#define YZZ_REF_RATE_RESPONSE_LEN_MIN 1200

#define YZZ_REF_REQUEST_INTERVAL 6.5f

@interface YZZHotelDownloadVC ()
@property (strong, nonatomic) NSMutableArray * m_requestHotelRateXmls;
@property int m_pv_sum;
@property int m_pv_footer;
@property int m_seq_index;
@property BOOL m_isSecondTime;
@property (strong, nonatomic) NSString * m_currCity;
@end

@implementation YZZHotelDownloadVC

//- (void)TestMain
//{
//    NSString * content = [YZZUtil READ_FROM_FILE:@"hotel_001.txt"];
//    [self receivedRatePlan:content];
//}

#pragma mark - views

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.m_querying_city = @"";
	self.m_recommendHotelsForExpo   = [[NSMutableDictionary alloc] init];
    self.m_requestHotelRateXmls     = [[NSMutableArray alloc] init];
    self.m_code2hotel               = [[NSMutableDictionary alloc] init];
    self.m_recommendedDicResult     = [[NSMutableDictionary alloc] init];
    
    self.m_fetchRateNoneFirstTimeHotels = [[NSMutableArray alloc] init];
    self.m_fetchRateNoneSecondTimeHotels = [[NSMutableArray alloc] init];

    self.m_sqlToPost                = [[NSMutableArray alloc] init];
    [self.m_sqlToPost addObject:[self CreateSQLForServer]];
    [self tableInit:hotelPlanTablePrefix];
    
    self.m_pv_sum = 0;
    self.m_pv_footer = 0;
    self.m_seq_index = 0;
    self.m_isSecondTime = NO;
    //[self TestMain];
}

- (void)tableInit:(NSString *)tableNamePrefix
{
    NSString * createSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (HOTELCODE TEXT, HOTELNAME TEXT, ROOMCODE TEXT, ROOMNAME TEXT, BEDS TEXT %@)",
                            [self TABLENAME_TODAY],
                            [self TABLECOLS_TODAY]];
//    NSLog(@"createSQL:(%@)",createSQL);
    [YZZDatabase execSQL:createSQL];
}

- (NSString *)TABLECOLS_TODAY
{
    NSString * colsNameList = @"";
    NSString * dayString = [YZZUtil DATE_TODAY_STRING];
    for (int i = 0; i<=YZZ_REF_HOTEL_TIME_DATES; i++) {
        NSArray * date3p = [dayString componentsSeparatedByString:@"-"];
        NSString * mm = [NSString stringWithFormat:@"%02d",[[date3p objectAtIndex:1] intValue]];
        NSString * dd = [NSString stringWithFormat:@"%02d",[[date3p objectAtIndex:2] intValue]];
        NSString * dateString = [NSString stringWithFormat:@"%@%@",mm,dd];
        colsNameList = [colsNameList stringByAppendingFormat:@", '%@' TEXT",dateString];
        dayString = [YZZUtil DATE_DAY_CAL:dayString intDays:+1];
    }
    return colsNameList;
}

- (NSString *)TABLECOLS_MYSQL_TODAY
{
    NSString * colsNameList = @"";
    NSString * dayString = [YZZUtil DATE_TODAY_STRING];
    for (int i = 0; i<=YZZ_REF_HOTEL_TIME_DATES; i++) {
        NSArray * date3p = [dayString componentsSeparatedByString:@"-"];
        NSString * mm = [NSString stringWithFormat:@"%02d",[[date3p objectAtIndex:1] intValue]];
        NSString * dd = [NSString stringWithFormat:@"%02d",[[date3p objectAtIndex:2] intValue]];
        NSString * dateString = [NSString stringWithFormat:@"%@%@",mm,dd];
        colsNameList = [colsNameList stringByAppendingFormat:@", R%@ TEXT",dateString];
        dayString = [YZZUtil DATE_DAY_CAL:dayString intDays:+1];
    }
    return colsNameList;
}

- (NSString *)TABLENAME_TODAY
{
    NSString * tableName = [NSString stringWithFormat:@"%@%@",
                            hotelPlanTablePrefix,
                            [YZZUtil DATE_FORMAT_MMDD:[YZZUtil DATE_TODAY_STRING]]];
    return tableName;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.m_citys count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * identifier = @"cityCell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    [self configCell:cell indexPath:indexPath];
    return cell;
}

- (void)configCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    UILabel * city = (UILabel *)[cell viewWithTag:1001];
    UILabel * count = (UILabel *)[cell viewWithTag:1002];
    //UIProgressView * process = (UIProgressView *)[cell viewWithTag:1003];
    UIButton * start = (UIButton *)[cell viewWithTag:2001];
    UIButton * filter =(UIButton *)[cell viewWithTag:2002];
    UIButton * price = (UIButton *)[cell viewWithTag:2003];
    UIButton * recommend = (UIButton *)[cell viewWithTag:2004];
    
    NSDictionary * dic = [self.m_citys objectAtIndex:indexPath.row];
    [city setText:[dic valueForKey:@"title"]];
    
    NSString * sql = [NSString stringWithFormat:@"SELECT COUNT(*) FROM (SELECT DISTINCT HALL FROM E13CN WHERE CITY = '%@')",
                      [dic valueForKey:@"title"]];
    NSString * cityHallCount = [YZZDatabase execSQL:sql];
    [count setText:cityHallCount];
        
    [start addTarget:self action:@selector(Start:) forControlEvents:UIControlEventTouchUpInside];
    [start setTag:indexPath.row];
    
    [filter addTarget:self action:@selector(Filter:) forControlEvents:UIControlEventTouchUpInside];
    [filter setTag:indexPath.row];
    
    [price addTarget:self action:@selector(Price:) forControlEvents:UIControlEventTouchUpInside];
    [price setTag:indexPath.row];
    
    [recommend addTarget:self action:@selector(Recommend:) forControlEvents:UIControlEventTouchUpInside];
    [recommend setTag:indexPath.row];
}

#pragma mark - action and requests

- (void)Start:(UIButton *)btn
{
    int row = btn.tag;
    NSDictionary * dic = [self.m_citys objectAtIndex:row];
    NSString * city = [dic valueForKey:@"title"];
    [self requestHotelListForCity:city];
}

- (void)requestHotelListForCity:(NSString *)city
{
    NSArray * fileDic = [self.m_cityFiles valueForKey:city];
    NSString * cityCode = [fileDic objectAtIndex:0];
    [self HotelSearchRequest:city cityCode:cityCode];
}

- (void)Filter:(UIButton *)btn
{
    int row = btn.tag;
    NSDictionary * dic = [self.m_citys objectAtIndex:row];
    NSString * city = [dic valueForKey:@"title"];
    NSArray * fileDic = [self.m_cityFiles valueForKey:city];
    NSString * cityFile = [fileDic objectAtIndex:1];
    NSString * content = [YZZUtil READ_FROM_FILE:cityFile];
    
    NSString * selectSQL = [NSString stringWithFormat:@"SELECT DISTINCT HALL.NAME,HALL.LATITUTE,HALL.LONGITUTE FROM HALL INNER JOIN E13CN ON HALL.NAME = E13CN.HALL AND E13CN.CITY = '%@'",city];
    NSArray * hall_arr = [YZZDatabase execSelect:selectSQL];

    for (NSDictionary * hall_dic in hall_arr) {
        NSString * hall_hotel_file = [NSString stringWithFormat:@"expo_hall_%@_hotel.json",[hall_dic valueForKey:@"NAME"]];
        NSArray * arr = [self XmlSplitHotelSearch:content forHall:hall_dic];
        [self dataPrepareHotelCodeDic:arr];
        [YZZUtil WRITE_TO_FILE:[NSString stringWithFormat:@"%@",arr] withName:hall_hotel_file];
        [self.m_recommendHotelsForExpo setValue:arr forKey:[hall_dic valueForKey:@"NAME"]];
    }
    [self PrintData];
}

- (void)dataPrepareHotelCodeDic:(NSArray *)arr
{
    for (NSDictionary * h in arr) {
        NSString * code = [h valueForKey:@"code"];
        NSString * name = [h valueForKey:@"name"];
        [self.m_code2hotel setValue:name forKey:code];
    }
}

- (void)PrintData
{
    NSLog(@"\n");
    int count = 0;
    for (NSString * k in [self.m_recommendHotelsForExpo allKeys]) {
        NSLog(@"%@:%d",k,[[self.m_recommendHotelsForExpo valueForKey:k] count]);
        count += [[self.m_recommendHotelsForExpo valueForKey:k] count];
    }
    NSLog(@"======= Sum:%d ==========",count);
}

- (void)Price:(UIButton *)btn
{
    [self.m_requestHotelRateXmls removeAllObjects];
    int row = btn.tag;
    NSDictionary * dic = [self.m_citys objectAtIndex:row];
    NSString * city = [dic valueForKey:@"title"];
    NSString * selectSQL = [NSString stringWithFormat:@"SELECT DISTINCT HALL.NAME,HALL.LATITUTE,HALL.LONGITUTE FROM HALL INNER JOIN E13CN ON HALL.NAME = E13CN.HALL AND E13CN.CITY = '%@'",city];
    NSArray * hall_arr = [YZZDatabase execSelect:selectSQL];
    for (NSDictionary * hall_dic in hall_arr) {
        NSArray * hotels = [self.m_recommendHotelsForExpo valueForKey:[hall_dic valueForKey:@"NAME"]];
        [self HotelRatePlanRequestPrepare:hotels];
        NSLog(@"city:(%@) has %d hall, and hall (%@) has %d hotels",city,[hall_arr count],[hall_dic valueForKey:@"NAME"],[hotels count]);
    }
    self.m_currCity = city;
    [self PriceSyn];
}

- (void)PriceSyn
{
    NSLog(@"PriceSyn count:(%d)",[self.m_requestHotelRateXmls count]);
    self.m_isSecondTime = NO;
    int i = 0;
    float interval = YZZ_REF_REQUEST_INTERVAL;//time interval per hotel rate request;
    [self.m_fetchRateNoneFirstTimeHotels removeAllObjects];
    self.m_pv_sum = [self.m_requestHotelRateXmls count];
    for (NSString * requestXML in self.m_requestHotelRateXmls) {
        [self performSelector:@selector(HotelRateQueryForIndex:) withObject:[NSNumber numberWithInt:i] afterDelay:(float)i*interval];
        i ++ ;
    }
    [self performSelector:@selector(PrintPriceSynTwice) withObject:nil afterDelay:i*interval];
}

- (void)PrintPriceSynTwice
{
    NSLog(@"PriceSynTwice count:(%d)",[self.m_fetchRateNoneFirstTimeHotels count]);
    self.m_isSecondTime = YES;

    int i = 0;
    float interval = YZZ_REF_REQUEST_INTERVAL;//time interval per hotel rate request;
    [self.m_fetchRateNoneSecondTimeHotels removeAllObjects];
    self.m_pv_sum = [self.m_fetchRateNoneFirstTimeHotels count];
    for (NSDictionary * kv in self.m_fetchRateNoneFirstTimeHotels) {
        NSString * k = [[kv allKeys] objectAtIndex:0];
        int ki = [k intValue];
        [self performSelector:@selector(HotelRateQueryForSecondTime:) withObject:[NSNumber numberWithInt:ki] afterDelay:(float)i*interval];
        i ++ ;
    }
    [self performSelector:@selector(PrintPriceNotSyn) withObject:nil afterDelay:i];
}


- (void)PrintPriceNotSyn
{
    NSLog(@"== PrintPriceNotSyn == %d ==",[self.m_fetchRateNoneSecondTimeHotels count]);
}

//3. MAKING RECOMMEND
//each hall
//algorithm recommend for 5 choice  (3+2)

- (NSMutableDictionary *)recommendHotelsForHall:(NSArray *)hotels hall:(NSMutableDictionary *)hallDic
{
    YZZR_H_Model * rhm = [[YZZR_H_Model alloc] init];
    for (NSMutableDictionary * h in hotels) {
        NSString * code = [h valueForKey:@"code"];
        NSString * roomSQL = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE HOTELCODE = '%@'",
                              [self TABLENAME_TODAY],
                              code];
        NSArray * rooms = [YZZDatabase execSelect:roomSQL];
        for (NSDictionary * room in rooms)
            [rhm trainRoom:room forHotel:h];
        //[rhm trainPrint:h];
    }
    NSMutableDictionary * rDicResult = [rhm recommend:hotels forHall:hallDic];
    return rDicResult;
}

//create auto table
//insert sql data for hall-hotel-room-rate, ready to upload
- (void)saveRecommendHotels:(NSMutableDictionary *)recommendArr forHall:(NSMutableDictionary *)hall_dic
{
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:recommendArr options:NSJSONWritingPrettyPrinted error:nil];
    NSString * jString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString * halljsonfile = [NSString stringWithFormat:@"hotels_%@_recommend.json",[hall_dic valueForKey:@"NAME"]];
    [YZZUtil WRITE_TO_FILE:jString withName:halljsonfile];
    //NSLog(@"RECOMMEND:(%@)",jString);
}

- (void)turnRecommendDicToSQL:(NSMutableDictionary *)recommendArr forHall:(NSMutableDictionary *)hall_dic
{
    NSString * hallname = [hall_dic valueForKey:@"NAME"];
    for (NSString * RECOMMENDTYPE in [recommendArr allKeys]) {
        NSDictionary * recRoomDic = [recommendArr valueForKey:RECOMMENDTYPE];
        [recRoomDic setValue:RECOMMENDTYPE forKey:@"RECOMMENDTYPE"];
        [recRoomDic setValue:hallname forKey:@"HALL"];
        
        NSString * insertSQL = [self analysisSQL:recRoomDic];
        [self.m_sqlToPost addObject:insertSQL];
    }
}

- (NSString *)CreateSQLForServer
{
    NSString * createSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
HOTELCODE TEXT , HOTELNAME TEXT , ROOMCODE TEXT , ROOMNAME TEXT , \
HALL TEXT, RECOMMENDTYPE TEXT , HOTELRATE TEXT , BEDS TEXT , \
HOTELIMAGE TEXT , ADDRESS TEXT , HOTELLONG TEXT , HOTELLAT TEXT %@)",
                            [self TABLENAME_TODAY],
                            [self TABLECOLS_MYSQL_TODAY]];
    return createSQL;
}

- (NSString *)analysisSQL:(NSDictionary *)dic
{
    //INSERT INTO TABLENAME (COL, COL, COL) VALUES (V, V, V)
    NSMutableArray * names = [[NSMutableArray alloc] init];
    NSMutableArray * values = [[NSMutableArray alloc] init];
    for (NSString * k in [dic allKeys]) {
        [names addObject:k];
        [values addObject:[dic valueForKey:k]];
    }

    NSString * colsNameList = @"";
    NSString * valueList = @"";
    for (int i = 0; i< [values count]; i++) {
        NSString * colsString = [names objectAtIndex:i];
        NSString * valueString = [values objectAtIndex:i];
        
        NSString * firstChar = [colsString substringToIndex:1];
        if ([firstChar isEqualToString:@"0"] || [firstChar isEqualToString:@"1"]) {
            colsString = [NSString stringWithFormat:@"R%@",colsString];
        }
        colsNameList = [colsNameList stringByAppendingFormat:@", %@ ",colsString];
        valueList = [valueList stringByAppendingFormat:@", '%@' ",valueString];
    }
    colsNameList = [colsNameList substringFromIndex:1];
    valueList = [valueList substringFromIndex:1];
    
    NSString * insertSQL = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)",
                            [self TABLENAME_TODAY],
                            colsNameList,
                            valueList];
//    NSLog(@"ana:%@",insertSQL);
    return insertSQL;
}

- (void)Recommend:(UIButton *)btn
{
    int row = btn.tag;
    NSDictionary * dic = [self.m_citys objectAtIndex:row];
    NSString * city = [dic valueForKey:@"title"];
    
    NSString * selectSQL = [NSString stringWithFormat:@"SELECT DISTINCT HALL.NAME,HALL.LATITUTE,HALL.LONGITUTE FROM HALL INNER JOIN E13CN ON HALL.NAME = E13CN.HALL AND E13CN.CITY = '%@'",city];
    NSArray * hall_arr = [YZZDatabase execSelect:selectSQL];
    for (NSMutableDictionary * hall_dic in hall_arr) {
        NSString * hall_name = [hall_dic valueForKey:@"NAME"];
        NSArray * hotels = [self.m_recommendHotelsForExpo valueForKey:hall_name];
        NSLog(@"\n");
        //NSLog(@"Hall:(%@)",hall_name);
        NSMutableDictionary * recommendDic = [self recommendHotelsForHall:hotels hall:hall_dic];
        [self saveRecommendHotels:recommendDic forHall:hall_dic];
        [self turnRecommendDicToSQL:recommendDic forHall:hall_dic];
    }
    NSLog(@"== Recommend SUCCESS! ==");
    NSLog(@"SQL LINES:%dL",[self.m_sqlToPost count]);
    NSString * sqls = [self.m_sqlToPost componentsJoinedByString:@";\n"];
    NSString * citySQL = [NSString stringWithFormat:@"%d_sqls_%@_line.txt",row,city];
    [YZZUtil WRITE_TO_FILE:sqls withName:citySQL];
}

#pragma mark - HotelSearch

/*
 <Response>
 <Header ShouldRecordPerformanceTime="False" Timestamp="2013-04-20 13:03:39:29178" ReferenceID="7fdb4bda-771a-4fda-bc3a-cabb7c7c4f97" ResultCode="Success" />
 <HotelResponse>
 <OTA_HotelSearchRS TimeStamp="2013-04-20T13:03:38.8204556+08:00" Version="1.0" PrimaryLangID="zh" xmlns="http://www.opentravel.org/OTA/2003/05">
 <Properties>
 ...
 */
- (NSArray *)XmlSplitHotelSearch:(NSString *)xmlString forHall:(NSDictionary *)hallDic
{
    GDataXMLDocument *gxml = [[GDataXMLDocument alloc] initWithXMLString:xmlString options:0 error:nil];
    NSArray *members = [gxml.rootElement nodesForXPath:@"//Response" error:nil];
    NSArray *Properties = [[[[[[[[members objectAtIndex:0]
                                 elementsForName:@"HotelResponse"] objectAtIndex:0]
                               elementsForName:@"OTA_HotelSearchRS"] objectAtIndex:0]
                             elementsForName:@"Properties"] objectAtIndex:0]
                           elementsForName:@"Property"];
    NSArray *nearbyHotels           = [self filterForRateAndDistance:Properties toHall:hallDic];
    NSArray *nearbyDictArray        = [self hotelFormatingFromXmlToDict:nearbyHotels];
    return nearbyDictArray;
}

- (NSArray *)filterForRateAndDistance:(NSArray *)arr toHall:(NSDictionary *)hall
{
    NSMutableArray *theNewArray = [NSMutableArray arrayWithCapacity:0];
    for (GDataXMLElement *element in arr) {
        
        // Filter : Distance
        GDataXMLElement *position = [[element elementsForName:@"Position"] objectAtIndex:0];
        CGFloat lat = [[[position attributeForName:@"Latitude"] stringValue] floatValue];
        CGFloat longit = [[[position attributeForName:@"Longitude"] stringValue] floatValue];
        CGFloat hall_lat = [[hall valueForKey:@"LATITUTE"] floatValue];
        CGFloat hall_lon = [[hall valueForKey:@"LONGITUTE"] floatValue];
        CLLocationDistance distance = [self distantFromLat:lat
                                                   andLong:longit
                                                    dstLat:hall_lat
                                                   dstLong:hall_lon];
        if (!(distance <= YZZ_REF_NEAR_METER)) continue;
        
        // Filter : STAR
        
//        http://hotels.ctrip.com/hotel/dianping/374783.html#ctm_ref=hd_0_0_0_0_lst_nr_1_df_ls_1_n_hi_0_0_0
        
//        <Property BrandCode="144" HotelCode="71783" HotelCityCode="1" HotelName="北京唐拉雅秀酒店" AreaID="92">

//        <Award Provider="HotelStarRate" Rating="5" />
//        <Award Provider="CtripStarRate" Rating="6" />
//        <Award Provider="CtripRecommendRate" Rating="4.5" />
//        <Award Provider="CtripCommRate" Rating="4.4" />
//        <Award Provider="CommSurroundingRate" Rating="4.4" />
//        <Award Provider="CommFacilityRate" Rating="4.4" />
//        <Award Provider="CommCleanRate" Rating="4.5" />
//        <Award Provider="CommServiceRate" Rating="4.3" />
        
        NSArray *arr = [element elementsForName:@"Award"];
        float Rating = 0.0f;
        for (GDataXMLElement *award in arr) {
            NSString *Provider = [[award attributeForName:@"Provider"] stringValue];
            if ([Provider isEqualToString:@"CtripCommRate"]) {
                Rating = [[[award attributeForName:@"Rating"] stringValue] floatValue];
                break;
            }
        }
        if (Rating >= YZZ_REF_STAR_MAX || Rating <= YZZ_REF_STAR_MIN) continue;
        
        //NSString *HotelName = [[element attributeForName:@"HotelName"] stringValue];
        //NSString *HotelCode = [[element attributeForName:@"HotelCode"] stringValue];
        //NSLog(@"Near Hotel :(%@)%@ Meter:%.0fm Star:%.2f",HotelCode,HotelName,distance,Rating);
        [theNewArray addObject:element];
    }
    //NSLog(@"\n");
    return theNewArray;
}

- (CLLocationDistance)distantFromLat:(CGFloat )lat andLong:(CGFloat)longit dstLat:(CGFloat )dstLat dstLong:(CGFloat)dstLong {
    CLLocation *location1 = [[CLLocation alloc] initWithLatitude:lat longitude:longit];
    CLLocation *location2 = [[CLLocation alloc] initWithLatitude:dstLat longitude:dstLong];
    CLLocationDistance distance = [location1 distanceFromLocation:location2];
    return distance;
}

- (NSArray *)hotelFormatingFromXmlToDict:(NSArray *)arr
{
    NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:0];
    for (GDataXMLElement *tmpElement in arr) {
        NSMutableDictionary *hotel = [NSMutableDictionary dictionaryWithCapacity:0];
        
        NSString * name = [[tmpElement attributeForName:@"HotelName"] stringValue];
        NSString * code = [[tmpElement attributeForName:@"HotelCode"] stringValue];
        NSString * lat  = [[[[tmpElement elementsForName:@"Position"] objectAtIndex:0] attributeForName:@"Latitude"] stringValue];
        NSString * lon  = [[[[tmpElement elementsForName:@"Position"] objectAtIndex:0] attributeForName:@"Longitude"] stringValue];
        NSString * img  = [[[[[[[[[[[tmpElement elementsForName:@"VendorMessages"] objectAtIndex:0]
                                   elementsForName:@"VendorMessage"] objectAtIndex:0]
                                 elementsForName:@"SubSection"] objectAtIndex:0]
                               elementsForName:@"Paragraph"] objectAtIndex:0]
                             elementsForName:@"Text"] objectAtIndex:0] stringValue];
        NSString * addr = [[[[[tmpElement elementsForName:@"Address"] objectAtIndex:0]
                             elementsForName:@"AddressLine"] objectAtIndex:0] stringValue];
        
        NSArray *arr = [tmpElement elementsForName:@"Award"];
        
        float Rating = 0.0f;
        for (GDataXMLElement *award in arr) {
            NSString *Provider = [[award attributeForName:@"Provider"] stringValue];
            if ([Provider isEqualToString:@"CtripCommRate"]) {
                Rating = [[[award attributeForName:@"Rating"] stringValue] floatValue];
                break;
            }
        }

        NSString * rate = [NSString stringWithFormat:@"%.02f",Rating];
        
        [hotel setValue:name    forKey:@"name"];
        [hotel setValue:code    forKey:@"code"];
        [hotel setValue:lat     forKey:@"lat"];
        [hotel setValue:lon     forKey:@"long"];
        [hotel setValue:img     forKey:@"image"];
        [hotel setValue:addr    forKey:@"address"];
        [hotel setValue:rate    forKey:@"rate"];
        [resultArray addObject:hotel];
    }
    return resultArray;
}

//request

/*
 <ns:HotelRef HotelCityCode=\"1\" HotelName=\"北京贵国酒店\"/>\
 <ns:HotelRef HotelCityCode=\"1\"  HotelName=\"桔子酒店·精选（北京三元桥店\"/>\
 <ns:Award Provider=\"HotelStarRate\" Rating=\"3\"/>\
 */

- (void)HotelSearchRequest:(NSString *)cityString cityCode:(NSString *)cityCode
{
    self.m_querying_city = cityString;
    OTA_HotelSearchOTA_HotelSearch *hotelRequest = [OTA_HotelSearchOTA_HotelSearch service];
    NSString *requestBody = [NSString stringWithFormat:@"\
                             <ns:OTA_HotelSearchRQ\
                             Version=\"1.0\" \
                             PrimaryLangID=\"zh\" \
                             xsi:schemaLocation=\"http://www.opentravel.org/OTA/2003/05 OTA_HotelSearchRQ.xsd\" \
                             xmlns=\"http://www.opentravel.org/OTA/2003/05\">\
                             <ns:Criteria AvailableOnlyIndicator=\"true\"> \
                             <ns:Criterion>\
                             <ns:HotelRef HotelCityCode=\"%@\" HotelName=\"%@\"/>\
                             </ns:Criterion>\
                             </ns:Criteria>\
                             </ns:OTA_HotelSearchRQ>",cityCode,cityString];
    NSString *requestXml = [YZZUtil OTA_REQUEST:@"OTA_HotelSearch" body:requestBody];
    [hotelRequest Request:self action:@selector(receivedHotel:) requestXML:requestXml];
}

- (void)receivedHotel:(id)xmlString
{
    NSArray * fileDic = [self.m_cityFiles valueForKey:self.m_querying_city];
    NSString * cityFile = [fileDic objectAtIndex:1];
    [YZZUtil WRITE_TO_FILE:xmlString withName:cityFile];
    NSLog(@"HotelSearch (%@) Length (%d) to File (%@)",self.m_querying_city,[xmlString length],cityFile);
}

//<ns:OTA_HotelRatePlanRQ
//TimeStamp="2013-05-02T00:20:51.3711718+08:00"
//Version="1.0">
//<ns:RatePlans>
//<ns:RatePlan>
//<ns:DateRange Start="2013-05-02" End="2013-06-16"/>
//<ns:RatePlanCandidates>
//<ns:RatePlanCandidate AvailRatesOnlyInd="true">
//<ns:HotelRefs>
//<ns:HotelRef HotelCode="6580"/>
//</ns:HotelRefs>
//</ns:RatePlanCandidate>
//</ns:RatePlanCandidates>
//</ns:RatePlan>
//</ns:RatePlans>
//</ns:OTA_HotelRatePlanRQ>

- (void)HotelRatePlanRequestPrepare:(NSArray *)hotels
{
    NSString * RatePlan = @"";
    NSString * dateIn   = [YZZUtil DATE_DAY_CAL:[YZZUtil DATE_TODAY_STRING] intDays:+0];
    NSString * dateOut  = [YZZUtil DATE_DAY_CAL:[YZZUtil DATE_TODAY_STRING] intDays:+YZZ_REF_HOTEL_TIME_DATES];
    for (NSDictionary *hotel in hotels) {
        NSString * HotelRef = [NSString stringWithFormat:@"<ns:HotelRef HotelCode=\"%@\" />\n",[hotel objectForKey:@"code"]];
    
        RatePlan = [NSString stringWithFormat:@"\
                     <ns:RatePlan>\
                     <ns:DateRange Start=\"%@\" End=\"%@\"/>\
                     <ns:RatePlanCandidates>\
                     <ns:RatePlanCandidate AvailRatesOnlyInd=\"true\">\
                     <ns:HotelRefs>\
                     %@\
                     </ns:HotelRefs>\
                     </ns:RatePlanCandidate>\
                     </ns:RatePlanCandidates>\
                     </ns:RatePlan>",dateIn,dateOut,HotelRef];
        
        NSString *requestBody = [NSString stringWithFormat:@"\
                                 <ns:OTA_HotelRatePlanRQ \
                                 TimeStamp=\"%@T00:00:00.0000000+08:00\" \
                                 Version=\"1.0\">\
                                 <ns:RatePlans>%@</ns:RatePlans>\
                                 </ns:OTA_HotelRatePlanRQ>",
                                 [YZZUtil DATE_TODAY_STRING],
                                 RatePlan];

        NSString *requestXML = [YZZUtil OTA_REQUEST:@"OTA_HotelRatePlan" body:requestBody];
        [self.m_requestHotelRateXmls addObject:requestXML];
    }
}

- (void)HotelRateQuery:(NSString *)requestXML
{
    OTA_HotelRatePlanOTA_HotelRatePlan *ratePlan = [OTA_HotelRatePlanOTA_HotelRatePlan service];
    [ratePlan Request:self action:@selector(receivedRatePlan:) requestXML:requestXML];
}

- (void)HotelRateQueryForIndex:(NSNumber *)i
{
    self.m_pv_footer = [i intValue];
    NSLog(@" i:%d",[i intValue]);
    NSString * requestXML = [self.m_requestHotelRateXmls objectAtIndex:self.m_pv_footer];
    [self performSelector:@selector(HotelRateQuery:) withObject:requestXML];
}

- (void)HotelRateQueryForSecondTime:(NSNumber *)ki
{
    self.m_pv_footer = [ki intValue];
    NSLog(@"ki:%d",[ki intValue]);
    NSString * requestXML = [self.m_requestHotelRateXmls objectAtIndex:self.m_pv_footer];
    [self performSelector:@selector(HotelRateQuery:) withObject:requestXML];
}

- (void)receivedRatePlan:(id)value
{
    float pv = (float)self.m_pv_footer/(float)self.m_pv_sum;
    [self.m_ratePV setProgress:pv animated:YES];
    if ([value length] > YZZ_REF_RATE_RESPONSE_LEN_MIN) {
        [self insertHotelPrice:value];
        NSString * name = [NSString stringWithFormat:@"hotel_%@_%03d.txt",self.m_currCity,self.m_pv_footer];
        [YZZUtil WRITE_TO_FILE:value withName:name];
    } else {
        NSString * k = [NSString stringWithFormat:@"%d",self.m_pv_footer];
        
        if (!self.m_isSecondTime) {
            NSLog(@" i:%@ X",k);
            [self.m_fetchRateNoneFirstTimeHotels addObject:@{k:value}];
        } else {
            NSLog(@" i:%@ XX",k);
            [self.m_fetchRateNoneSecondTimeHotels addObject:@{k:value}];
        }
    }
}

//<RatePlans HotelCode="22607">
//<RatePlan RatePlanCode="33177" RatePlanCategory="16" MarketCode="15">
//<Rates>
//<Rate Start="2013-5-2 0:00:00" End="2013-5-2 0:00:00" Status="OnRequest">
//<BaseByGuestAmts>
//<BaseByGuestAmt AmountBeforeTax="398.00" CurrencyCode="CNY" NumberOfGuests="2" ListPrice="398.00" />
//<SellableProducts>
//<SellableProduct InvCode="50122" />
//</SellableProducts>
//<Description Name="标准房" />
//</RatePlan>

- (void)insertHotelPrice:(NSString *)ratingXmlString
{
    GDataXMLDocument *gxml = [[GDataXMLDocument alloc] initWithXMLString:ratingXmlString options:0 error:nil];
    NSArray *members = [gxml.rootElement nodesForXPath:@"//Response" error:nil];
    NSArray *RatePlans = [[[[[[members objectAtIndex:0]
                                 elementsForName:@"HotelResponse"] objectAtIndex:0]
                               elementsForName:@"OTA_HotelRatePlanRS"] objectAtIndex:0]
                            elementsForName:@"RatePlans"];
    NSString * HotelCode = [[[RatePlans objectAtIndex:0] attributeForName:@"HotelCode"] stringValue];
    NSArray *roomPlans = [[RatePlans objectAtIndex:0] elementsForName:@"RatePlan"];
    
    //NSLog(@"HotelCode:(%@)",HotelCode);
    for (GDataXMLElement * ratePlan in roomPlans) {
        NSString * RoomName = [[[[ratePlan elementsForName:@"Description"] objectAtIndex:0]
                                attributeForName:@"Name"] stringValue];
        NSString * PlanCode = [[ratePlan attributeForName:@"RatePlanCode"] stringValue];
        NSArray * rates = [[[ratePlan elementsForName:@"Rates"] objectAtIndex:0] elementsForName:@"Rate"];
        //NSLog(@"RoomName:(%@)(%d),Code(%@)",RoomName,[rates count],PlanCode);

        NSString * colsDate = @"";
        NSString * colsData = @"";
        NSString * guests = @"";
        for (GDataXMLElement * rate in rates) {
            NSString * date = [[rate attributeForName:@"Start"] stringValue];
            NSString * amount = [[[[[[rate elementsForName:@"BaseByGuestAmts"] objectAtIndex:0]
                                 elementsForName:@"BaseByGuestAmt"] objectAtIndex:0]
                                 attributeForName:@"AmountBeforeTax"] stringValue];
            guests = [[[[[[rate elementsForName:@"BaseByGuestAmts"] objectAtIndex:0]
                                   elementsForName:@"BaseByGuestAmt"] objectAtIndex:0]
                                 attributeForName:@"NumberOfGuests"] stringValue];
            //NSLog(@"date:%@ price:%@ guests:%@",date,amount,guests);
            //2013-5-6 0:00:00
            NSArray * arr = [date componentsSeparatedByString:@" "];
            NSArray * date3p = [[arr objectAtIndex:0] componentsSeparatedByString:@"-"];
            NSString * mm = [NSString stringWithFormat:@"%02d",[[date3p objectAtIndex:1] intValue]];
            NSString * dd = [NSString stringWithFormat:@"%02d",[[date3p objectAtIndex:2] intValue]];
            NSString * dateString = [NSString stringWithFormat:@"%@%@",mm,dd];
            colsDate = [colsDate stringByAppendingFormat:@", '%@'",dateString];
            colsData = [colsData stringByAppendingFormat:@", '%@'",amount];
        }
        NSString * hotelName = [self.m_code2hotel valueForKey:HotelCode];
        NSString * insertSQL = [NSString stringWithFormat:@"INSERT INTO %@ (HOTELCODE, HOTELNAME, ROOMCODE, ROOMNAME, BEDS %@) VALUES ('%@','%@','%@','%@','%@' %@)",
                                [self TABLENAME_TODAY],
                                colsDate,
                                HotelCode,hotelName,PlanCode,RoomName,guests,
                                colsData];
        NSString * dayPrice = [[colsData componentsSeparatedByString:@","] objectAtIndex:1];
//        NSLog(@"%@:%@,%@:%@(%@),%@¥",HotelCode,hotelName,PlanCode,RoomName,guests,dayPrice);
        [YZZDatabase execSQL:insertSQL];
    }
}

#pragma mark - Run Once

#define YZZ_REF_RUN_ONCE_INTERVAL_SECS 12.0f
#define YZZ_REF_RUN_ONCE_FILTER_INTERVAL_SECS 10.0f

- (IBAction)RunOnce:(id)sender {
    
    NSLog(@"== RUN ONCE START! ==");
    int count = [self.m_citys count];
    [self performSelector:@selector(RunDownloadOnce)];
    
    float delay = ((float)(count+1)*YZZ_REF_RUN_ONCE_INTERVAL_SECS);
    [self performSelector:@selector(RunFilterOnce) withObject:nil afterDelay:delay];
    
    delay += count * YZZ_REF_RUN_ONCE_FILTER_INTERVAL_SECS;
    [self performSelector:@selector(RunRatePlanOnce) withObject:nil afterDelay:delay];
    
    // RunRecommendOnce inside RunRatePlanOnce
    
}

- (void)RunDownloadOnce
{
    NSLog(@"== RUN ONCE 1/4 RunDownloadOnce! ==");
    float delySec = 0.0f;
    for (NSDictionary * cityDic in self.m_citys) {
        NSString * city = [cityDic valueForKey:@"title"];
        [self performSelector:@selector(requestHotelListForCity:) withObject:city afterDelay:delySec];
        delySec += YZZ_REF_RUN_ONCE_INTERVAL_SECS;
    }
}

- (void)RunFilterOnce
{
    NSLog(@"== RUN ONCE 2/4 RunFilterOnce! ==");
    for (NSDictionary * dic in self.m_citys) {
        NSString * city = [dic valueForKey:@"title"];
        NSArray * fileDic = [self.m_cityFiles valueForKey:city];
        NSString * cityFile = [fileDic objectAtIndex:1];
        NSString * content = [YZZUtil READ_FROM_FILE:cityFile];
    
        NSString * selectSQL = [NSString stringWithFormat:@"SELECT DISTINCT HALL.NAME,HALL.LATITUTE,HALL.LONGITUTE FROM HALL INNER JOIN E13CN ON HALL.NAME = E13CN.HALL AND E13CN.CITY = '%@'",city];
        NSArray * hall_arr = [YZZDatabase execSelect:selectSQL];
    
        for (NSDictionary * hall_dic in hall_arr) {
            NSString * hall_hotel_file = [NSString stringWithFormat:@"expo_hall_%@_hotel.json",[hall_dic valueForKey:@"NAME"]];
            NSArray * arr = [self XmlSplitHotelSearch:content forHall:hall_dic];
            [self dataPrepareHotelCodeDic:arr];
            [YZZUtil WRITE_TO_FILE:[NSString stringWithFormat:@"%@",arr] withName:hall_hotel_file];
            [self.m_recommendHotelsForExpo setValue:arr forKey:[hall_dic valueForKey:@"NAME"]];
        }
    }
}

- (void)RunRatePlanOnce
{
    NSLog(@"== RUN ONCE 3/4 RunRatePlanOnce! ==");
    [self.m_requestHotelRateXmls removeAllObjects];
    for (NSDictionary * dic in self.m_citys) {
        NSString * city = [dic valueForKey:@"title"];
        NSString * selectSQL = [NSString stringWithFormat:@"SELECT DISTINCT HALL.NAME,HALL.LATITUTE,HALL.LONGITUTE FROM HALL INNER JOIN E13CN ON HALL.NAME = E13CN.HALL AND E13CN.CITY = '%@'",city];
        NSArray * hall_arr = [YZZDatabase execSelect:selectSQL];
        for (NSDictionary * hall_dic in hall_arr) {
            NSArray * hotels = [self.m_recommendHotelsForExpo valueForKey:[hall_dic valueForKey:@"NAME"]];
            [self HotelRatePlanRequestPrepare:hotels];
            //NSLog(@"city:(%@) has %d hall, and hall (%@) has %d hotels",city,[hall_arr count],[hall_dic valueForKey:@"NAME"],[hotels count]);
        }
    }
    self.m_currCity = @"ALL";
    [self PriceSyn];
    int hcount = 0;
    for (NSString * k in [self.m_recommendHotelsForExpo allKeys]) {
        hcount += [[self.m_recommendHotelsForExpo valueForKey:k] count];
    }
    float delay = YZZ_REF_REQUEST_INTERVAL * (hcount+10);
    [self performSelector:@selector(RunRecommendOnce) withObject:nil afterDelay:delay];
}

- (void)RunRecommendOnce
{
    NSLog(@"== RUN ONCE 4/4 RunRecommendOnce! ==");
    for (NSDictionary * dic in self.m_citys) {
        NSString * city = [dic valueForKey:@"title"];
        NSString * selectSQL = [NSString stringWithFormat:@"SELECT DISTINCT HALL.NAME,HALL.LATITUTE,HALL.LONGITUTE FROM HALL INNER JOIN E13CN ON HALL.NAME = E13CN.HALL AND E13CN.CITY = '%@'",city];
        NSArray * hall_arr = [YZZDatabase execSelect:selectSQL];
        for (NSMutableDictionary * hall_dic in hall_arr) {
            NSString * hall_name = [hall_dic valueForKey:@"NAME"];
            NSArray * hotels = [self.m_recommendHotelsForExpo valueForKey:hall_name];
            NSMutableDictionary * recommendDic = [self recommendHotelsForHall:hotels hall:hall_dic];
            [self saveRecommendHotels:recommendDic forHall:hall_dic];
            [self turnRecommendDicToSQL:recommendDic forHall:hall_dic];
        }
    }
    NSLog(@"== RUN ONCE SUCCESS! ==");
    NSLog(@"%@",self.m_sqlToPost);
    NSLog(@"== RUN ONCE SUCCESS! ==");
    NSLog(@"SQL LINES:%dL",[self.m_sqlToPost count]);
    NSString * sqls = [self.m_sqlToPost componentsJoinedByString:@";\n"];
    [YZZUtil WRITE_TO_FILE:sqls withName:@"sqls.txt"];
}

@end
