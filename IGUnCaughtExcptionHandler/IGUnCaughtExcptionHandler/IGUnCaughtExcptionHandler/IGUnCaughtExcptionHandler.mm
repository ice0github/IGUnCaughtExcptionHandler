//
//  IGUnCaughtExcptionHandler.m
//  T_CatchExction
//
//  Created by 桂强 何 on 15/12/12.
//  Copyright © 2015年 桂强 何. All rights reserved.
//

#import "IGUnCaughtExcptionHandler.h"
#import <UIKit/UIKit.h>
#include <libkern/OSAtomic.h>
#include <execinfo.h>

NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";

NSString * const UncaughtExceptionHandlerSignalKey           = @"UncaughtExceptionHandlerSignalKey";

NSString * const UncaughtExceptionHandlerAddressesKey        = @"UncaughtExceptionHandlerAddressesKey";

volatile int32_t UncaughtExceptionCount                      = 0;

const int32_t UncaughtExceptionMaximum                       = 10;

const NSInteger UncaughtExceptionHandlerSkipAddressCount     = 4;

const NSInteger UncaughtExceptionHandlerReportAddressCount   = 5;
   

@interface IGUnCaughtExcptionHandler ()<UIAlertViewDelegate>

@property (nonatomic,assign) BOOL dismissed;

@end

@implementation IGUnCaughtExcptionHandler

+(instancetype)shareHandler
{
    static IGUnCaughtExcptionHandler *_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[IGUnCaughtExcptionHandler alloc] init];
        [_sharedInstance setup];
    });
    return _sharedInstance;
}


- (void)setup{
    _caughtSIGABRT = NO;
}

- (void)bindHandler{
    if (_caughtSIGABRT) {
        InstallUncaughtExceptionHandler();
    }
    NSSetUncaughtExceptionHandler(&UncaughtExceptionHandler);
}

- (NSArray*)backtrace{
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (
         i = UncaughtExceptionHandlerSkipAddressCount;
         i < UncaughtExceptionHandlerSkipAddressCount +
         UncaughtExceptionHandlerReportAddressCount;
         i++){
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    
    return backtrace;
}

- (void)alertView:(UIAlertView *)anAlertView clickedButtonAtIndex:(NSInteger)anIndex{
    if (anIndex == 0){
        _dismissed = YES;
    }
}

- (void)handleException:(NSException *)exception{
    UncaughtExceptionHandler(exception);
    
    UIAlertView *alert =
    [[UIAlertView alloc] initWithTitle:@"抱歉，程序出现了异常"
                               message:[NSString stringWithFormat:@"如果点击继续，程序有可能会出现其他的问题，建议您还是点击退出按钮并重新打开\n\n异常原因如下:\n%@\n%@",
                                        [exception reason],
                                        [[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey]]
                              delegate:self
                     cancelButtonTitle:@"退出"
                     otherButtonTitles:@"继续", nil];
    [alert show];
    
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFArrayRef allModes  = CFRunLoopCopyAllModes(runLoop);
    
    while (!_dismissed){
        for (NSString *mode in (__bridge NSArray *)allModes){
            CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
        }
    }
    
    CFRelease(allModes);
    
    NSSetUncaughtExceptionHandler(NULL);
    
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    
    if ([[exception name] isEqual:UncaughtExceptionHandlerSignalExceptionName]){
        kill(getpid(), [[[exception userInfo] objectForKey:UncaughtExceptionHandlerSignalKey] intValue]);
    }else{
        [exception raise];
    }
}


#pragma mark - ----> C部分
NSString* savePath(){
    static NSString *rootPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        rootPath = [rootPath stringByAppendingPathComponent:@"ExcptionLogs"];
        
        BOOL isDir;
        if (![[NSFileManager defaultManager] fileExistsAtPath:rootPath isDirectory:&isDir]
            || !isDir) {
            [[NSFileManager defaultManager] createDirectoryAtPath:rootPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        NSLog(@"RootPath: %@",rootPath);
    });
    
    return rootPath;
}

NSDateFormatter* dateFromatter(){
    static NSDateFormatter *formatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyyMMdd_HHmmss"];
    });
    return formatter;
}

NSString* getAppInfo() {
    NSString *appInfo = [NSString stringWithFormat:
                         @"App : %@ %@(%@)\n"
                         "Device : %@\n"
                         "OS Version : %@ %@\n",
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey],
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
                         [UIDevice currentDevice].model,
                         [UIDevice currentDevice].systemName,
                         [UIDevice currentDevice].systemVersion];
    return appInfo;
}


void UncaughtExceptionHandler(NSException *exception) {
    NSArray *stack       = [exception callStackSymbols];
    NSString *reason     = [exception reason];
    NSString *name       = [exception name];
    NSString *dateString = [dateFromatter() stringFromDate:[NSDate date]];
    
    NSString *log = [NSString stringWithFormat:
                     @"============= 异常崩溃报告 %@ =============\n"
                     "Name: %@\n"
                     "Reason: %@\n"
                     "Stack:\n%@\n"
                     "AppInfo:\n%@\n",
                     dateString,name,reason,[stack componentsJoinedByString:@"\n"],getAppInfo()];
    NSString *path = [savePath() stringByAppendingPathComponent:[dateString stringByAppendingPathExtension:@"txt"]];
    [log writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}





void IGSignalHandler(int signal) {
    
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount > UncaughtExceptionMaximum){
        return;
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:@(signal) forKey:UncaughtExceptionHandlerSignalKey];
    
    NSArray *callStack = [[IGUnCaughtExcptionHandler  shareHandler] backtrace];
    
    [userInfo setObject:callStack forKey:UncaughtExceptionHandlerAddressesKey];
    
    [[IGUnCaughtExcptionHandler  shareHandler] performSelectorOnMainThread:@selector(handleException:)
                                                                  withObject:[NSException exceptionWithName:UncaughtExceptionHandlerSignalExceptionName
                                                                                                     reason:[NSString stringWithFormat:@"Signal %d was raised.",signal]
                                                                                                   userInfo:userInfo]
                                                               waitUntilDone:YES];
}

void InstallUncaughtExceptionHandler(){
    
    signal(SIGABRT, IGSignalHandler);
    
    signal(SIGILL, IGSignalHandler);
    
    signal(SIGSEGV, IGSignalHandler);
    
    signal(SIGFPE, IGSignalHandler);
    
    signal(SIGBUS, IGSignalHandler);
    
    signal(SIGPIPE, IGSignalHandler);
}

@end

