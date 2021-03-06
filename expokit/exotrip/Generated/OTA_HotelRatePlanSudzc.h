/*
	OTA_HotelRatePlanSudzc.h
	Creates a list of the services available with the OTA_HotelRatePlan prefix.
	Generated by SudzC.com
*/
#import "OTA_HotelRatePlanOTA_HotelRatePlan.h"

@interface OTA_HotelRatePlanSudzC : NSObject {
	BOOL logging;
	NSString* server;
	NSString* defaultServer;
OTA_HotelRatePlanOTA_HotelRatePlan* oTA_HotelRatePlan;

}

-(id)initWithServer:(NSString*)serverName;
-(void)updateService:(SoapService*)service;
-(void)updateServices;
+(OTA_HotelRatePlanSudzC*)sudzc;
+(OTA_HotelRatePlanSudzC*)sudzcWithServer:(NSString*)serverName;

@property (nonatomic) BOOL logging;
@property (nonatomic, retain) NSString* server;
@property (nonatomic, retain) NSString* defaultServer;

@property (nonatomic, retain, readonly) OTA_HotelRatePlanOTA_HotelRatePlan* oTA_HotelRatePlan;

@end
			