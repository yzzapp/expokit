//
//  YZZPlaneDataVC.m
//  expokit
//
//  Created by 石戬, 姚勤(还没有对象的87) on on 13-5-7.
//  Copyright (c) 2013年 YzzApp.com. All rights reserved.
//

#import "YZZPlaneDataVC.h"
#import "YZZUtil.h"
#import "YZZDatabase.h"

#import <CommonCrypto/CommonDigest.h>
#import <CoreLocation/CoreLocation.h>
#import "GDataXMLNode.h"
#import "NSString+HTML.h"

#import "OTA_FlightSearchOTA_FlightSearch.h"

//NSString * selEarlyLine0845 = @"price  99999";
//NSString * selMorningLine1300 = @"price  99999";
//NSString * selMiddleLine1700 = @"price  99999";
//NSString * selEveningLine2130 = @"price  99999";
//NSString * selLateLine0130 = @"price  99999";

#define YZZ_REF_AIR_TABLE @"AIR_CACHE"
#define YZZ_REF_AIR_START 2888

//77,78,79, +227,   461,    513,    705,
//1008,     1083,   1312,   1362,   1439,   1591,
//2300,     2502,   2732,   2887

#define YZZ_REF_DAYS 45
#define YZZ_REF_RATE_RESPONSE_LEN_MIN 1200

#define YZZ_REF_REQUEST_INTERVAL 3.0f
#define YZZ_REF_REQUEST_LEN 4

#define YZZ_REF_AIR_TEST_COUNT 30
@interface YZZPlaneDataVC ()
@property int m_receivedFooter;
@property int m_receivedCounter;
@property (strong, nonatomic) NSString * m_bigString;
@end

@implementation YZZPlaneDataVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self dataInit];
}

- (void)dataInit
{
    NSString * sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (ID INTEGER PRIMARY KEY, LINE TEXT)",YZZ_REF_AIR_TABLE];
    [YZZDatabase execSQL:sql];
    self.m_dstCitys = [[NSMutableArray alloc] init];
    [self.m_dstCitys addObjectsFromArray:@[
     @{@"CITY":@"北京",@"CODE":@"BJS"},
     @{@"CITY":@"上海",@"CODE":@"SHA"},
     @{@"CITY":@"成都",@"CODE":@"CTU"},
     @{@"CITY":@"广州",@"CODE":@"CAN"},
     @{@"CITY":@"深圳",@"CODE":@"SZX"},
     ]];
    
    self.m_planeCitys = [[NSMutableArray alloc] init];
    NSString * cityLocationFilePath = [[NSBundle mainBundle] pathForResource:@"city_location" ofType:@"txt"];
    NSString * cityContent = [NSString stringWithContentsOfFile:cityLocationFilePath encoding:NSUTF8StringEncoding error:nil];

    self.m_cityCodeDic = [[NSMutableDictionary alloc] init];
    for (NSString * line in [cityContent componentsSeparatedByString:@"\n"]) {
        NSArray * lineArr = [line componentsSeparatedByString:@","];
        [self.m_planeCitys addObject:@{
         @"CITY":[lineArr objectAtIndex:0],
         @"CODE":[lineArr objectAtIndex:1],
         @"LON":[lineArr objectAtIndex:2],
         @"LAT":[lineArr objectAtIndex:3],
         }];
        [self.m_cityCodeDic setValue:[lineArr objectAtIndex:0] forKey:[lineArr objectAtIndex:1]];
    }
//    NSLog(@"%@",self.m_planeCitys);
    self.m_requestBlocks = [[NSMutableArray alloc] init];
    self.m_mistakeDic = [[NSMutableDictionary alloc] init];
    self.m_mistakeContentDic = [[NSMutableDictionary alloc] init];
    self.m_bigString = @"";
}

- (void)runAirData
{
    [self runAddingRequestsFixSrcCityFixDstCity];
    [self playRequests];
}

- (void)runTest
{
//    [self runFakeAddingRequestsFixSrcCityFixDstCity];
    [self runAddingRequestsFixSrcCityFixDstCity];
    [self playFakeTestRequests];
}

- (void)runAddingRequestsFixSrcCityFixDstCity
{
    [self.m_requestBlocks removeAllObjects];

    NSString *arriveCode = @"";
    NSString *departCode = @"";
    NSString *departDate = @"";
    for (NSDictionary * arriveCityDic in self.m_dstCitys) {
        arriveCode = [arriveCityDic valueForKey:@"CODE"];
        
        for (NSDictionary * cityDic in self.m_planeCitys) {
            departCode = [cityDic valueForKey:@"CODE"];
            if ([departCode isEqualToString:arriveCode]) continue;
            
            for (int i = 1; i<= YZZ_REF_DAYS; i++) {
                departDate = [YZZUtil DATE_DAY_CAL:[YZZUtil DATE_TODAY_STRING] intDays:+i];
                // double side flying query
                [self.m_requestBlocks addObject:[NSString stringWithFormat:@"<FlightRoute><DepartCity>%@</DepartCity><ArriveCity>%@</ArriveCity><DepartDate>%@</DepartDate></FlightRoute>",departCode,arriveCode,departDate]];
                [self.m_requestBlocks addObject:[NSString stringWithFormat:@"<FlightRoute><DepartCity>%@</DepartCity><ArriveCity>%@</ArriveCity><DepartDate>%@</DepartDate></FlightRoute>",arriveCode,departCode,departDate]];
            }
            
        }
        
    }
    
}

- (void)runFakeAddingRequestsFixSrcCityFixDstCity
{
    [self.m_requestBlocks removeAllObjects];
    
    NSString *arriveCode = @"CAN";
    NSString *departCode = @"";
    NSString *departDate = @"";
    for (NSDictionary * cityDic in self.m_planeCitys) {
        departCode = [cityDic valueForKey:@"CODE"];
        if ([departCode isEqualToString:arriveCode]) continue;
        for (int i = 1; i<= YZZ_REF_DAYS; i++) {
            departDate = [YZZUtil DATE_DAY_CAL:[YZZUtil DATE_TODAY_STRING] intDays:+i];
            [self.m_requestBlocks addObject:[NSString stringWithFormat:@"<FlightRoute><DepartCity>%@</DepartCity><ArriveCity>%@</ArriveCity><DepartDate>%@</DepartDate></FlightRoute>",departCode,arriveCode,departDate]];
        }
    }
}

- (void)playRequests
{
    int group_step = YZZ_REF_REQUEST_LEN;
    int start = YZZ_REF_AIR_START;
    int count = [self.m_requestBlocks count];
    int timer = 0;
    int timer_interval = YZZ_REF_REQUEST_INTERVAL;
    self.m_receivedCounter = count;

    while (start + group_step < count) {
        NSRange subRange = NSMakeRange(start, group_step);
        NSString * content = [[self.m_requestBlocks subarrayWithRange:subRange] componentsJoinedByString:@" "];
        timer = timer + timer_interval;
        [self performSelector:@selector(flightSearchRequest:) withObject:content afterDelay:timer];
        start = start + group_step;
    }
    NSRange subRange = NSMakeRange(start, count-start);
    NSString * content = [[self.m_requestBlocks subarrayWithRange:subRange] componentsJoinedByString:@" "];
    timer = timer + timer_interval;
    [self performSelector:@selector(flightSearchRequest:) withObject:content afterDelay:timer];
}

- (void)playFakeTestRequests
{
    NSLog(@"requests (%d) ",[self.m_requestBlocks count]);
    int group_step = YZZ_REF_REQUEST_LEN;
    int start = 0;
    int count = YZZ_REF_AIR_TEST_COUNT;//[self.m_requestBlocks count];
    int timer = 0;
    int timer_interval = YZZ_REF_REQUEST_INTERVAL;
    self.m_receivedCounter = count;
    
    while (start + group_step < count) {
        NSRange subRange = NSMakeRange(start, group_step);
        NSString * content = [[self.m_requestBlocks subarrayWithRange:subRange] componentsJoinedByString:@" "];
        timer = timer + timer_interval;
        [self performSelector:@selector(flightSearchRequest:) withObject:content afterDelay:timer];
        start = start + group_step;
    }
    NSRange subRange = NSMakeRange(start, count-start);
    NSString * content = [[self.m_requestBlocks subarrayWithRange:subRange] componentsJoinedByString:@" "];
    timer = timer + timer_interval;
    [self performSelector:@selector(flightSearchRequest:) withObject:content afterDelay:timer];
}

#pragma mark - FlightSearch

//    <FlightSearchRequest>
//    <SearchType>S</SearchType>
//    <Routes>
//    <FlightRoute>
//    <DepartCity>SHA</DepartCity>
//    <ArriveCity>BJS</ArriveCity>
//    <DepartDate>2013-05-20</DepartDate>
//    <AirlineDibitCode></AirlineDibitCode>
//    <DepartPort></DepartPort>
//    <ArrivePort></ArrivePort>
//    <EarliestDepartTime>0001-01-01T00:00:00</EarliestDepartTime>
//    <LatestDepartTime>0001-01-01T00:00:00</LatestDepartTime>
//    </FlightRoute>
//    </Routes>
//    <SendTicketCity>SHA</SendTicketCity>
//    <IsSimpleResponse>false</IsSimpleResponse>
//    <IsLowestPrice>false</IsLowestPrice>
//    <PriceTypeOptions>
//    <string>NormalPrice</string>
//    </PriceTypeOptions>
//    <ProductTypeOptions></ProductTypeOptions>
//    <OrderBy>DepartTime</OrderBy>
//    <Direction>ASC</Direction>
//    </FlightSearchRequest>

- (void)flightSearchRequest:(NSString *)content
{
    NSString *type = @"S"; //S（单程）D（往返程）M（联程)
    NSString *bookDate = [YZZUtil DATE_TODAY_STRING];
    OTA_FlightSearchOTA_FlightSearch *flight = [OTA_FlightSearchOTA_FlightSearch service];
    NSString *requestBody = [NSString stringWithFormat:@"\
                             <SearchType>%@</SearchType>\
                             <Routes>%@</Routes>\
                             <BookDate>%@</BookDate>\
                             <Direction>ASC</Direction>",
                             type,
                             content,
                             bookDate];
    
    NSString *requestXml = [YZZUtil OTA_FLIGHT_REQUEST:@"OTA_FlightSearch" body:requestBody];
//    NSLog(@"requestXML:(%@)",requestXml);
    [flight Request:self action:@selector(receivedFlight:) requestXML:requestXml];
}

- (void)receivedFlight:(id)value
{
    static int respond_counter = YZZ_REF_AIR_START;
    respond_counter++;
//    if (respond_counter<=4) {
//        [YZZUtil WRITE_TO_FILE:value withName:[NSString stringWithFormat:@"A_i_r_%d.txt",respond_counter]];
//    }
    float pv = YZZ_REF_REQUEST_LEN*(float)respond_counter/(float)self.m_receivedCounter;
    [self.m_ratePV setProgress:pv animated:YES];
    if ([value length] > YZZ_REF_RATE_RESPONSE_LEN_MIN) {
        [self processAirLine:value i:respond_counter];
    } else {
        int v = [value length];
        NSString * k = [NSString stringWithFormat:@"%d",v];
        [self.m_mistakeContentDic setValue:value forKey:k];
        NSString * counter = [self.m_mistakeDic valueForKey:k];
        if ([counter isEqualToString:@""] || counter == nil) {
            counter = @"0";
            NSLog(@" %d : %@",v,value);
        }
        int c = [counter intValue];c++;
        counter = [NSString stringWithFormat:@"%d",c];
        NSLog(@"FIND NO FLGIHT BETWEEN CITYS HERE: @\"%@\" = %@ ",k,counter);
        [self.m_mistakeDic setValue:counter forKey:k];
    }
    if (pv>=1.0f) {
        NSLog(@"Received All. And mistakes:(%@)(%@)",self.m_mistakeDic,self.m_mistakeContentDic);
        [YZZUtil WRITE_TO_FILE:self.m_bigString withName:@"A__I__R.txt"];
    } else {
        if ([self.m_bigString length]>400000) {
            NSString * airFile = [NSString stringWithFormat:@"air_%d.txt",(int)(pv*100)];
            [YZZUtil WRITE_TO_FILE:self.m_bigString withName:airFile];
            self.m_bigString = @"";
        }
        NSLog(@"pv:%f %d %d",pv,respond_counter,[self.m_bigString length]);
    }
}

#pragma mark - process airline
//<Response>
//<Header ShouldRecordPerformanceTime="False" Timestamp="2013-05-07 23:06:34:70612" ReferenceID="f7879c76-54de-4aeb-be01-2d6f63ce44ad" ResultCode="Success" />
//<FlightSearchResponse>
//<FlightRoutes>
//<DomesticFlightRoute>
//<RecordCount>195</RecordCount>
//<Direction>ASC</Direction>
//<FlightsList>
//<DomesticFlightData>
//<DepartCityCode>BJS</DepartCityCode>
//<ArriveCityCode>CAN</ArriveCityCode>
//<TakeOffTime>2013-05-11T08:30:00</TakeOffTime>
//<ArriveTime>2013-05-11T11:45:00</ArriveTime>
//<Flight>CZ3108</Flight>
//<CraftType>321</CraftType>
//<AirlineCode>CZ</AirlineCode>
//<Class>F</Class>
//<SubClass>P</SubClass>
//<DisplaySubclass>P</DisplaySubclass>
//<Rate>0.43</Rate>
//<Price>2210</Price>
//<StandardPrice>5100.0000</StandardPrice>
//<ChildStandardPrice>2550</ChildStandardPrice>
//<BabyStandardPrice>510</BabyStandardPrice>
//<MealType>C</MealType>
//<AdultTax>50</AdultTax>
//<BabyTax>0</BabyTax>
//<ChildTax>0</ChildTax>
//<AdultOilFee>110.0000</AdultOilFee>
//<BabyOilFee>0</BabyOilFee>
//<ChildOilFee>50.0000</ChildOilFee>
//<DPortCode>PEK</DPortCode>
//<APortCode>CAN</APortCode>
//<DPortBuildingID>2</DPortBuildingID>
//<APortBuildingID>47</APortBuildingID>
//<StopTimes>0</StopTimes>
//<Nonrer>H</Nonrer>
//<Nonend>T</Nonend>
//<Nonref>H</Nonref>
//<Rernote>起飞前后变更按订座舱位公布运价收取5％变更费。</Rernote>
//<Endnote>不得签转。</Endnote>
//<Refnote>起飞前后退票按订座舱位公布运价收取10％退票费。</Refnote>
//<Remarks>儿童加CHD。</Remarks>
//<TicketType>0101</TicketType>
//<BeforeFlyDate>3</BeforeFlyDate>
//<Quantity>5</Quantity>
//<PriceType>SingleTripPrice</PriceType>
//<ProductType />
//<ProductSource>1</ProductSource>
//<InventoryType>Fav</InventoryType>
//<RouteIndex>0</RouteIndex>
//<NeedApplyString>F</NeedApplyString>
//<Recommend>2</Recommend>
//<RefundFeeFormulaID>53</RefundFeeFormulaID>
//<CanUpGrade>true</CanUpGrade>
//<CanSeparateSale />
//<CanNoDefer>false</CanNoDefer>
//<IsFlyMan>false</IsFlyMan>
//<OnlyOwnCity>true</OnlyOwnCity>
//<IsLowestPrice>false</IsLowestPrice>
//<IsLowestCZSpecialPrice>false</IsLowestCZSpecialPrice>
//<PunctualityRate>86.21</PunctualityRate>
//<PolicyID>194705151</PolicyID>
//<AllowCPType>1111</AllowCPType>
//<OutOfPostTime>false</OutOfPostTime>
//<OutOfSendGetTime>false</OutOfSendGetTime>
//<OutOfAirlineCounterTime>false</OutOfAirlineCounterTime>
//<CanPost>true</CanPost>
//<CanAirlineCounter>false</CanAirlineCounter>
//<CanSendGet>true</CanSendGet>
//<IsRebate>true</IsRebate>
//<RebateAmount>50</RebateAmount>
//<RebateCPCity />
//</DomesticFlightData>

- (void)processAirLine:(NSString *)value i:(int)i
{
    
    NSMutableDictionary * valueDic = [self processAirValue:value];
    //NSString * f = [NSString stringWithFormat:@"AIR_SEL_%@_%@_%04d.txt",[YZZUtil DATE_TODAY_STRING],[valueDic valueForKey:@"PAIR"],i];
//    NSLog(@"%d/%d %@ : %d",YZZ_REF_REQUEST_LEN*i,[self.m_requestBlocks count],f,[value length]);
    //[YZZUtil WRITE_TO_FILE:value withName:f];
    
}

- (NSMutableDictionary *)processAirValue:(NSString *)value
{
    GDataXMLDocument *gxml = [[GDataXMLDocument alloc] initWithXMLString:value options:0 error:nil];
    NSArray *response = [gxml.rootElement nodesForXPath:@"//Response" error:nil];
    NSArray *DomesticFlightRoutes = [[[[[[response objectAtIndex:0]
                                        elementsForName:@"FlightSearchResponse"] objectAtIndex:0]
                                       elementsForName:@"FlightRoutes"] objectAtIndex:0]
                                     elementsForName:@"DomesticFlightRoute"];
    for (GDataXMLElement * domesticFightRoute in DomesticFlightRoutes) {
        NSString * recordCount = [[[domesticFightRoute elementsForName:@"RecordCount"] objectAtIndex:0] stringValue];
        int rCount = [recordCount intValue];
        
        if (rCount == 0) {
            NSLog(@"FIND COUNT 0 IN ROUTE");
            continue;
        }
        
        NSString * departCode = @"";
        NSString * arriveCode = @"";
        NSString * takeOffDate = @"";
        NSString * airLineContent = @"";
        NSArray * DomesticFlightDatas = [[[domesticFightRoute elementsForName:@"FlightsList"] objectAtIndex:0]
                                                elementsForName:@"DomesticFlightData"];
        for (GDataXMLElement * DomesticFlightData in DomesticFlightDatas) {
            
            airLineContent = [self processAirFilter:DomesticFlightData withLine:airLineContent];
            
            departCode = [[[DomesticFlightData elementsForName:@"DepartCityCode"] objectAtIndex:0] stringValue];
            arriveCode = [[[DomesticFlightData elementsForName:@"ArriveCityCode"] objectAtIndex:0] stringValue];
            takeOffDate = [[[DomesticFlightData elementsForName:@"TakeOffTime"] objectAtIndex:0] stringValue];
        }
        
        airLineContent = [self recommendAir:airLineContent];

        takeOffDate = [[takeOffDate componentsSeparatedByString:@"T"] objectAtIndex:0];
        takeOffDate = [YZZUtil DATE_FORMAT_MMDD:takeOffDate];
        NSString * lineName = [NSString stringWithFormat:@"<AIRLINE>%@_%@_%@",departCode,arriveCode,takeOffDate];
        NSString * newLine = [NSString stringWithFormat:@"%@\n%@\n",lineName,[airLineContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        self.m_bigString = [self.m_bigString stringByAppendingFormat:newLine];
        NSString * insertSQL = [NSString stringWithFormat:@"INSERT INTO %@ (LINE) VALUES ('%@')",YZZ_REF_AIR_TABLE,newLine];
        [YZZDatabase execSQL:insertSQL];
        
//        NSLog(@"len:%d",[self.m_bigString length]);
        //NSLog(@"fileName:%@",fileName);
        //[YZZUtil WRITE_TO_FILE:airLineContent withName:fileName];
    }
    
//    NSMutableDictionary * selectAirLines = [[NSMutableDictionary alloc] init];
//    [selectAirLines setValue:@"BJS_CAN" forKey:@"PAIR"];
    return nil;
}

- (NSString *)recommendAir:(NSString *)content
{
    content = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray * lines = [content componentsSeparatedByString:@"\n"];
    if ([lines count]<=5) return content;
    
    NSString * selEarlyLine0845 = @"price  99999";
    NSString * selMorningLine1300 = @"price  99999";
    NSString * selMiddleLine1700 = @"price  99999";
    NSString * selEveningLine2130 = @"price  99999";
    NSString * selLateLine0130 = @"price  99999";
    
    for (NSString * line in lines) {
//CTU,BJS,2013-05-09T19:45:00,2013-05-09T22:25:00,CZ3904  580,1440,0.40,50,110.0000,10  86.67  Y,X,X  CTU,90,PEK,2
        
//        NSString * line = [NSString stringWithFormat:@"%@,%@,%@,%@,%@  %@,%d,%@,%@,%@,%@  %@  %@,%@,%@  %@,%@,%@,%@",
//                           departCityCode,arriveCityCode,takeOffTime,arriveTime,flight,
//                           price,[standardPrice intValue],rate,tax,oilfee,quantity,
//                           punctuality,
//                           fClass,fSubClass,fDisplayClass,
//                           dPortCode,dPortBuilding,aPortCode,aPortBuilding];
        NSArray * partsOfLine = [line componentsSeparatedByString:@"  "];
        NSString * takeOffTime = [[[partsOfLine objectAtIndex:0] componentsSeparatedByString:@","] objectAtIndex:2];
        NSString * timeString = [[[[takeOffTime componentsSeparatedByString:@"T"] objectAtIndex:1]
                                  componentsSeparatedByString:@":"] componentsJoinedByString:@""];
//        NSLog(@"timeString:%@",timeString);
        int timeNumber = [timeString intValue];
        int ticketPrice = [[[[partsOfLine objectAtIndex:1] componentsSeparatedByString:@","] objectAtIndex:0] intValue];
        
        if (13100 <= timeNumber && timeNumber <= 83000) {
            NSArray * partsOfLine = [selEarlyLine0845 componentsSeparatedByString:@"  "];
            int partPrice = [[[[partsOfLine objectAtIndex:1] componentsSeparatedByString:@","] objectAtIndex:0] intValue];
            if (ticketPrice >= partPrice) continue;
            selEarlyLine0845 = line;
        }
        
        if (83100 <= timeNumber && timeNumber <= 130000) {
            NSArray * partsOfLine = [selMorningLine1300 componentsSeparatedByString:@"  "];
            int partPrice = [[[[partsOfLine objectAtIndex:1] componentsSeparatedByString:@","] objectAtIndex:0] intValue];
            if (ticketPrice >= partPrice) continue;
            selMorningLine1300 = line;
        }
        
        if (130100 <= timeNumber && timeNumber <= 170000) {
            NSArray * partsOfLine = [selMiddleLine1700 componentsSeparatedByString:@"  "];
            int partPrice = [[[[partsOfLine objectAtIndex:1] componentsSeparatedByString:@","] objectAtIndex:0] intValue];
            if (ticketPrice >= partPrice) continue;
            selMiddleLine1700 = line;
        }
        
        if (170100 <= timeNumber && timeNumber <= 213000) {
            NSArray * partsOfLine = [selEveningLine2130 componentsSeparatedByString:@"  "];
            int partPrice = [[[[partsOfLine objectAtIndex:1] componentsSeparatedByString:@","] objectAtIndex:0] intValue];
            if (ticketPrice >= partPrice) continue;
            selEveningLine2130 = line;
        }
        
        if (213100 <= timeNumber || timeNumber <= 13000) {
            NSArray * partsOfLine = [selLateLine0130 componentsSeparatedByString:@"  "];
            int partPrice = [[[[partsOfLine objectAtIndex:1] componentsSeparatedByString:@","] objectAtIndex:0] intValue];
            if (ticketPrice >= partPrice) continue;
            selLateLine0130 = line;
        }
    }
    NSString * mergedLines = @"";
    for (NSString * line in @[selEarlyLine0845,selMorningLine1300,selMiddleLine1700,selEveningLine2130,selLateLine0130]) {
        if ([line isEqualToString:@"price  99999"]) continue;
        mergedLines = [NSString stringWithFormat:@"%@\n%@",mergedLines,line];
    }
    //NSLog(@"mergedLines(%@)",mergedLines);
    return mergedLines;
}

#define YZZ_REF_AIR_FILTER_PUNCTUALITY 85.00f
#define YZZ_REF_AIR_FILTER_CLASS_1 @"F" 
#define YZZ_REF_AIR_FILTER_RATE 0.98f

- (NSString *)processAirFilter:(GDataXMLElement *)domesticFlight withLine:(NSString *)content
{
    //[self TestWriteFileFor:domesticFlight];
    
    // CITY , TIME
    NSString * departCityCode   = [[[domesticFlight elementsForName:@"DepartCityCode"] objectAtIndex:0] stringValue];
    NSString * arriveCityCode   = [[[domesticFlight elementsForName:@"ArriveCityCode"] objectAtIndex:0] stringValue];
    NSString * takeOffTime      = [[[domesticFlight elementsForName:@"TakeOffTime"] objectAtIndex:0] stringValue];
    NSString * arriveTime       = [[[domesticFlight elementsForName:@"ArriveTime"] objectAtIndex:0] stringValue];
    NSString * punctuality      = [[[domesticFlight elementsForName:@"PunctualityRate"] objectAtIndex:0] stringValue];
    if ([punctuality floatValue]<= YZZ_REF_AIR_FILTER_PUNCTUALITY) {
        return content;
    }
    
    // Flight
    NSString * flight           = [[[domesticFlight elementsForName:@"Flight"] objectAtIndex:0] stringValue];
    //NSString * craft            = [[[domesticFlight elementsForName:@"CraftType"] objectAtIndex:0] stringValue];
    NSString * fClass           = [[[domesticFlight elementsForName:@"Class"] objectAtIndex:0] stringValue];
    NSString * fSubClass        = [[[domesticFlight elementsForName:@"SubClass"] objectAtIndex:0] stringValue];
    NSString * fDisplayClass    = [[[domesticFlight elementsForName:@"DisplaySubclass"] objectAtIndex:0] stringValue];
    if ([fClass isEqualToString:YZZ_REF_AIR_FILTER_CLASS_1]) {
        return content;
    }
    
    // Price & amount
    NSString * rate             = [[[domesticFlight elementsForName:@"Rate"] objectAtIndex:0] stringValue];
    NSString * price            = [[[domesticFlight elementsForName:@"Price"] objectAtIndex:0] stringValue];
    NSString * standardPrice    = [[[domesticFlight elementsForName:@"StandardPrice"] objectAtIndex:0] stringValue];
    NSString * tax              = [[[domesticFlight elementsForName:@"AdultTax"] objectAtIndex:0] stringValue];
    NSString * oilfee           = [[[domesticFlight elementsForName:@"AdultOilFee"] objectAtIndex:0] stringValue];
    oilfee = [NSString stringWithFormat:@"%d",(int)[oilfee floatValue]];
    
    NSString * quantity         = [[[domesticFlight elementsForName:@"Quantity"] objectAtIndex:0] stringValue];
    //NSString * recommend        = [[[domesticFlight elementsForName:@"Recommend"] objectAtIndex:0] stringValue];
    NSString * isLowest         = [[[domesticFlight elementsForName:@"IsLowestPrice"] objectAtIndex:0] stringValue];

    // 携程返点，不进行记录。
//    NSString * isRebate         = [[[domesticFlight elementsForName:@"IsRebate"] objectAtIndex:0] stringValue];
//    NSString * rebateAmount     = [[[domesticFlight elementsForName:@"RebateAmount"] objectAtIndex:0] stringValue];
    if ([quantity intValue] < 5) {
        return content;
    }
    if ([isLowest boolValue] != true) {
        return content;
    }
    if ([rate floatValue] >= YZZ_REF_AIR_FILTER_RATE) {
        return content;
    }

    // AirPort Info
    NSString * dPortCode        = [[[domesticFlight elementsForName:@"DPortCode"] objectAtIndex:0] stringValue];
    NSString * aPortCode        = [[[domesticFlight elementsForName:@"APortCode"] objectAtIndex:0] stringValue];
    NSString * dPortBuilding    = [[[domesticFlight elementsForName:@"DPortBuildingID"] objectAtIndex:0] stringValue];
    NSString * aPortBuilding    = [[[domesticFlight elementsForName:@"APortBuildingID"] objectAtIndex:0] stringValue];
    NSString * stopTimes        = [[[domesticFlight elementsForName:@"StopTimes"] objectAtIndex:0] stringValue];
    if (![stopTimes isEqualToString:@"0"]) {
        return content;
    }
    
    NSString * line = [NSString stringWithFormat:@"%@,%@,%@,%@,%@  %@,%d,%@,%@,%@,%@  %@  %@,%@,%@  %@,%@,%@,%@",
                       departCityCode,arriveCityCode,takeOffTime,arriveTime,flight,
                       price,[standardPrice intValue],rate,tax,oilfee,quantity,
                       punctuality,
                       fClass,fSubClass,fDisplayClass,
                       dPortCode,dPortBuilding,aPortCode,aPortBuilding];
                        //isLowest,
    content = [NSString stringWithFormat:@"%@\n%@",content,line];
    return content;
}

- (void)TestWriteFileFor:(GDataXMLElement *)domesticFlight
{
    static int i = 0;
    if (i<=5) {
        i++;
        NSString * content = [domesticFlight XMLString];
        NSString * fileName = [NSString stringWithFormat:@"A_I_R_domesticFlight_%d_DATA.txt",i];
        [YZZUtil WRITE_TO_FILE:content withName:fileName];
    }
}

- (IBAction)Run:(id)sender {
    //[self runTest];
    [self runAirData];
}

@end
