//
//  YZZPlanePubVC.h
//  expokit
//
//  Created by 石戬, 姚勤(还没有对象的87) on on 13-5-7.
//  Copyright (c) 2013年 YzzApp.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YZZPlanePubVC : UIViewController

@property (strong, nonatomic) IBOutlet UIProgressView   * m_pv;
@property (strong, nonatomic) NSMutableDictionary       * m_dataDic;
@property (strong, nonatomic) NSMutableArray            * m_sqlToPost;

@property (strong, nonatomic) MKNetworkOperation        * m_op;

- (IBAction)PostSQLs:(id)sender;



@end
