//
//  ZPMPurchaseService.h
//  IAPDemo
//
//  Created by 吴桐 on 2018/5/15.
//  Copyright © 2018年 zhaopin.com. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void(^EventHandler)(id sender);

@interface ZPMPurchaseService : NSObject

+ (instancetype)sharedPurchaseService;
/**
 发起【内购IAP】支付

 @param dic 支付相关数据
 @param succ 成功回调
 @param failed 失败回调
 */
- (void)inAppPurchase:(NSDictionary *)dic andSucc:(EventHandler)succ andfailed:(EventHandler)failed;

@end
