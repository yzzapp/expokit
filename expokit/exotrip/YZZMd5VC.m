//
//  YZZMd5VC.m
//  exotrip
//
//  Created by 石戬, 姚勤(还没有对象的87) on on 13-4-20.
//  Copyright (c) 2013年 YzzApp.com. All rights reserved.
//

#import "YZZMd5VC.h"
#import <CommonCrypto/CommonDigest.h>
#import "OTA_HotelSearchOTA_HotelSearch.h"
#import "NSString+HTML.h"
#import "OTA_PingOTA_Ping.h"

@interface YZZMd5VC ()

@end

@implementation YZZMd5VC

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (NSString *) md5_ctrip:(NSString *)requestType
{
    NSString * md5;
    
    NSDate * timestamp = [NSDate date];
    int timeInterval = [timestamp timeIntervalSince1970];
    NSLog(@"timestamp(%d)",timeInterval);
    NSString * aid = self.m_aid.text;
    NSString * sid = self.m_sid.text;
    NSString * key = self.m_key.text;
    
    NSString * md5_key_upper = [[self md5:key] uppercaseString];
    NSString * fullString = [NSString stringWithFormat:@"%d%@%@%@%@",
                             timeInterval,
                             aid,
                             md5_key_upper,
                             sid,
                             requestType];
    self.m_timestamp.text = [NSString stringWithFormat:@"%d",timeInterval];
    self.originStringTV.text = fullString;
    md5 = [self md5:fullString];
    return md5;
}

- (NSString *) md5:(NSString *) input
{
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
}

- (NSString *)getHeadWithRequestType:(NSString *)requestType
{
    NSUInteger timeInterval = [[NSDate date] timeIntervalSince1970];
    NSString * aid = self.m_aid.text;
    NSString * sid = self.m_sid.text;
    NSString * key = self.m_key.text;
    NSString * md5_key_upper = [[self md5:key] uppercaseString];
    NSString * fullString = [NSString stringWithFormat:@"%d%@%@%@%@",
                             timeInterval,
                             aid,
                             md5_key_upper,
                             sid,
                             requestType];
    NSString *str = [NSString stringWithFormat:@"<Header AllianceID=\"%@\" SID=\"%@\" TimeStamp=\"%d\" RequestType=\"%@\" Signature=\"%@\"/>",aid,sid,timeInterval,requestType,[self md5:fullString]];
    return str;
}

- (IBAction)Cal:(id)sender {
    self.m_md5.text = [self md5_ctrip:self.m_action.text];
    //ping 测试
    OTA_PingOTA_Ping *request = [OTA_PingOTA_Ping service];
    NSString *requestBody = [NSString stringWithFormat:@"<HotelRequest><RequestBody xmlns=\"http://www.opentravel.org/OTA/2003/05\" xmlxsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlxsd=\"http://www.w3.org/2001/XMLSchema\"><OTA_PingRQ><EchoData>测试文本</EchoData></OTA_PingRQ></RequestBody></HotelRequest>"];
    NSString *requestXml = [NSString stringWithFormat:@"<![CDATA[<Request>%@%@</Request>]]>",[self getHeadWithRequestType:@"OTA_Ping"],requestBody];
    [request Request:self action:@selector(receivedPing:) requestXML:requestXml];
    
    //酒店测试
    
    OTA_HotelSearchOTA_HotelSearch *hotelRequest = [OTA_HotelSearchOTA_HotelSearch service];
    requestBody = [NSString stringWithFormat:@"<HotelRequest><RequestBody xmlns:ns=\"http://www.opentravel.org/OTA/2003/05\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"><ns:OTA_HotelSearchRQ Version=\"1.0\" PrimaryLangID=\"zh\" xsi:schemaLocation=\"http://www.opentravel.org/OTA/2003/05 OTA_HotelSearchRQ.xsd\" xmlns=\"http://www.opentravel.org/OTA/2003/05\"><ns:Criteria AvailableOnlyIndicator=\"true\"><ns:Criterion><ns:HotelRef HotelCityCode=\"2\"   HotelName=\"光大会展中心\"/><ns:Award Provider=\"HotelStarRate\" Rating=\"3\"/></ns:Criterion></ns:Criteria></ns:OTA_HotelSearchRQ></RequestBody></HotelRequest>"];
    requestXml = [NSString stringWithFormat:@"<![CDATA[<Request>%@%@</Request>]]>",[self getHeadWithRequestType:@"OTA_HotelSearch"],requestBody];
    [hotelRequest Request:self action:@selector(receivedHotel:) requestXML:requestXml];
}

- (void)receivedPing:(id)value
{
    NSLog(@"PING:%@",value);
}

- (void)receivedHotel:(id)value
{
    NSLog(@"HOTEL:%@",value);
}
@end
