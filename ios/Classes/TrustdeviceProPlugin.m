#import "TrustdeviceProPlugin.h"
#import <TDMobRisk/TDMobRisk.h>

@interface TrustdeviceProPlugin()

@end

static FlutterMethodChannel* _channel = nil;

@implementation TrustdeviceProPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"trustdevice_pro_plugin"
                                     binaryMessenger:[registrar messenger]];
    TrustdeviceProPlugin* instance = [[TrustdeviceProPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    _channel = channel;
}

- (UIWindow *)getKeyWindow
{
    if (@available(iOS 13.0, *))
    {
        for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes) {
            if (windowScene.activationState == UISceneActivationStateForegroundActive)
            {
                for (UIWindow *window in windowScene.windows)
                {
                    if (window.isKeyWindow)
                    {
                        return window;
                    }
                }
            }
        }
    }
    else
    {
        return [UIApplication sharedApplication].keyWindow;
    }
    return nil;
}

- (UIViewController *)getRootViewController
{
    UIWindow *keyWindow = [self getKeyWindow];
    UIViewController*rootViewController = keyWindow.rootViewController;
    return rootViewController;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    }else if ([@"initWithOptions" isEqualToString:call.method]) {
        TDMobRiskManager_t *manager = [TDMobRiskManager sharedManager];
        NSDictionary* configOptions = call.arguments;
        NSMutableDictionary *options = [[NSMutableDictionary alloc] initWithDictionary:configOptions];
        
        // 参数处理
        id allowedObj = options[@"debug"];
        if([allowedObj isKindOfClass:[NSNumber class]]){
            if([allowedObj boolValue] == YES){
                options[@"allowed"] = @"allowed";
            }
        }
        
        id locationObj = options[@"location"];
        if([locationObj isKindOfClass:[NSNumber class]]){
            if([locationObj boolValue] == NO){
                options[@"noLocation"] = @"noLocation";
            }
        }
        
        id IDFAObj = options[@"IDFA"];
        if([IDFAObj isKindOfClass:[NSNumber class]]){
            if([IDFAObj boolValue] == NO){
                options[@"noIDFA"] = @"noIDFA";
            }
        }
        
        id deviceNameObj = options[@"deviceName"];
        if([deviceNameObj isKindOfClass:[NSNumber class]]){
            if([deviceNameObj boolValue] == NO){
                options[@"noDeviceName"] = @"noDeviceName";
            }
        }
        
        /// 这个无法用textView设置，只能默认设置
        manager->initWithOptions([options copy]);
    }else if ([@"getBlackbox" isEqualToString:call.method]) {
        TDMobRiskManager_t *manager = [TDMobRiskManager sharedManager];
        NSString* blackBox = manager->getBlackBox();
        result(blackBox);
    }else if ([@"getBlackboxAsync" isEqualToString:call.method]) {
        TDMobRiskManager_t *manager = [TDMobRiskManager sharedManager];
        manager->getBlackBoxAsync(^(NSString* blackBox){
            dispatch_async(dispatch_get_main_queue(), ^{
                result(blackBox);
            });
        });
    }
    else if ([@"getSDKVersion" isEqualToString:call.method]) {
        TDMobRiskManager_t *manager = [TDMobRiskManager sharedManager];
        NSString* version = manager->getSDKVersion();
        result(version);
    }else if ([@"showCaptcha" isEqualToString:call.method]) {
        TDMobRiskManager_t *manager = [TDMobRiskManager sharedManager];
        UIWindow *keyWindow = [self getKeyWindow];
        manager->showCaptcha(keyWindow,^(TDShowCaptchaResultStruct resultStruct) {
            NSMutableDictionary *resultDictionary = [NSMutableDictionary dictionary];
            switch (resultStruct.resultType) {
                case TDShowCaptchaResultTypeSuccess:
                    resultDictionary[@"function"] = @"onSuccess";
                    resultDictionary[@"token"] = @(resultStruct.validateToken);
                    break;
                case TDShowCaptchaResultTypeFailed:
                    resultDictionary[@"function"] = @"onFailed";
                    resultDictionary[@"errorCode"] = @(resultStruct.errorCode);
                    resultDictionary[@"errorMsg"] = @(resultStruct.errorMsg);
                    break;
                case TDShowCaptchaResultTypeReady:
                    resultDictionary[@"function"] = @"onReady";
                    break;
                default:
                    break;
            }
            [_channel invokeMethod:@"showCaptcha" arguments:resultDictionary];
        });
    }else if ([@"getRootViewController" isEqualToString:call.method]) {
        UIViewController*rootViewController = [self getRootViewController];
        result(rootViewController);
    }else if ([@"showLiveness" isEqualToString:call.method]) {
        TDMobRiskManager_t *manager = [TDMobRiskManager sharedManager];
        
        NSDictionary* configOptions = call.arguments;
        NSMutableDictionary *options = [[NSMutableDictionary alloc] initWithDictionary:configOptions];
        
        UIViewController*targetVC = options[@"targetVC"];
        
        UIViewController*license = options[@"license"];
        
        manager->showLivenessWithShowStyle(targetVC,license,TDLivenessShowStylePush,^(TDLivenessResultStruct resultStruct) {
            if(resultStruct.resultType == TDLivenessResultTypeSuccess){
                NSString*bestImageString = [NSString stringWithUTF8String:resultStruct.bestImageString];
                // 如果存在最佳照片
                if(bestImageString.length > 0){
                    NSData* data = [[NSData alloc]initWithBase64EncodedString:bestImageString options:NSDataBase64DecodingIgnoreUnknownCharacters];
                    UIImage * image = [UIImage imageWithData:data];
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
                }
                
                NSString*successMsg = [NSString stringWithUTF8String:resultStruct.errorMsg];
                NSLog(@"successMsg-::%@,seqId:%s,score:%f",successMsg,resultStruct.seqId,resultStruct.score);
            }else{
                NSString*errorMsg = [NSString stringWithUTF8String:resultStruct.errorMsg];
                NSLog(@"人脸检测失败，错误码:%ld,错误信息:%@",resultStruct.errorCode,errorMsg);
            }
            char const* livenessId_c = resultStruct.livenessId;
            NSLog(@"livenessId_c---::%s",livenessId_c);
        });
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
