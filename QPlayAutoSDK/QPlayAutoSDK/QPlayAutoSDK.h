//
//  QPlayAutoSDK.h
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QPlayAutoDefine.h"

#define APP_DEVICE_TYPE (3)

/**
 QPlayAutoSDK回调
 */
@protocol QPlayAutoSDKDelegate <NSObject>

//连接状态变化回调
- (void)onQPlayAutoConnectStateChanged:(QPlayAutoConnectState)newState;

//变化状态变化回调
- (void)onQPlayAutoPlayStateChanged:(QPlayAutoPlayState)playState song:(QPlayAutoListItem *)song position:(NSInteger)position;

//歌曲收藏状态变化
- (void)onSongFavoriteStateChange:(NSString*)songID isFavorite:(BOOL)isFavorite;

//播放状态事件变化
- (void)onPlayModeChange:(QPlayAutoPlayMode)playMode;

//定时关闭事件
- (void)onPlayPausedByTimeoff;

@end



@interface QPlayAutoSDK : NSObject
/**
 注册App

 @param name 名称
 @param brand 品牌
 @param deviceId ？
 @param appId Q音分配的Id
 @param secretKey 合作方私钥
 @param scheme 授权成功后Q音跳转合作方的scheme
 @param bundleId 合作方包名
 */
+ (void)registerAppWithName:(NSString *)name brand:(NSString *)brand deviceId:(NSString *)deviceId scheme:(NSString *)scheme appId:(NSString *)appId secretKey:(NSString *)secretKey bundleId:(NSString *)bundleId;

/**
 @param delegate 回调代理
 */
+ (void)setDelegate:(id<QPlayAutoSDKDelegate>) delegate;

/**
 检查QQ音乐是否已安装
 
 @return 安装返回YES，否则返回NO
 */
+ (BOOL)isQQMusicInstalled;

/**
查询qq音乐信息
*/
+ (void)requestMobileDeviceInfos:(QPlayAutoRequestFinishBlock)block;

/**
 开启QPlay
 */
+ (void)connect;
/**
  连接中
 */
+ (BOOL)isConnecting;

+ (void)reconnectWithTimeout:(NSTimeInterval)timeout completion:(QPlayAutoRequestFinishBlock)completion;

/**
 停止
 */
+ (void)stop;


/**
 是否已连接
 */
+ (BOOL)isConnected;

/**
 打开QQ音乐
 
 @return 成功返回YES，否则返回NO
 */
+ (BOOL)openQQMusicApp;


/**
 激活QQ音乐(打开并获取授权)

 @return 成功返回YES，否则返回NO
 */
+ (BOOL)activeQQMusicApp;

/**
 获取数据

 @param parentID 父ID
 @param pageIndex 页码
 @param pageSize 页大小
 @param openId 授权ID
 @param openToken 授权Token
 
 @param block 回调
 @return 请求ID
 */
+ (NSInteger)getDataItems:(NSString*)parentID
                pageIndex:(NSUInteger)pageIndex
                 pageSize:(NSUInteger)pageSize
                   openId:(nullable NSString*)openId        //访问用户歌单需要
                openToken:(nullable NSString*)openToken     //访问用户歌单需要
                calllback:(QPlayAutoRequestFinishBlock _Nullable )block;


/**
 获取当前播放信息

 @param block 回调
 @return 请求ID
 */
+ (NSInteger)getCurrentPlayInfo:(QPlayAutoRequestFinishBlock _Nullable )block;

/**
 获取当前播放模式
 
 @param block 回调
 @return 请求ID
 */
+ (NSInteger)getPlayMode:(QPlayAutoRequestFinishBlock _Nullable )block;

/**
 设置播放模式
 
 @param block 回调
 @return 请求ID
 */
+ (NSInteger)setPlayMode:(QPlayAutoPlayMode)playMode callback:(QPlayAutoRequestFinishBlock _Nullable )block;

/**
 设置播放整首还是高潮
 
 @param block 回调
 @return 请求ID
 */
+ (NSInteger)setAssenceMode:(QPlayAutoAssenceMode)assencceMode callback:(QPlayAutoRequestFinishBlock _Nullable )block;
/**
 查询收藏状态

 @param songId 歌曲ID
 @param block 回调
 @return 请求ID
 */
+ (NSInteger)queryFavoriteState:(NSString*_Nullable)songId calllback:(QPlayAutoRequestFinishBlock _Nullable )block;


/**
 设置收藏状态

 @param isFav 收藏状态
 @param songId 歌曲ID
 @param block 回调
 @return 请求ID
 */
+ (NSInteger)setFavoriteState:(BOOL)isFav songId:(NSString*_Nullable)songId callback:(QPlayAutoRequestFinishBlock _Nullable )block;


/**
 播放歌曲

 @param songList 歌曲列表
 @param playIndex 播放索引
 */
+ (void)playAtIndex:(NSArray<QPlayAutoListItem*>*_Nullable)songList playIndex:(NSInteger)playIndex callback:(QPlayAutoRequestFinishBlock _Nullable )block;


/**
 通过歌曲Mid列表播放歌曲

 @param songMidList 歌曲Mid列表
 @param playIndex 播放索引
 */
+ (void)playSongMidAtIndex:(NSArray<NSString*>*_Nullable)songMidList playIndex:(NSInteger)playIndex callback:(QPlayAutoRequestFinishBlock _Nullable )block;


/**
 播放下一首
 */
+ (void)playerPlayNext:(QPlayAutoRequestFinishBlock _Nullable )block;


/**
 播放上一首
 */
+ (void)playerPlayPrev:(QPlayAutoRequestFinishBlock _Nullable )block;


/**
 播放暂停
 */
+ (void)playerPlayPause;


/**
 播放恢复
 */
+ (void)playerResume:(QPlayAutoRequestFinishBlock _Nullable )block;


/**
 Seek到指定位置

 @param position 秒
 */
+ (void)playerSeek:(NSInteger)position;


/**
 获取OpenID授权
 
 @param block 回调
 @return 请求ID
 */
+ (NSInteger)getOpenIdAuth:(QPlayAutoRequestFinishBlock _Nullable )block;


/**
 搜索歌曲
 
 @param keyword 关键词
 @param firstPage 是否第一页
 @return 请求ID
 */
+ (NSInteger)search:(NSString*_Nullable)keyword
          firstPage:(BOOL)firstPage
            calback:(QPlayAutoRequestFinishBlock _Nullable )block;
@end
