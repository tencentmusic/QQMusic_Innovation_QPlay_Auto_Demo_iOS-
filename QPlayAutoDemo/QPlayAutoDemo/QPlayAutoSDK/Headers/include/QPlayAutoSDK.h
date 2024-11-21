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

NS_ASSUME_NONNULL_BEGIN

typedef void (^QPlayAutoResultItemsBlock)(NSInteger errorCode,NSArray<QPlayAutoListItem *> *_Nullable items);
typedef void (^QPlayAutoResultParentItemBlock)(NSInteger errorCode,QPlayAutoListItem *parentItem);

extern NSString const * QPlayAutoSDKVersion;

@protocol QPlayAutoSDKDelegate <NSObject>

//连接状态变化回调
- (void)onQPlayAutoConnectStateChanged:(QPlayAutoConnectState)newState;
//播放状态状态变化回调
- (void)onQPlayAutoPlayStateChanged:(QPlayAutoPlayState)playState song:(QPlayAutoListItem *)song position:(NSInteger)position;
//歌曲播放进度
- (void)onQPlayAutoPlayProgressChanged:(QPlayAutoListItem *)song progress:(NSTimeInterval)progress duration:(NSTimeInterval)duration;
//歌曲收藏状态变化
- (void)onSongFavoriteStateChange:(NSString*)songID isFavorite:(BOOL)isFavorite;
//播放状态事件变化
- (void)onPlayModeChange:(QPlayAutoPlayMode)playMode;
//定时关闭事件
- (void)onPlayPausedByTimeoff;
//登陆状态
- (void)onLoginStateDidChanged:(BOOL)isLoginOK;
@end



@interface QPlayAutoSDK : NSObject

/// 注册App
/// @param name 名称
/// @param brand 品牌
/// @param deviceId ？
/// @param scheme 授权成功后Q音跳转合作方的scheme
/// @param appId Q音分配的Id
/// @param secretKey 合作方私钥
/// @param bundleId 合作方包名
+ (void)registerAppWithName:(NSString *)name brand:(NSString *)brand deviceId:(NSString *)deviceId scheme:(NSString *)scheme appId:(NSString *)appId secretKey:(NSString *)secretKey bundleId:(NSString *)bundleId;

/// 播放状态
+ (QPlayAutoPlayMode)currentPlayMode;
/// 当前歌曲
+ (QPlayAutoListItem *_Nullable)currentSong;
/// 当前播放状态
+ (QPlayAutoPlayState)currentPlayState;
/// 当前播放进度
+ (NSTimeInterval)currentProgress;
/// QQ音乐是否登录
+ (BOOL)isLoginOK;
///  检查QQ音乐是否已安装
+ (BOOL)isQQMusicInstalled;
/// 是否已连接
+ (BOOL)isConnected;
/// 连接中
+ (BOOL)isConnecting;
///QQ音乐设备信息
+ (NSDictionary *)deviceInfo;


///是否可以处理回调url
+ (BOOL)canHandleOpenURL:(NSURL *)url;
///处理回调url
+ (BOOL)handleOpenURL:(NSURL *)url;

/// 回调代理
+ (void)setDelegate:(id<QPlayAutoSDKDelegate>) delegate;


/// 拉端连接QPlay
/// - Parameter forceLogin: 是否强制登录
+ (void)connectAndForceLogin:(BOOL)forceLogin;
/// 停止
+ (void)stop;


/// 二次热启动连接（需要联系Q音打开此功能才能使用）
/// - Parameters:
///   - timeout: 超时时间
///   - completion: 回调
+ (void)reconnectWithTimeout:(NSTimeInterval)timeout completion:(QPlayAutoRequestFinishBlock)completion;

/// 跳转QQ音乐登录
/// @param bundleId 合作方bundleId
/// @param callbackUrl 跳转合作方url
+ (BOOL)loginQQMusicWithBundleId:(NSString *)bundleId callbackUrl:(NSString *)callbackUrl;


/// 获取数据
/// @param parent 父
/// @param pageIndex 页码
/// @param pageSize 页大小
/// @param completion 回调
+ (void)getDataItemsFromParent:(QPlayAutoListItem *)parent pageIndex:(NSUInteger)pageIndex pageSize:(NSUInteger)pageSize completion:(QPlayAutoResultParentItemBlock)completion;


/// 设置播放模式
/// @param playMode 播放模式
/// @param block 回调
+ (NSInteger)setPlayMode:(QPlayAutoPlayMode)playMode callback:(QPlayAutoRequestFinishBlock _Nullable )block;


/// 设置播放整首还是高潮
/// @param assencceMode 高潮还是整首
/// @param block 回调
+ (NSInteger)setAssenceMode:(QPlayAutoAssenceMode)assencceMode callback:(QPlayAutoRequestFinishBlock _Nullable )block;

/// 收藏/取消收藏(歌曲id)
/// @param song 歌曲
/// @param isFavorite 收藏/取消收藏
/// @param completion 回调
+ (void)setFavoriteStateWithSong:(QPlayAutoListItem *)song isFavorite:(BOOL)isFavorite completion:(void (^)(NSInteger errorCode))completion;

/// 播放歌曲
/// @param songList 歌曲列表
/// @param playIndex 播放索引
/// @param completion 回调
+ (void)playAtIndex:(NSArray<QPlayAutoListItem*> *)songList playIndex:(NSInteger)playIndex completion:(void (^)(NSInteger errorCode))completion;


/// 通过歌曲Mid列表播放歌曲
/// @param songMidList 歌曲Mid列表
/// @param playIndex 播放索引
/// @param completion 回调
+ (void)playSongMidAtIndex:(NSArray<NSString*> *)songMidList playIndex:(NSInteger)playIndex completion:(void (^)(NSInteger errorCode))completion;


///播放下一首
+ (void)playerPlayNextWithCompletion:(void (^)(NSInteger errorCode))completion;

///播放上一首
+ (void)playerPlayPrevWithCompletion:(void (^)(NSInteger errorCode))completion;

///播放暂停
+ (void)playerPlayPause;

///播放恢复
+ (void)playerPlayResumeWithCompletion:(void (^)(NSInteger errorCode))completion;

///Seek到指定位置
+ (void)playerSeek:(NSInteger)position;


/// 搜索歌曲
/// @param keyword 关键词
/// @param type 搜索类型
/// @param firstPage 是否第一页
/// @param completion 回调
+ (NSInteger)search:(NSString *)keyword
               type:(QPlayAutoSearchType)type
          firstPage:(BOOL)firstPage
         completion:(QPlayAutoResultItemsBlock)completion;

/// 相似歌曲
/// @param song 歌曲
/// @param completion 回调
+ (void)requestSimilarWithSong:(QPlayAutoListItem *)song completion:(QPlayAutoResultItemsBlock)completion;


/// 查询歌词
/// @param song 歌曲
/// @param completion 回调
+ (void)requestLyricWithSong:(QPlayAutoListItem *)song completion:(void (^)(NSInteger errorCode,QPlayAutoLyric *_Nullable lyric))completion;


/// 获取特定歌曲列表
/// @param type 列表类型
/// @param completion 回调
+ (void)requestSonglistWithType:(QPlayAutoSongListType)type completion:(QPlayAutoResultItemsBlock)completion;

@end

NS_ASSUME_NONNULL_END
