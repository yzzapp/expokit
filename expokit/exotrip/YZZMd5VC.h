//
//  YZZMd5VC.h
//  exotrip
//
//  Created by 石戬, 姚勤(还没有对象的87) on on 13-4-20.
//  Copyright (c) 2013年 YzzApp.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YZZMd5VC : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *m_aid;
@property (strong, nonatomic) IBOutlet UITextField *m_sid;
@property (strong, nonatomic) IBOutlet UITextField *m_key;
@property (strong, nonatomic) IBOutlet UITextField *m_action;
@property (strong, nonatomic) IBOutlet UITextView *m_md5;
@property (strong, nonatomic) IBOutlet UITextView *m_timestamp;

@property (strong, nonatomic) IBOutlet UITextView *originStringTV;

- (IBAction)Cal:(id)sender;
@end
