//
//  QPlayAutoSDK.m
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QPlayAutoSDK.h"
#import "QPlayAutoManager.h"
#import "QQMusicUtils.h"
#import "QMMacros.h"
#import "QMRSA.h"
#import "QMNetworkHelper.h"


static NSString * const QQMusic_Scheme = @"qqmusic://";
static NSString * const QQMusic_Scheme_Domain = @"qqmusic://qq.com/other/qplayauto";
static NSString * const kScheme_Nonce = @"nonce";
static NSString * const kScheme_Sign = @"sign";
static NSString * const kScheme_OpenId= @"openId";
static NSString * const kScheme_OpenToken= @"openToken";
static NSString * const kScheme_CallbackUrl = @"callbackUrl";
static NSString * const kScheme_EncryptString= @"encryptString";
static NSString * const QQMusic_PubKey = @"MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCrp4sMcJjY9hb2J3sHWlwIEBrJlw2Cimv+rZAQmR8V3EI+0PUK14pL8OcG7CY79li30IHwYGWwUapADKA01nKgNeq7+rSciMYZv6ByVq+ocxKY8az78HwIppwxKWpQ+ziqYavvfE5+iHIzAc8RvGj9lL6xx1zhoPkdaA0agAyuMQIDAQAB";

@interface QPlayAutoSDK()

@property (nonatomic, weak) id<QPlayAutoSDKDelegate> delegate;

@end

@implementation QPlayAutoSDK

- (instancetype)init 
{
    self = [super init];
    if(self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotifyConnected:) name:kNotifyConnectSuccess object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotifyDisconnect:) name:kNotifyDisconnect object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPlayInfoChanged:) name:kNotifyPlayInfo object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSongFavoriteStateChange:) name:kNotifySongFavariteStateChange object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPlayModeChange:) name:kNotifyPlayModeChange object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPlayPausedByTimeoff) name:kNotifyPlayPausedByTimeOff object:nil];
    }
    return self;
}


+ (instancetype)sharedInstance
{
    static QPlayAutoSDK* g_dQPlayAutoSDK;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_dQPlayAutoSDK = [[QPlayAutoSDK alloc] init];
    });
    return g_dQPlayAutoSDK;
}

+ (void)registerAppWithName:(NSString *)name brand:(NSString *)brand deviceId:(NSString *)deviceId scheme:(NSString *)scheme appId:(NSString *)appId secretKey:(NSString *)secretKey bundleId:(NSString *)bundleId
{
    QPlayAutoAppInfo *appInfo = [[QPlayAutoAppInfo alloc] init];
    appInfo.deviceId = deviceId;
    appInfo.scheme = scheme;
    appInfo.brand = brand;
    appInfo.name = name;
    appInfo.bundleId = bundleId;
    appInfo.appId = appId;
    appInfo.secretKey = secretKey;
    appInfo.deviceType = APP_DEVICE_TYPE;
    [QPlayAutoManager sharedInstance].appInfo = appInfo;
}

+ (void)setDelegate:(id<QPlayAutoSDKDelegate>)delegate 
{
    [QPlayAutoSDK sharedInstance].delegate = delegate;
}

+ (BOOL)isQQMusicInstalled
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:QQMusic_Scheme]])
    {
        return YES;
    }
    return NO;
}

+ (BOOL)openQQMusicApp
{
    if (![QPlayAutoSDK isQQMusicInstalled])
    {
        return NO;
    }
    QPlayAutoAppInfo *appInfo = [QPlayAutoManager sharedInstance].appInfo;
    if(appInfo==nil || appInfo.deviceId.length==0 || appInfo.scheme.length==0)
    {
        return NO;
    }
    NSDictionary *param = @{
                            @"cmd":@"open",
                            @"callbackurl":appInfo.scheme,
                            @"devicebrand":appInfo.brand,
                            @"deviceid":appInfo.deviceId
                            };
    NSString *json = [QQMusicUtils strWithJsonObject:param];
    NSString *scheme = [NSString stringWithFormat:@"%@?p=%@",QQMusic_Scheme_Domain,[json stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [QQMusicUtils openUrl:scheme];
    return YES;
}

+ (BOOL)activeQQMusicApp
{
    if (![QPlayAutoSDK isQQMusicInstalled])
    {
        return NO;
    }
    QPlayAutoAppInfo *appInfo = [QPlayAutoManager sharedInstance].appInfo;
    if(appInfo==nil || appInfo.deviceId.length==0 || appInfo.scheme.length==0 || appInfo.appId.length==0|| appInfo.secretKey.length==0)
    {
        return NO;
    }

    NSString *encryptString = [QPlayAutoSDK createEncryptString];
    
    NSString *localIP =[QMNetworkHelper getIPAddress:YES];
    NSDictionary *param = @{
                            @"cmd":@"start",
                            @"callbackurl":appInfo.scheme,
                            @"devicebrand":appInfo.brand,
                            @"devicename":appInfo.name,
                            @"deviceid":appInfo.deviceId,
                            @"appid":appInfo.appId,
                            @"devicetype":@(appInfo.deviceType),
                            @"deviceip":localIP,
                            @"packagename":appInfo.bundleId,
                            @"dataport":@(LocalDataPort),
                            @"commandport":@(LocalCommandPort),
                            @"resultport":@(LocalResultPort),
                            @"encrypt":encryptString,
                            };
    NSString *json = [QQMusicUtils strWithJsonObject:param];
    NSString *scheme = [NSString stringWithFormat:@"%@?p=%@",QQMusic_Scheme_Domain,[json stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [QQMusicUtils openUrl:scheme];
    return YES;
}

+ (void)connect
{
    if(QPlayAutoManager.sharedInstance.isConnected == NO)
    {
        [QPlayAutoSDK activeQQMusicApp];
        [[QPlayAutoManager sharedInstance] connect];
    }
    else
    {
        NSLog(@"[IPC] 已经是连接状态");
    }
}

+ (BOOL)isConnecting {
    return QPlayAutoManager.sharedInstance.isStarted;
}

+ (void)reconnectWithTimeout:(NSTimeInterval)timeout completion:(QPlayAutoRequestFinishBlock)completion
{
    if(QPlayAutoManager.sharedInstance.isConnected == NO &&
       QPlayAutoManager.sharedInstance.isStarted == NO)
    {
        [QPlayAutoManager.sharedInstance reconnectWithCallback:completion timeout:timeout];
    }
    else
    {
        completion(YES,@{@"info":@"已经是连接状态"});
    }
}

+ (void)stop
{
    [[QPlayAutoManager sharedInstance] stop];
}

+ (BOOL)isConnected
{
    return [QPlayAutoManager sharedInstance].isConnected;
}

+ (NSInteger)getDataItems:(NSString*)parentID
                pageIndex:(NSUInteger)pageIndex
                 pageSize:(NSUInteger)pageSize
                   openId:(nullable NSString*)openId
                openToken:(nullable NSString*)openToken
                calllback:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoAppInfo *appInfo = [QPlayAutoManager sharedInstance].appInfo;
    if(appInfo==nil || appInfo.appId.length==0)
    {
        return 0;
    }
    return [[QPlayAutoManager sharedInstance] requestItems:parentID
                                                 pageIndex:pageIndex
                                                  pageSize:pageSize
                                                     appId:appInfo.appId
                                                    openId:openId
                                                 openToken:openToken
                                                 calllback:block];
}

+ (void)requestMobileDeviceInfos:(QPlayAutoRequestFinishBlock)block{
    [[QPlayAutoManager sharedInstance] requestMobileDeviceInfos:block];
}

+ (NSInteger)getCurrentPlayInfo:(QPlayAutoRequestFinishBlock)block
{
    return [[QPlayAutoManager sharedInstance] requestGetCurrentSong:block];
}

+ (NSInteger)getPlayMode:(QPlayAutoRequestFinishBlock)block
{
    return [[QPlayAutoManager sharedInstance] requestGetPlayMode:block];
}

+ (NSInteger)setPlayMode:(QPlayAutoPlayMode)playMode callback:(QPlayAutoRequestFinishBlock)block
{
    return [[QPlayAutoManager sharedInstance] requestSetPlayMode:playMode callback:block];
}

+ (NSInteger)setAssenceMode:(QPlayAutoAssenceMode)assencceMode callback:(QPlayAutoRequestFinishBlock)block
{
    return [[QPlayAutoManager sharedInstance] requestSetAssenceMode:assencceMode callback:block];
}

+ (NSInteger)queryFavoriteState:(NSString*)songId calllback:(QPlayAutoRequestFinishBlock)block
{
    return [[QPlayAutoManager sharedInstance] requestQueryFavoriteState:songId calllback:block];
}

+ (NSInteger)setFavoriteState:(BOOL)isFav songId:(NSString*)songId callback:(QPlayAutoRequestFinishBlock)block
{
    return [[QPlayAutoManager sharedInstance] requestSetFavoriteState:isFav songId:songId callback:block];
}

+ (void)playAtIndex:(NSArray<QPlayAutoListItem*>*)songList playIndex:(NSInteger)playIndex callback:(QPlayAutoRequestFinishBlock _Nullable)block
{
    if (songList.count==0)
        return;
    NSMutableArray *songIdList = [[NSMutableArray alloc]initWithCapacity:songList.count];
    [songList enumerateObjectsUsingBlock:^(QPlayAutoListItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.Type == QPlayAutoListItemType_Song)
        {
            [songIdList addObject:obj.ID];
        }
    }];
    [[QPlayAutoManager sharedInstance] requestPlaySongList:songIdList playIndex:playIndex callback:block];
}

+ (void)playSongMidAtIndex:(NSArray<NSString*>*)songMidList playIndex:(NSInteger)playIndex callback:(QPlayAutoRequestFinishBlock _Nullable)block
{
    if (songMidList.count==0)
        return;
    [[QPlayAutoManager sharedInstance] requestPlaySongMidList:songMidList playIndex:playIndex callback:block];
}

+ (void)playerPlayNext:(QPlayAutoRequestFinishBlock)block
{
    [[QPlayAutoManager sharedInstance] reqeustPlayNext:block];
}

+ (void)playerPlayPrev:(QPlayAutoRequestFinishBlock)block
{
    [[QPlayAutoManager sharedInstance] reqeustPlayPrev:block];
}

+ (void)playerPlayPause
{
    [[QPlayAutoManager sharedInstance] reqeustPlayPause];
}

+ (void)playerResume:(QPlayAutoRequestFinishBlock)block
{
    [[QPlayAutoManager sharedInstance] reqeustPlayResume:block];
}

+ (void)playerSeek:(NSInteger)position
{
    [[QPlayAutoManager sharedInstance] requestSeek:position];
}

+ (NSInteger)getOpenIdAuth:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoAppInfo *appInfo = [QPlayAutoManager sharedInstance].appInfo;
    if(appInfo==nil || appInfo.appId.length==0 || appInfo.bundleId.length==0)
    {
        return NO;
    }
    NSString *encryptString = [QPlayAutoSDK createEncryptString];
    
    NSInteger reqNo = [[QPlayAutoManager sharedInstance] requestOpenIDAuthWithAppId:appInfo.appId
                                                             packageName:appInfo.bundleId
                                                           encryptString:encryptString
                                                                callback:^(BOOL success, NSDictionary *dict) {
        if (success)
        {
            QMOpenIDAuthResult authResult =  [[dict objectForKey:@"ResultCode"] integerValue];
            BOOL authPass = NO;
            NSMutableDictionary *resultDict = [[NSMutableDictionary alloc] init];
            [resultDict setObject:@(authResult) forKey:@"ResultCode"];
            if (authResult == QMOpenIDAuthResult_Success)
            {
                NSString *encryptString = [dict objectForKey:@"EncryptString"];
                NSString *decryptString = [QMRSA decryptString:encryptString privateKey:[QPlayAutoManager sharedInstance].appInfo.secretKey];
                NSDictionary *decryptDict = [QQMusicUtils objectWithJsonData:[decryptString dataUsingEncoding:NSUTF8StringEncoding] error:nil targetClass:[NSDictionary class]];
                NSString *nonce = [decryptDict objectForKey:kScheme_Nonce];
                NSString *sign = [decryptDict objectForKey:kScheme_Sign];
                if (sign.length>0 && nonce.length>0)
                {
                    authPass = [QMRSA verify:nonce signature:sign pubKey:QQMusic_PubKey];
                    if (authPass)
                    {
                        //验证通过
                        NSString *openID = [decryptDict objectForKey:kScheme_OpenId];
                        NSString *openToken = [decryptDict objectForKey:kScheme_OpenToken];
                         [resultDict setObject:openID forKey:kScheme_OpenId];
                        [resultDict setObject:openToken forKey:kScheme_OpenToken];
                        NSLog(@"验证通过 OpenID:%@,OpenToken:%@",openID,openToken);
                    }
                }
            }
            if (block)
            {
                block(authPass,resultDict);
            }
        }
    }];
    return reqNo;
}

+ (NSInteger)search:(NSString*)keyword
          firstPage:(BOOL)firstPage
            calback:(QPlayAutoRequestFinishBlock)block;
{
    NSInteger reqNo = [[QPlayAutoManager sharedInstance] requestSearch:keyword firstPage:firstPage callback:block];
    return reqNo;
}

#pragma mark Private

+ (NSString*)createEncryptString
{
    QPlayAutoAppInfo *appInfo = [QPlayAutoManager sharedInstance].appInfo;
    if(appInfo==nil || appInfo.secretKey.length==0)
    {
        return nil;
    }
    NSTimeInterval time=[[NSDate date] timeIntervalSince1970];
    NSString *nonce = [NSString stringWithFormat:@"%.3f",time];
    //1.签名
    NSString *sign = [QMRSA signString:nonce privateKey:appInfo.secretKey];
    NSDictionary *signDict = @{
                               kScheme_Nonce:nonce,
                               kScheme_Sign:sign,
                               kScheme_CallbackUrl:appInfo.scheme
                               };
    NSString *sourceString =  [QQMusicUtils strWithJsonObject:signDict];
    //2.加密
    NSString *encryptString = [QMRSA encryptString:sourceString publicKey:QQMusic_PubKey];
    return encryptString;
}


#pragma mark Notivication

- (void)onNotifyConnected:(NSNotification*)notification
{
    if(QPlayAutoManager.sharedInstance.isConnected == NO){
        return;
    }
    if ([self.delegate respondsToSelector:@selector(onQPlayAutoConnectStateChanged:)])
    {
        [self.delegate onQPlayAutoConnectStateChanged:QPlayAutoConnectState_Connected];
    }
    
}

- (void)onNotifyDisconnect:(NSNotification*)notification
{
    if ([self.delegate respondsToSelector:@selector(onQPlayAutoConnectStateChanged:)])
    {
        [self.delegate onQPlayAutoConnectStateChanged:QPlayAutoConnectState_Disconnect];
    }
}

- (void)onPlayInfoChanged:(NSNotification*)notification
{
    if(QPlayAutoManager.sharedInstance.isConnected == NO){
        return;
    }
    NSDictionary *dataDict = notification.userInfo;
    QPlayAutoPlayState playState = [[dataDict objectForKey:@"State"] unsignedIntegerValue];
    NSInteger position = [[dataDict objectForKey:@"Position"]integerValue];
    NSDictionary *songDict = [dataDict objectForKey:@"Song"];
    QPlayAutoListItem *song =[[QPlayAutoListItem alloc] initWithDictionary:songDict];
    
    
    if ([self.delegate respondsToSelector:@selector(onQPlayAutoPlayStateChanged:song:position:)])
    {
        [self.delegate onQPlayAutoPlayStateChanged:playState song:song position:position];
    }
    
}

- (void)onSongFavoriteStateChange:(NSNotification*)notification
{
    if(QPlayAutoManager.sharedInstance.isConnected == NO){
        return;
    }
    NSDictionary *dataDict = notification.userInfo;
    BOOL isFav = [[dataDict objectForKey:@"isFav"] boolValue];
    NSString *songId = [dataDict objectForKey:@"SongID"];
    
    if ([self.delegate respondsToSelector:@selector(onSongFavoriteStateChange:isFavorite:)])
    {
        [self.delegate onSongFavoriteStateChange:songId isFavorite:isFav];
    }
}

- (void)onPlayModeChange:(NSNotification*)notification
{
    if(QPlayAutoManager.sharedInstance.isConnected == NO){
        return;
    }
    NSDictionary *dataDict = notification.userInfo;
    QPlayAutoPlayMode playMode = [[dataDict objectForKey:@"PlayMode"] integerValue];
    if ([self.delegate respondsToSelector:@selector(onPlayModeChange:)])
    {
        [self.delegate onPlayModeChange:playMode];
    }
}

- (void)onPlayPausedByTimeoff
{
    if(QPlayAutoManager.sharedInstance.isConnected == NO){
        return;
    }
    if ([self.delegate respondsToSelector:@selector(onPlayPausedByTimeoff)])
    {
        [self.delegate onPlayPausedByTimeoff];
    }
}

@end



