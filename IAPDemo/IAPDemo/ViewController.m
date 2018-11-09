//
//  ViewController.m
//  IAPDemo
//
//  Created by 吴桐 on 2018/11/9.
//  Copyright © 2018年 cowlevel. All rights reserved.
//

#import "ViewController.h"
#import "ZPMPurchaseService.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSDictionary *dic = @{@"projectid":@"YOURS",
                          @"orderid":@"YOURS",
                          @"payid":@"YOURS",
                          @"pccode":@"YOURS",};
    
    //唤起内购
    [[ZPMPurchaseService sharedPurchaseService]inAppPurchase:dic andSucc:^(id sender) {
       //成功回调操作
        NSLog(@"成功回调操作");
    } andfailed:^(id sender) {
       //失败回调操作
        NSLog(@"失败回调操作,失败原因:%@",sender);
    }];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
