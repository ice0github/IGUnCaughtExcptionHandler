//
//  IGUnCaughtExcptionHandler.h
//  T_CatchExction
//
//  Created by 桂强 何 on 15/12/12.
//  Copyright © 2015年 桂强 何. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IGUnCaughtExcptionHandler : NSObject

@property (nonatomic,assign) BOOL caughtSIGABRT;

+ (instancetype) shareHandler;

- (void)bindHandler;

@end
