//
//  ViewController.m
//  IGUnCaughtExcptionHandler
//
//  Created by 桂强 何 on 15/12/12.
//  Copyright © 2015年 桂强 何. All rights reserved.
//


#import "ViewController.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>{
    UITableView *tb;
    NSMutableArray *datas;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    
    tb            = [[UITableView alloc] initWithFrame:self.view.bounds];
    tb.dataSource = self;
    tb.delegate   = self;
    [self.view addSubview:tb];
    
    [self initData];
}


- (void)initData{
    datas = [[NSMutableArray alloc] init];
    [datas addObject:@"----- 占位 -----"];
    
    [datas addObject:@"未定义的selector"];
    [datas addObject:@"数组越界"];
}


#pragma mark - ----> TableView Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return datas.count;
}

static NSString *cellID = @"CellID";
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    
    cell.textLabel.text = datas[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.row) {
        case 1:{
            id obj = datas[indexPath.row];
            [obj removeFromSuperview];
        }
            break;
        case 2:{
            NSLog(@"%@",datas[datas.count+1]);
        }
            break;
        default:
            break;
    }
}



@end
