//
//  YZZPlaneDataVC.h
//  expokit
//
//  Created by 石戬, 姚勤(还没有对象的87) on on 13-5-7.
//  Copyright (c) 2013年 YzzApp.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YZZPlaneDataVC : UIViewController

@property (strong, nonatomic) NSMutableArray * m_planeCitys;
@property (strong, nonatomic) NSMutableArray * m_dstCitys;
@property (strong, nonatomic) NSMutableDictionary * m_cityCodeDic;

@property (strong, nonatomic) NSMutableDictionary * m_mistakeDic;
@property (strong, nonatomic) NSMutableDictionary * m_mistakeContentDic;

@property (strong, nonatomic) NSMutableArray * m_requestBlocks;
@property (strong, nonatomic) IBOutlet UIProgressView *m_ratePV;

- (IBAction)Run:(id)sender;
@end
