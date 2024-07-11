//
//  QPlayAutoManager.h
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QPlayAutoSDK.h"

NS_ASSUME_NONNULL_BEGIN

@interface QPlayAutoManager : NSObject

@property (nonatomic,strong) QPlayAutoAppInfo *appInfo;
@property (nonatomic,assign) BOOL isStarted;
@property (nonatomic,assign) BOOL isConnected;
@property (nonatomic,assign) BOOL isLoginOK;

+ (instancetype)sharedInstance;

- (void)connect;
- (void)reconnectWithCallback:(QPlayAutoRequestFinishBlock)block timeout:(NSTimeInterval)timeout;
- (void)stop;

- (NSInteger)requestItems:(NSString*)parentID
                pageIndex:(NSUInteger)pageIndex
                 pageSize:(NSUInteger)pageSize
                    appId:(nullable NSString*)appId         //访问用户歌单需要
                   openId:(nullable NSString*)openId        //访问用户歌单需要
                openToken:(nullable NSString*)openToken     //访问用户歌单需要
                calllback:(QPlayAutoRequestFinishBlock)block;

- (NSInteger)requestQueryFavoriteState:(NSString*)songId calllback:(QPlayAutoRequestFinishBlock)block;

- (NSInteger)requestSetFavoriteState:(BOOL)isFav songId:(NSString*)songId callback:(QPlayAutoRequestFinishBlock)block;

- (NSInteger)requestGetPlayMode:(QPlayAutoRequestFinishBlock)block;

- (NSInteger)requestSetPlayMode:(QPlayAutoPlayMode)playMode callback:(QPlayAutoRequestFinishBlock)block;

- (NSInteger)requestGetCurrentSong:(QPlayAutoRequestFinishBlock)block;

- (NSInteger)requestSetAssenceMode:(QPlayAutoAssenceMode)assenceMode callback:(QPlayAutoRequestFinishBlock)block;

- (void)requestLyric:(NSString*)songId callback:(QPlayAutoRequestFinishBlock)block;

- (void)requestMobileDeviceInfos:(QPlayAutoRequestFinishBlock)block;

- (void)requestMediaInfo:(NSString*)songId;

- (void)requestAlbumImage:(NSString*)songId pageIndex:(NSUInteger)pageIndex;

- (void)requestPlaySongList:(NSArray<NSString*>*)songIdList playIndex:(NSInteger)playIndex callback:(QPlayAutoRequestFinishBlock)block;

- (void)requestPlaySongMidList:(NSArray<NSString*>*)songMIdList playIndex:(NSInteger)playIndex callback:(QPlayAutoRequestFinishBlock)block;

- (void)reqeustPlayNext:(QPlayAutoRequestFinishBlock)block;

- (void)reqeustPlayPrev:(QPlayAutoRequestFinishBlock)block;

- (void)reqeustPlayPause;

- (void)reqeustPlayResume:(QPlayAutoRequestFinishBlock)block;

- (void)requestSeek:(NSInteger)position;

- (NSInteger)requestOpenIDAuthWithAppId:(NSString*)appId
                            packageName:(NSString*)packageName
                          encryptString:(NSString*)encryptString
                               callback:(QPlayAutoRequestFinishBlock)block;

- (NSInteger)requestSearch:(NSString*)keyword type:(QPlayAutoSearchType)type firstPage:(BOOL)firstPage callback:(QPlayAutoRequestFinishBlock)block;

- (void)requestLoginStateWithcompletion:(QPlayAutoRequestFinishBlock)completion;

@end

NS_ASSUME_NONNULL_END
