//
//  ZPMPurchaseService.m
//  IAPDemo
//
//  Created by 吴桐 on 2018/5/15.
//  Copyright © 2018年 zhaopin.com. All rights reserved.
//
#define BlockCallWithOneArg(block,arg)  if(block){block(arg);}

#import "ZPMPurchaseService.h"
#import "IAPShare.h"
#import "MBProgressHUD.h"
#import <CommonCrypto/CommonDigest.h>

@interface ZPMPurchaseService()
    @property (nonatomic, strong) NSDictionary *infoDic;
    /// 请求支付成功后返回的order信息
    @property (nonatomic, strong) NSDictionary *orderDic;
    /// 是否活动
    @property (nonatomic, assign) BOOL isActive;
@end

@implementation ZPMPurchaseService
+ (instancetype)sharedPurchaseService{
    static ZPMPurchaseService *purchaseService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        purchaseService = [[ZPMPurchaseService alloc]init];
    });
    
    return purchaseService;
}

#pragma mark- 内购相关方法
- (void)inAppPurchase:(NSDictionary *)dic
              andSucc:(EventHandler)succ
            andfailed:(EventHandler)failed
{
    NSSet *dataSet = [[NSSet alloc] initWithObjects:dic[@"projectid"], nil];
    
    [IAPShare sharedHelper].iap = [[IAPHelper alloc] initWithProductIdentifiers:dataSet];
    
    [IAPShare sharedHelper].iap.production = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //展现加载状态
        [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    });
    
    //按照projectID查询商品列表中的商品
    [[IAPShare sharedHelper].iap requestProductsWithCompletion:^(SKProductsRequest* request,SKProductsResponse* response)
     {
         if(response > 0 ) {
             SKProduct *product =[[IAPShare sharedHelper].iap.products firstObject];
             //product 为空，意味着无projectid内购商品
             if (!product) {
                 [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
                 BlockCallWithOneArg(failed, @"内购商品信息有误...");
                 return ;
             }
             
             NSLog(@"Price: %@",[[IAPShare sharedHelper].iap getLocalePrice:product]);
             NSLog(@"Title: %@",product.localizedTitle);
             //发起支付请求
             [[IAPShare sharedHelper].iap buyProduct:product
                                        onCompletion:^(SKPaymentTransaction* trans){
                                            //隐藏加载状态
                                            [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
                                            //返回错误
                                            if(trans.error)
                                            {
                                                NSLog(@"Fail %@",[trans.error localizedDescription]);
                                                BlockCallWithOneArg(failed, [trans.error localizedDescription]);
                                            }
                                            //支付成功
                                            else if(trans.transactionState == SKPaymentTransactionStatePurchased) {
                                                //进行base64
                                                [[IAPShare sharedHelper].iap checkNotVerifyReceiptReceipt:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]]
                                                                                             onCompletion:^(NSString *response, NSError *error) {
                                                                                                 //调用后台接口，将苹果的收据receipt，
                                                                                                 [self requestInapppay:dic receipt:response];
                                                                                             }];
                                                
                                            }
                                            //支付失败
                                            else if(trans.transactionState == SKPaymentTransactionStateFailed) {
                                                NSLog(@"Fail");
                                                BlockCallWithOneArg(failed, @"IAP处理失败...");
                                            }
                                            
                                        }];//end of buy product
         }
     }];
}


- (void)requestInapppay:(NSDictionary *)dic receipt:(NSString *)receipt
{
    NSString *key = @"abcabc123123";
    NSString *sign = [NSString stringWithFormat:@"%@%@%@%@%@%@",dic[@"orderid"], dic[@"payid"],dic[@"pccode"],dic[@"projectid"], receipt, key];
    //将订单号，支付单号，苹果收据，pccode,商品编号以及key拼接并且进行md5加密
    NSString *md5Sign = [self md5:sign];
    NSLog(@"md5Sign:%@",md5Sign);
    
    NSMutableDictionary *purchaseDic = [NSMutableDictionary dictionary];
    [purchaseDic setDictionary:dic];
    [purchaseDic setObject:receipt forKey:@"receipt"];
    [purchaseDic setObject:md5Sign forKey:@"sign"];
    NSLog(@"purchaseDic:%@",purchaseDic);
    
    //将purchaseDic送给后台处理
}

//md5加密
- (NSString *)md5:(NSString *)input {
    const char *cStr = [input UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (int)strlen(cStr), digest); // This is the md5 call
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    return  output;
}


-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
