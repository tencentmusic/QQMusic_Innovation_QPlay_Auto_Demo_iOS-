//
//  QPlayAutoManager.m
//  QPlayAutoManager
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import "QPlayAutoManager.h"
#import "DiscoverSocket.h"
#import "HeartbeatSocket.h"
#import "CommandSocket.h"
#import "DataSocket.h"
#import "ResultSocket.h"
#import "QPlayAutoEntity.h"
#import "QMMacros.h"
#import <UIKit/UIDevice.h>
#import "QMNetworkHelper.h"
#import "QQMusicUtils.h"


NSString *const kQPlayAutoItemRootID = @"-1";
NSString *const kQPlayAutoCmd_MobileDeviceInfos = @"MobileDeviceInfos";
NSString *const kQPlayAutoCmd_LoginState = @"LoginState";
NSString *const kQPlayAutoCmd_DeviceInfos = @"DeviceInfos";
NSString *const kQPlayAutoCmd_Items = @"Items";
NSString *const kQPlayAutoCmd_IsFavorite = @"IsFavorite";
NSString *const kQPlayAutoCmd_AddFavorite = @"AddFavorite";
NSString *const kQPlayAutoCmd_RemoveFavorite = @"RemoveFavorite";
NSString *const kQPlayAutoCmd_GetPlayMode = @"GetPlayMode";
NSString *const kQPlayAutoCmd_SetPlayMode = @"SetPlayMode";
NSString *const kQPlayAutoCmd_SetAssenceMode = @"SetAssenceMode";
NSString *const kQPlayAutoCmd_GetCurrentSong = @"GetCurrentSong";
NSString *const kQPlayAutoCmd_PICData = @"PICData";
NSString *const kQPlayAutoCmd_LyricData = @"LyricData";
NSString *const kQPlayAutoCmd_Search = @"Search";
NSString *const kQPlayAutoCmd_Disconnect = @"Disconnect";
NSString *const kQPlayAutoCmd_MediaInfo = @"MediaInfo";
NSString *const kQPlayAutoCmd_PCMData = @"PCMData";
NSString *const kQPlayAutoCmd_PlaySongIdList = @"PlaySongIdList";
NSString *const kQPlayAutoCmd_PlaySongMIdList = @"PlaySongMidList";
NSString *const kQPlayAutoCmd_PlayNext = @"PlayNext";
NSString *const kQPlayAutoCmd_PlayPrev = @"PlayPrev";
NSString *const kQPlayAutoCmd_PlayPause = @"PlayPause";
NSString *const kQPlayAutoCmd_PlayResume = @"PlayResume";
NSString *const kQPlayAutoCmd_PlaySeek = @"PlaySeek";
NSString *const kQPlayAutoCmd_Heartbeat = @"Heartbeat";
NSString *const kQPlayAutoCmd_CommInfos = @"CommInfos";
NSString *const kQPlayAutoCmd_Auth = @"Auth";
NSString *const kQPlayAutoCmd_Reconnect = @"Reconnect";

NSString *const kQPlayAutoInfo_LastConnectInfo = @"kQMQPlayAutoInfo_LastConnectInfo";

@interface QPlayAutoManager()<CommandSocketDelegate,DiscoverSocketDelegate,ResultSocketDelegate,DataSocketDelegate>

@property (nonatomic,strong) DiscoverSocket *discoverSocket;
@property (nonatomic,strong) HeartbeatSocket *heartbeatSocket;
@property (nonatomic,strong) CommandSocket *commandSocket;
@property (nonatomic,strong) DataSocket *dataSocket;
@property (nonatomic,strong) ResultSocket *resultSocket;
@property (nonatomic,strong) NSTimer *checkHeartbeatTimer;
@property (nonatomic,assign) NSTimeInterval lastHeartbeatTime;

@property (nonatomic,assign) int qmCommandPort;
@property (nonatomic,assign) int qmResultPort;
@property (nonatomic,strong) NSString *qmHost;

@property (nonatomic,assign) NSInteger requestNo;
@property (nonatomic,strong) NSMutableDictionary<NSString *,QPlayAutoRequestInfo *> *requestDic;
@property (nonatomic,strong) QPlayAutoListItem *rootItem;

@property (nonatomic,strong,nullable) QPlayAutoAppInfo *lastConnectAppInfo;
@property (nonatomic,strong) dispatch_source_t timeoutTimer;
@property (nonatomic,copy,nullable) QPlayAutoRequestFinishBlock reconnectBlock;
@property (nonatomic,strong) NSMutableData *dataBuffer;
@end


@implementation QPlayAutoManager

+ (instancetype)sharedInstance
{
    static QPlayAutoManager* g_dQPlayAutoManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_dQPlayAutoManager = [[QPlayAutoManager alloc] init];
    });
    return g_dQPlayAutoManager;
}

#pragma mark - Getter & Setter
- (NSMutableData *)dataBuffer 
{
    if(!_dataBuffer)
    {
        _dataBuffer = [NSMutableData data];
    }
    return _dataBuffer;
}

- (void)setLastConnectAppInfo:(QPlayAutoAppInfo *)lastConnectAppInfo
{
    NSData *encodedAppInfo = [NSKeyedArchiver archivedDataWithRootObject:lastConnectAppInfo];
    [[NSUserDefaults standardUserDefaults] setObject:encodedAppInfo forKey:kQPlayAutoInfo_LastConnectInfo];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (QPlayAutoAppInfo *)lastConnectAppInfo 
{
    NSData *encodedAppInfo = [[NSUserDefaults standardUserDefaults] objectForKey:kQPlayAutoInfo_LastConnectInfo];
    if (encodedAppInfo)
    {
        QPlayAutoAppInfo *appInfo = [NSKeyedUnarchiver unarchiveObjectWithData:encodedAppInfo];
        return appInfo;
    }
    return nil;
}

- (void)connect
{
    if(self.appInfo == nil)
    {
        NSLog(@"[IPC] 注册信息为空");
        return;
    }
    if (self.appInfo.deviceType!=APP_DEVICE_TYPE)
    {
        //App方式的不再用发广播，直接使用scheme拉起来连接
        self.discoverSocket = [[DiscoverSocket alloc] init];
        self.discoverSocket.appInfo = self.appInfo;
        [self.discoverSocket start];
        self.discoverSocket.delegate = self;
    }
    
    self.commandSocket = [[CommandSocket alloc] init];
    [self.commandSocket start];
    self.commandSocket.delegate = self;
    
    self.dataSocket = [[DataSocket alloc] init];
    self.dataSocket.delegate = self;
    [self.dataSocket start];
    self.requestDic = [[NSMutableDictionary alloc]init];
    
    self.isConnected = NO;
    self.isStarted = YES;
}

- (void)reconnectWithCallback:(QPlayAutoRequestFinishBlock)block timeout:(NSTimeInterval)timeout
{
    if(self.lastConnectAppInfo == nil)
    {
        block(NO,@{@"info":@"不重连(无上次连接成功记录)"});
        return;
    }
    if([self.lastConnectAppInfo.appId isEqualToString:self.appInfo.appId] == NO)
    {
        self.lastConnectAppInfo = nil;
        block(NO,@{@"info":@"不重连(appId不一样)"});
        return;
    }
    if([self isMoreThan24HoursWihtDate:self.lastConnectAppInfo.lastConnectDate date2:[NSDate date]])
    {
        self.lastConnectAppInfo = nil;
        block(NO,@{@"info":@"不重连(超过了24小时)"});
        return;
    }
    self.reconnectBlock = block;
    [self innerStop];
    self.isStarted = YES;
    self.appInfo = self.lastConnectAppInfo;
    self.commandSocket = [[CommandSocket alloc] init];
    self.commandSocket.destIP = self.appInfo.qmHost;
    self.commandSocket.destPort = (int)self.appInfo.qmCommandPort;
    [self.commandSocket start];
    self.commandSocket.delegate = self;
    
    self.dataSocket = [[DataSocket alloc] init];
    self.dataSocket.delegate = self;
    [self.dataSocket start];
    self.requestDic = [[NSMutableDictionary alloc] init];
    
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc] initWithRequestNO:[self getRequestId] finishBlock:block];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\",\"Arguments\":{\"appid\":\"%@\",\"devicebrand\":\"%@\",\"deviceip\":\"%@\",\"dataport\":\"%d\",\"commandport\":\"%d\",\"resultport\":\"%d\",\"packagename\":\"%@\",\"deviceid\":\"%@\",\"devicetype\":\"%d\",\"devicename\":\"%@\"}}\r\n",(long)req.requestNo,kQPlayAutoCmd_Reconnect,self.appInfo.appId,self.appInfo.brand,self.appInfo.qmHost,LocalDataPort,LocalCommandPort,LocalResultPort,self.appInfo.bundleId,self.appInfo.deviceId,APP_DEVICE_TYPE,self.appInfo.name];
    [self.commandSocket sendMsg:msg];
    
    dispatch_time_t timeoutTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC));
    self.timeoutTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_event_handler(self.timeoutTimer, ^{
        [self innerStop]; // 停止所有操作
        block(NO, @{@"info": @"重连失败(超时)"});
        dispatch_source_cancel(self.timeoutTimer);
        self.reconnectBlock = nil;
    });
    dispatch_source_set_timer(self.timeoutTimer, timeoutTime, DISPATCH_TIME_FOREVER, 0);
    dispatch_resume(self.timeoutTimer);
}

- (void)stop
{
    if(self.isConnected)
    {
        [self stopCheckHeartbeatTimer];
        [self requestDisconnect];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self innerStop];
        });
    }
    else
    {
       [self innerStop];
    }
}

- (void)innerStop
{
    self.isLoginOK = NO;
    [self.dataBuffer setLength:0];
    self.isConnected = NO;
    self.isStarted = NO;
    self.requestDic = nil;
    [self.discoverSocket stop];
    self.discoverSocket = nil;
    
    [self.commandSocket stop];
    self.commandSocket = nil;
    
    [self.dataSocket stop];
    self.dataSocket.delegate = nil;
    self.dataSocket = nil;
    
    [self.heartbeatSocket stop];
    self.heartbeatSocket = nil;
    
    [self.resultSocket stop];
    self.resultSocket = nil;
}

#pragma mark Handler

- (void)onConnectSuccess
{
    NSLog(@"连接成功 %@ %d %d",self.qmHost,self.qmResultPort,self.qmCommandPort);
    self.isConnected = YES;
    if (self.discoverSocket)
    {
        [self.discoverSocket stop];//重启或断开连接后再开启
        self.discoverSocket = nil;
    }
    self.heartbeatSocket = [[HeartbeatSocket alloc]init];
    self.heartbeatSocket.destIP = self.qmHost;
    self.heartbeatSocket.destPort = self.qmCommandPort;
    [self.heartbeatSocket start];
    
    self.resultSocket = [[ResultSocket alloc]init];
    self.resultSocket.delegate = self;
    self.resultSocket.destIP = self.qmHost;
    self.resultSocket.destPort = self.qmResultPort;
    [self.resultSocket start];
    
    self.rootItem = [[QPlayAutoListItem alloc]init];
    self.rootItem.ID = kQPlayAutoItemRootID;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyConnectSuccess object:nil];
    
    self.lastHeartbeatTime = [NSDate timeIntervalSinceReferenceDate];
    [self startCheckHeartbeatTimer];
    [self requestLoginStateWithcompletion:^(BOOL success, NSDictionary *dict) {}];
}

- (void)onDisconnect
{
    [self innerStop];
    [self stopCheckHeartbeatTimer];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyDisconnect object:nil];
}

#pragma mark --- Commands ---
//查询移动设备信息
- (void)requestMobileDeviceInfos:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\"}\r\n",(long)req.requestNo,kQPlayAutoCmd_MobileDeviceInfos];
    [self.commandSocket sendMsg:msg];
}


- (void)requestLoginStateWithcompletion:(QPlayAutoRequestFinishBlock)completion 
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:completion];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\"}\r\n",(long)req.requestNo,kQPlayAutoCmd_LoginState];
    [self.commandSocket sendMsg:msg];
}

//查询歌单目录
- (NSInteger)requestItems:(NSString*)parentID
                pageIndex:(NSUInteger)pageIndex
                 pageSize:(NSUInteger)pageSize
                    appId:(nullable NSString*)appId         //访问用户歌单需要
                   openId:(nullable NSString*)openId        //访问用户歌单需要
                openToken:(nullable NSString*)openToken     //访问用户歌单需要
                calllback:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc] initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\",\"Arguments\":{\"ParentID\":\"%@\", \"PageIndex\":%tu, \"PagePerCount\":%tu,\"AppID\":\"%@\",\"OpenID\":\"%@\",\"OpenToken\":\"%@\"}}\r\n",(long)req.requestNo, kQPlayAutoCmd_Items,parentID,pageIndex,pageSize,appId,openId,openToken];
    [self.commandSocket sendMsg:msg];
    return req.requestNo;
}

- (NSInteger)requestQueryFavoriteState:(NSString*)songId calllback:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\",\"Arguments\":{\"SongID\":\"%@\"}}\r\n",(long)req.requestNo,kQPlayAutoCmd_IsFavorite,songId];
    [self.commandSocket sendMsg:msg];
    return req.requestNo;
}

- (NSInteger)requestSetFavoriteState:(BOOL)isFav songId:(NSString*)songId callback:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    NSString *cmd = isFav ? kQPlayAutoCmd_AddFavorite : kQPlayAutoCmd_RemoveFavorite;
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\",\"Arguments\":{\"SongID\":\"%@\"}}\r\n",(long)req.requestNo,cmd,songId];
    [self.commandSocket sendMsg:msg];
    return req.requestNo;
}

- (NSInteger)requestGetPlayMode:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\"}\r\n",(long)req.requestNo,kQPlayAutoCmd_GetPlayMode];
    [self.commandSocket sendMsg:msg];
    return req.requestNo;
}

- (NSInteger)requestSetPlayMode:(QPlayAutoPlayMode)playMode callback:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\",\"Arguments\":{\"IntegerValue\":%d}}\r\n",(long)req.requestNo,kQPlayAutoCmd_SetPlayMode,(int)playMode];
    [self.commandSocket sendMsg:msg];
    return req.requestNo;
}

- (NSInteger)requestSetAssenceMode:(QPlayAutoAssenceMode)assenceMode callback:(QPlayAutoRequestFinishBlock)block {
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\",\"Arguments\":{\"IntegerValue\":%d}}\r\n",(long)req.requestNo,kQPlayAutoCmd_SetAssenceMode,(int)assenceMode];
    [self.commandSocket sendMsg:msg];
    return req.requestNo;
}

- (NSInteger)requestGetCurrentSong:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\"}\r\n",(long)req.requestNo,kQPlayAutoCmd_GetCurrentSong];
    [self.commandSocket sendMsg:msg];
    return req.requestNo;
}

//查询歌曲图片
- (void)requestAlbumImage:(NSString*)songId pageIndex:(NSUInteger)pageIndex
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:nil];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\",\"Arguments\":{\"SongID\":\"%@\", \"PackageIndex\":%tu}}\r\n",(long)req.requestNo,kQPlayAutoCmd_PICData,songId,pageIndex];
    [self.commandSocket sendMsg:msg];
}

//查询歌词
- (void)requestLyric:(NSString*)songId callback:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc] initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\",\"Arguments\":{\"SongID\":\"%@\",\"PackageIndex\":%d,\"LyricType\":%d}}\r\n",(long)req.requestNo,kQPlayAutoCmd_LyricData,songId,0,1];
    [self.commandSocket sendMsg:msg];
}

//在线搜索歌曲
- (void)requestSearch:(NSString*)keyword pageIndex:(NSUInteger)pageIndex callback:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\",\"Arguments\":{\"Key\":\"%@\",\"PageFlag\":%zd}}\r\n",(long)req.requestNo,kQPlayAutoCmd_Search,keyword,pageIndex];
    [self.commandSocket sendMsg:msg];
}

//断开连接请求
- (void)requestDisconnect
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:nil];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{ \"RequestID\":%ld,\"Request\":\"%@\"}\r\n",(long)req.requestNo,kQPlayAutoCmd_Disconnect];
    [self.commandSocket sendMsg:msg];
}

//查询歌曲播放信息
- (void)requestMediaInfo:(NSString*)songId
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:nil];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{ \"RequestID\":%ld,\"Request\":\"%@\",\"Arguments\":{\"SongID\":\"%@\"}}\r\n",(long)req.requestNo,kQPlayAutoCmd_MediaInfo,songId];
    [self.commandSocket sendMsg:msg];
}

//查询歌曲播放信息
- (void)requestPcmData:(NSString*)songId packageIndex:(NSUInteger)packageIndex
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:nil];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\", \"Arguments\":{\"SongID\":\"%@\",\"PackageIndex\":%zd}}\r\n",(long)req.requestNo,kQPlayAutoCmd_PCMData,songId,packageIndex];
    [self.commandSocket sendMsg:msg];
}

- (void)requestPlaySongList:(NSArray<NSString*>*)songIdList playIndex:(NSInteger)playIndex callback:(QPlayAutoRequestFinishBlock)block
{
    if (songIdList.count==0)
        return;
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    
    NSString *songIdJson = [QQMusicUtils strWithJsonObject:songIdList];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\", \"Arguments\":{\"SongIDLists\":%@,\"Index\":%zd}}\r\n",(long)req.requestNo,kQPlayAutoCmd_PlaySongIdList,songIdJson,playIndex];
    [self.commandSocket sendMsg:msg];
}

- (void)requestPlaySongMidList:(NSArray<NSString*>*)songMIdList playIndex:(NSInteger)playIndex callback:(QPlayAutoRequestFinishBlock)block
{
    if (songMIdList.count==0)
        return;
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    
    NSString *songIdJson = [QQMusicUtils strWithJsonObject:songMIdList];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\", \"Arguments\":{\"SongIDLists\":%@,\"Index\":%zd}}\r\n",(long)req.requestNo,kQPlayAutoCmd_PlaySongMIdList,songIdJson,playIndex];
    [self.commandSocket sendMsg:msg];
}

- (void)reqeustPlayNext:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{ \"RequestID\":%ld,\"Request\":\"%@\"}\r\n",(long)req.requestNo,kQPlayAutoCmd_PlayNext];
    [self.commandSocket sendMsg:msg];
}

- (void)reqeustPlayPrev:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{ \"RequestID\":%ld,\"Request\":\"%@\"}\r\n",(long)req.requestNo,kQPlayAutoCmd_PlayPrev];
    [self.commandSocket sendMsg:msg];
}

- (void)reqeustPlayPause
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:nil];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{ \"RequestID\":%ld,\"Request\":\"%@\"}\r\n",(long)req.requestNo,kQPlayAutoCmd_PlayPause];
    [self.commandSocket sendMsg:msg];
}

- (void)reqeustPlayResume:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{ \"RequestID\":%ld,\"Request\":\"%@\"}\r\n",(long)req.requestNo,kQPlayAutoCmd_PlayResume];
    [self.commandSocket sendMsg:msg];
}

- (void)requestSeek:(NSInteger)position
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:nil];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\", \"Arguments\":{\"IntegerValue\":%d}}\r\n",(long)req.requestNo,kQPlayAutoCmd_PlaySeek,(int)position];
    [self.commandSocket sendMsg:msg];
}

- (NSInteger)requestOpenIDAuthWithAppId:(NSString*)appId
                            packageName:(NSString*)packageName
                          encryptString:(NSString*)encryptString
                               callback:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\", \"Arguments\":{\"AppID\":\"%@\",\"PackageName\":\"%@\",\"EncryptString\":\"%@\"}}\r\n",(long)req.requestNo,kQPlayAutoCmd_Auth,appId,packageName,encryptString];
    [self.commandSocket sendMsg:msg];
    return req.requestNo;
}

- (NSInteger)requestSearch:(NSString*)keyword type:(QPlayAutoSearchType)type firstPage:(BOOL)firstPage callback:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\", \"Arguments\":{\"Key\":\"%@\",\"PageFlag\":%d,\"SearchType\":%ld}}\r\n",(long)req.requestNo,kQPlayAutoCmd_Search,keyword,firstPage?0:1,(long)type];
    [self.commandSocket sendMsg:msg];
    return req.requestNo;
}

#pragma mark ---Helpers---
-(BOOL)isMoreThan24HoursWihtDate:(NSDate *)date1 date2:(NSDate *)date2
{
    NSTimeInterval interval = [date2 timeIntervalSinceDate:date1];
    return interval > (60 * 60 * 24);
}

//获取请求ID
- (NSInteger)getRequestId
{
    @synchronized(self.requestDic)
    {
        self.requestNo += 1;
        return self.requestNo;
    }
}

- (void)startCheckHeartbeatTimer
{
    [self stopCheckHeartbeatTimer];
    self.checkHeartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(onCheckHeartbeat) userInfo:nil repeats:YES];
}

- (void)stopCheckHeartbeatTimer
{
    if (self.checkHeartbeatTimer)
    {
        [self.checkHeartbeatTimer invalidate];
        self.checkHeartbeatTimer = nil;
    }
}

- (void)onCheckHeartbeat
{
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval heartbeatTime = (now-self.lastHeartbeatTime);
    if (heartbeatTime>11)
    {
        NSLog(@"已经%.1f秒没有收到心跳包了，连接断开",heartbeatTime);
        [self onDisconnect];
    }
}

#pragma mark ---- DataSocketDelegate ----
- (void)onDataSocket:(DataSocket *)socket recvData:(NSData *)data 
{
    if(data.length)
    {
        if(self.dataBuffer.length){
            [self.dataBuffer appendData:data];
        }
        NSString *clientStr = [[NSString alloc] initWithData:self.dataBuffer.length?self.dataBuffer : data encoding:NSUTF8StringEncoding];
        if(clientStr.length)
        {
            NSArray<NSString *> *lines = [clientStr componentsSeparatedByString:@"\n"];
            NSString *jsonString = nil;
            NSMutableString *lyricsString = [NSMutableString string];
            // 遍历每一行，找到非空的第一行作为 JSON 数据
            for (NSInteger index = 0;index<lines.count;index++) {
                NSString *line = [lines objectAtIndex:index];
                if (line.length > 0 && jsonString == nil) {
                    jsonString = line;
                } else {
                    [lyricsString appendString:line];
                    if(index<lines.count-1){
                        [lyricsString appendString:@"\n"];
                    }
                }
            }
            if (jsonString) {
                NSError *error = nil;
                NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
                if (error) {
                    NSLog(@"Error parsing JSON: %@", error.localizedDescription);
                    return;
                }
                NSString *reqIdStr = [QQMusicUtils getStringFromJSON:jsonDict forKey:@"RequestID"];
                if(reqIdStr.length){
                    QPlayAutoRequestInfo *req = [self.requestDic objectForKey:reqIdStr];
                    if(req.finishBlock) {
                        [self.dataBuffer setLength:0];
                        NSMutableDictionary *result = [NSMutableDictionary dictionary];
                        if(lyricsString.length){
                            [result setObject:lyricsString forKey:@"lyricsString"];
                            req.finishBlock(YES,result);
                        }else {
                            if(data.length < 200){
                                [self.dataBuffer appendData:data];
                                NSLog(@"datasocket 数据分批次回了");
                            }else {
                                req.finishBlock(NO,result);
                            }
                        }
                    }else {
                        [self.dataBuffer setLength:0];
                    }
                }
                else {
                    [self.dataBuffer setLength:0];
                }
            } else {
                [self.dataBuffer setLength:0];
                NSLog(@"No JSON data found.");
            }
        }
    }
}

#pragma mark ---- CommandSocketDelegate ----

- (void)onCommandSocket:(CommandSocket*)socket recvData:(NSData*)data
{
    NSError *error = nil;
    NSDictionary *cmdDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    NSString *cmd = [QQMusicUtils getStringFromJSON:cmdDict forKey:@"Request"];
    NSString *reqIdStr = [QQMusicUtils getStringFromJSON:cmdDict forKey:@"RequestID"];
    
    if ([cmd isEqualToString:kQPlayAutoCmd_Heartbeat])
    {
        self.lastHeartbeatTime = [NSDate timeIntervalSinceReferenceDate];
        return;
    }
    
    if ([cmd isEqualToString:kQPlayAutoCmd_CommInfos] || [cmd isEqualToString:kQPlayAutoCmd_Reconnect])
    {
        //QQ音乐的连接信息
        if(self.timeoutTimer)
        {
            dispatch_source_cancel(self.timeoutTimer);
            self.timeoutTimer = nil;
        }
        NSDictionary *argsDict = [cmdDict objectForKey:@"Arguments"];
        self.qmCommandPort = [[argsDict objectForKey:@"CommandPort"] intValue];
        self.qmResultPort = [[argsDict objectForKey:@"ResultPort"] intValue];
        self.qmHost = self.commandSocket.destIP;
        self.commandSocket.destPort = self.qmCommandPort;
        self.appInfo.qmCommandPort = self.qmCommandPort;
        self.appInfo.qmHost = self.commandSocket.destIP;
        self.appInfo.lastConnectDate = [NSDate date];
        self.lastConnectAppInfo = self.appInfo;
        [self onConnectSuccess];
        
        if([cmd isEqualToString:kQPlayAutoCmd_Reconnect])
        {
            if(self.reconnectBlock)
            {
                self.reconnectBlock(YES,@{});
                self.reconnectBlock = nil;
            }
        }
    }
    else if ([cmd isEqualToString:kQPlayAutoCmd_DeviceInfos])
    {
        //获取设备信息
        NSString *osVer = [[UIDevice currentDevice] systemVersion];
        NSDictionary *appInfoDic = [[NSBundle mainBundle] infoDictionary];
        NSString *appVersion = [appInfoDic objectForKey:@"CFBundleShortVersionString"];
        NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":\"%@\",\"DeviceInfos\":{\"Brand\":\"%@\",\"Models\":\"%@\",\"OS\":\"%@\",\" OSVer\":\"%@\",\"AppVer\":\"%@\",\"PCMBuf\":%d, \"PICBuf\":%d, \"LRCBuf\": %d, \"Network\":1, \"Ver\":\"1.2\"}}\r\n",reqIdStr,DeviceBrand,DeviceModel,DeviceOS,osVer,appVersion,PCMBufSize,PicBufSize,LrcBufSize];
        [self.resultSocket sendMsg:msg];
        
    }
    else
    {
        NSLog(@"未处理的命令:%@",cmd);
    }
}

#pragma mark ResultSocketDelegate

- (void)onResultSocket:(ResultSocket*)socket recvData:(NSData*)data
{
    NSError *error = nil;
    NSDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    NSString *eventName = [resultDict objectForKey:@"Event"];
    if (eventName.length>0)
    {
        NSLog(@"收到事件：%@",eventName);
        //事件处理
        NSDictionary *dataDict = [resultDict objectForKey:@"Data"];
        
        if ([eventName isEqualToString:@"PlayState"])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyPlayInfo object:nil userInfo:dataDict];
        }
        else if ([eventName isEqualToString:@"SongFavoriteState"])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifySongFavariteStateChange object:nil userInfo:dataDict];
        }
        else if ([eventName isEqualToString:@"PlayMode"])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyPlayModeChange object:nil userInfo:dataDict];
        }
        else if ([eventName isEqualToString:@"QPlay_TimeOff"])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyPlayPausedByTimeOff object:nil userInfo:dataDict];
        }
        else if ([eventName isEqualToString:@"LoginState"])
        {
            self.isLoginOK = [QQMusicUtils getBoolFromJSON:dataDict forKey:@"isLoginOK"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyLoginStateDidChanged object:nil userInfo:dataDict];
        }
        return;
    }
    
    id key  =  [[resultDict allKeys] firstObject];
    if ([key isKindOfClass:[NSString class]] == NO)
    {
        return;
    }
    NSString *strKey = key;
    NSDictionary *contentDict = [resultDict objectForKey:key];
    NSObject *err = [contentDict objectForKey:@"Error"];
    NSString *reqIdStr = [NSString stringWithFormat:@"%ld",(long)[[resultDict objectForKey:@"RequestID"] integerValue]];
    
    QPlayAutoRequestInfo * req = [self.requestDic objectForKey:reqIdStr];
    if(req)
    {
        if (req.finishBlock)
        {
            BOOL success = (err== nil) || ([self changeWithValue:err] == 0);
            req.finishBlock(success, contentDict);
        }
        else
        {
            NSLog(@"请求：%@ 回调为空",strKey);
        }
    }
    else
    {
        NSLog(@"注意了！！！没有找到对应的请求");
    }
}

- (int)changeWithValue:(id)value
{
   if([value isKindOfClass:[NSNumber class]])
   {
      int intValue = [value intValue];
      return intValue;
   }
   else
   {
       return 1;
   }
}

- (void)onDiscoversocket:(nonnull DiscoverSocket *)socket {
    
}
@end
