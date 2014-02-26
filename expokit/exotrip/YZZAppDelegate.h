//
//  YZZAppDelegate.h
//  exotrip
//
//  Created by 石戬, 姚勤(还没有对象的87) on on 13-4-17.
//  Copyright (c) 2013年 YzzApp.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YZZEngine.h"

#define AppDelegate ((YZZAppDelegate *)[UIApplication sharedApplication].delegate)

@interface YZZAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) YZZEngine *m_engine;
@property (strong, nonatomic) YZZEngine *m_imgEngine;

@end
