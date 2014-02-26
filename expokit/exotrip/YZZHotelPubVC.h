//
//  YZZViewController.h
//  exotrip
//
//  Created by 石戬, 姚勤(还没有对象的87) on on 13-4-17.
//  Copyright (c) 2013年 YzzApp.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YZZHotelPubVC : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *m_tableView;
@property (strong, nonatomic) IBOutlet UIProgressView *m_processView;

@property (strong, nonatomic) NSMutableArray * m_sqlArray;

@property (strong, nonatomic) MKNetworkOperation * m_op;

- (IBAction)GoPost:(id)sender;

@end
