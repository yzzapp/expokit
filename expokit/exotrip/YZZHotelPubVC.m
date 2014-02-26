//
//  YZZViewController.m
//  exotrip
//
//  Created by 石戬, 姚勤(还没有对象的87) on on 13-4-17.
//  Copyright (c) 2013年 YzzApp.com. All rights reserved.
//

#import "YZZDatabase.h"
#import "YZZUtil.h"
#import "YZZHotelPubVC.h"

@interface YZZHotelPubVC ()
@property (strong, nonatomic) NSMutableArray * m_citys;
@end

@implementation YZZHotelPubVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString * content = [YZZUtil READ_FROM_FILE:@"sqls.txt"];
    self.m_sqlArray = [[NSMutableArray alloc] initWithArray:[content componentsSeparatedByString:@"\n"]];
    NSLog(@"count(%dL)",[self.m_sqlArray count]);
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.m_sqlArray count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * identifier = [self getCellIdentifier:indexPath];
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    cell = [self configCell:cell atIndexPath:indexPath];
    return cell;
}

- (NSString *)getCellIdentifier:(NSIndexPath *)indexPath
{
    return @"defaultCell";
}

- (UITableViewCell *)configCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    UILabel * sqlLine = (UILabel *)[cell viewWithTag:1001];
    sqlLine.text = [NSString stringWithFormat:@"%d,%@",indexPath.row,[self.m_sqlArray objectAtIndex:indexPath.row]];
    return cell;
}

- (IBAction)GoPost:(id)sender {
    NSLog(@"Post Create SQL");
    NSString * createSQL = [self.m_sqlArray objectAtIndex:0];
    [self.m_sqlArray removeObjectAtIndex:0];
    self.m_op = [[AppDelegate m_engine] ExpoCreate:createSQL vc:self];

    float interval = 6.0f;
    for (NSString * line in self.m_sqlArray) {
        interval = interval + 1.0f;
        [self performSelector:@selector(postData:) withObject:line afterDelay:interval];
    }
}

- (void)postData:(NSString *)line
{
    int count = [self.m_sqlArray count];
    static int i = 0;
    float pv = (float)i/(float)count;
    [self.m_processView setProgress:pv animated:YES];
    self.m_op = [[AppDelegate m_engine] ExpoCreate:line vc:self];
    i++;
}

- (void)Refresh
{
    //NSLog(@"Line : call back.");
}
@end
