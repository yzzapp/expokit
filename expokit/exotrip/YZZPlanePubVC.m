//
//  YZZPlanePubVC.m
//  expokit
//
//  Created by 石戬, 姚勤(还没有对象的87) on on 13-5-7.
//  Copyright (c) 2013年 YzzApp.com. All rights reserved.
//

#import "YZZPlanePubVC.h"
#import "YZZUtil.h"

static NSString * airPlanTablePrefix = @"AIRPLAN";

#define YZZ_REF_AIRLITE_DATE_DAYS 45

@interface YZZPlanePubVC ()

@end

@implementation YZZPlanePubVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.m_dataDic = [[NSMutableDictionary alloc] init];
    self.m_sqlToPost = [[NSMutableArray alloc] init];
}

- (IBAction)PostSQLs:(id)sender {
    [self transToSQLs];
}

//<AIRLINE>SHE_BJS_0514
//
//<AIRLINE>SHE_BJS_0514
//SHE,BJS,2013-05-14T08:00:00,2013-05-14T09:25:00,CZ6101  490,700,0.7,50,60,10  100  Y,G,G  SHE,23,PEK,2
//SHE,BJS,2013-05-14T08:30:00,2013-05-14T09:50:00,CA1654  560,700,0.8,50,60,10  86.67  Y,H,H  SHE,23,PEK,3
//SHE,BJS,2013-05-14T10:30:00,2013-05-14T11:50:00,CZ6103  490,700,0.7,50,60,10  96.67  Y,G,G  SHE,23,PEK,2
//SHE,BJS,2013-05-14T18:30:00,2013-05-14T19:55:00,CZ6109  490,700,0.7,50,60,10  90  Y,G,G  SHE,23,PEK,2

//"BJS_CAN" =     {
//    0509 = "BJS_CAN_0509";
//    0510 = "BJS_CAN_0510";
//    0511 = "BJS_CAN_0511";
//    0512 = "BJS_CAN_0512\nBJS,CAN,2013-05-12T08:30:00,2013-05-12T11:45:00,CZ3108  1360,1700,0.8,50,110,10  86.21  Y,H,H  PEK,2,CAN,47\nBJS,CAN,2013-05-12T11:00:00,2013-05-12T14:10:00,CA1315  1360,1700,0.8,50,110,10  86.67  Y,H,H  PEK,3,CAN,47\nBJS,CAN,2013-05-12T15:30:00,2013-05-12T18:45:00,CZ3104  1360,1700,0.8,50,110,10  93.33  Y,H,H  PEK,2,CAN,47\nBJS,CAN,2013-05-12T19:30:00,2013-05-12T22:45:00,CZ3110  1360,1700,0.8,50,110,10  86.67  Y,H,H  PEK,2,CAN,47";
//    0513 = "BJS_CAN_0513\nBJS,CAN,2013-05-13T08:30:00,2013-05-13T11:45:00,CZ3108  1360,1700,0.8,50,110,10  86.21  Y,H,H  PEK,2,CAN,47\nBJS,CAN,2013-05-13T11:00:00,2013-05-13T14:10:00,CA1315  1360,1700,0.8,50,110,10  86.67  Y,H,H  PEK,3,CAN,47\nBJS,CAN,2013-05-13T15:30:00,2013-05-13T18:45:00,CZ3104  1360,1700,0.8,50,110,10  93.33  Y,H,H  PEK,2,CAN,47\nBJS,CAN,2013-05-13T19:30:00,2013-05-13T22:45:00,CZ3110  850,1700,0.5,50,110,6  86.67  Y,E,E  PEK,2,CAN,47";
//    0514 = "BJS_CAN_0514\nBJS,CAN,2013-05-14T08:30:00,2013-05-14T11:45:00,CZ3108  1360,1700,0.8,50,110,10  86.21  Y,H,H  PEK,2,CAN,47\nBJS,CAN,2013-05-14T11:00:00,2013-05-14T14:10:00,CA1315  1360,1700,0.8,50,110,10  86.67  Y,H,H  PEK,3,CAN,47\nBJS,CAN,2013-05-14T15:30:00,2013-05-14T18:45:00,CZ3104  1360,1700,0.8,50,110,10  93.33  Y,H,H  PEK,2,CAN,47\nBJS,CAN,2013-05-14T19:30:00,2013-05-14T22:45:00,CZ3110  850,1700,0.5,50,110,10  86.67  Y,E,E  PEK,2,CAN,47";
//  ...
//}

- (void)transToSQLs
{
    NSLog(@"transToSQLs start...");

    NSString * content = [YZZUtil READ_FROM_FILE:@"A__I__R.txt"];
    NSArray * blocks = [content componentsSeparatedByString:@"<AIRLINE>"];
    NSLog(@"blocks count:%d",[blocks count]);
    for (NSString * thisBlock in blocks) {
        NSString * dataString = [thisBlock stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([dataString isEqualToString:@""]) continue;
        
        NSString * lineName = [[dataString componentsSeparatedByString:@"\n"] objectAtIndex:0];
        NSString * lineContent = dataString;
        
        if ([lineContent isEqualToString:@""]) continue;
        
        NSArray * nameArr = [lineName componentsSeparatedByString:@"_"];
        NSString * dCity = [nameArr objectAtIndex:0];
        NSString * aCity = [nameArr objectAtIndex:1];
        NSString * dDate = [nameArr objectAtIndex:2];
        NSString * cityPair = [NSString stringWithFormat:@"%@_%@",dCity,aCity];
        
        NSMutableDictionary * deepDic = [self.m_dataDic valueForKey:cityPair];
        if (deepDic == nil) {
            deepDic = [[NSMutableDictionary alloc] init];
        }
        
        lineContent = [lineContent stringByReplacingOccurrencesOfString:@"\n" withString:@"   "];
        [deepDic setValue:lineContent forKey:dDate];
        [self.m_dataDic setValue:deepDic forKey:cityPair];
    }
    
    NSString * sqlContent = [self CreateSQLForServer];
    //NSLog(@"%@",sqlContent);
    for (NSString * key in self.m_dataDic) {
        NSMutableDictionary * dic = [self.m_dataDic valueForKey:key];
        [dic setValue:key forKey:@"CITYPAIR"];
        NSString * insertSQL = [self analysisSQL:dic];
        sqlContent = [NSString stringWithFormat:@"%@\n%@",sqlContent,insertSQL];
    }
    [YZZUtil WRITE_TO_FILE:sqlContent withName:@"air_sqls.txt"];
    NSLog(@"transToSQLs Processed Success!");
    
    self.m_sqlToPost = [[NSMutableArray alloc] initWithArray:[sqlContent componentsSeparatedByString:@"\n"]];
    NSLog(@"to Post SQLs Count(%dL)",[self.m_sqlToPost count]);
    [self GoPost];
    
}

- (void)GoPost {
    NSLog(@"Post Create SQL");
    NSString * createSQL = [self.m_sqlToPost objectAtIndex:0];
    [self.m_sqlToPost removeObjectAtIndex:0];
    self.m_op = [[AppDelegate m_engine] ExpoCreate:createSQL vc:self];
    
    float interval = 6.0f;
    for (NSString * line in self.m_sqlToPost) {
        interval = interval + 1.0f;
        [self performSelector:@selector(postData:) withObject:line afterDelay:interval];
    }
}

- (void)postData:(NSString *)line
{
    int count = [self.m_sqlToPost count];
    static int i = 0;
    float pv = (float)i/(float)count;
    [self.m_pv setProgress:pv animated:YES];
    self.m_op = [[AppDelegate m_engine] ExpoCreate:line vc:self];
    i++;
}

- (void)Refresh
{
    //call back
}
- (NSString *)CreateSQLForServer
{
    NSString * createSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (CITYPAIR TEXT %@)",
                            [self TABLENAME_TODAY],
                            [self TABLECOLS_MYSQL_TODAY]];
    return createSQL;
}

- (NSString *)TABLECOLS_MYSQL_TODAY
{
    NSString * colsNameList = @"";
    NSString * dayString = [YZZUtil DATE_TODAY_STRING];
    for (int i = 0; i<=YZZ_REF_AIRLITE_DATE_DAYS; i++) {
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
                            airPlanTablePrefix,
                            [YZZUtil DATE_FORMAT_MMDD:[YZZUtil DATE_TODAY_STRING]]];
    return tableName;
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
    //NSLog(@"ana:%@",insertSQL);
    return insertSQL;
}

//move to exoptrip
- (void)addToDataDic:(NSString *)LineData
{
    //SHE,BJS,2013-05-14T08:00:00,2013-05-14T09:25:00,CZ6101  490,700,0.7,50,60,10  100  Y,G,G  SHE,23,PEK,2

    NSArray * parts = [LineData componentsSeparatedByString:@"  "];
    NSArray * part1 = [[parts objectAtIndex:0] componentsSeparatedByString:@","];
    NSArray * part2 = [[parts objectAtIndex:1] componentsSeparatedByString:@","];
    //part3 string
    NSArray * part4 = [[parts objectAtIndex:3] componentsSeparatedByString:@","];
    NSArray * part5 = [[parts objectAtIndex:4] componentsSeparatedByString:@","];

    NSString * dCityCode = [part1 objectAtIndex:0];
    NSString * aCityCode = [part1 objectAtIndex:1];
    NSString * dDateTime = [part1 objectAtIndex:2];
    NSString * aDateTime = [part1 objectAtIndex:3];
    NSString * aLineCode = [part1 objectAtIndex:4];
    
    NSString * customPrice = [part2 objectAtIndex:0];
    NSString * originPrice = [part2 objectAtIndex:1];
    NSString * customRates = [part2 objectAtIndex:2];
    NSString * customTaxes = [part2 objectAtIndex:3];
    NSString * customOiFee = [part2 objectAtIndex:4];
    NSString * ticketCount = [part2 objectAtIndex:5];
    
    NSString * punctuality = [parts objectAtIndex:2];

    NSString * displaySeat = [part4 objectAtIndex:2];
    
    NSString * dAirPortCode = [part5 objectAtIndex:0];
    NSString * dAirPortBuild = [part5 objectAtIndex:1];
    NSString * aAirPortCode = [part5 objectAtIndex:2];
    NSString * aAirPortBuild = [part5 objectAtIndex:3];
    
    
    
}

@end
