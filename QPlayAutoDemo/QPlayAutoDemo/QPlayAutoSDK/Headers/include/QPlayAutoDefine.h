//
//  QPlayAutoDefine.h
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/17.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#ifndef QPlayAutoDefine_h
#define QPlayAutoDefine_h

extern NSString *const kQPlayAutoItemRootID;
extern NSString *const kQPlayAutoArgument_Count;
extern NSString *const kQPlayAutoArgument_PageIndex;
extern NSString *const kQPlayAutoArgument_ParentID;
extern NSString *const kQPlayAutoArgument_Lists;
extern NSString *const kQPlayAutoArgument_PlayMode;
extern NSString *const kQPlayAutoArgument_IsFav;
extern NSString *const kQPlayAutoArgument_Position;
extern NSString *const kQPlayAutoArgument_Song;
extern NSString *const kQPlayAutoArgument_SongID;
extern NSString *const kQPlayAutoArgument_State;
extern NSString *const kQPlayAutoArgument_Error;

/*
 QPlayAuto错误
 */
typedef NS_ENUM(NSUInteger, QPlayAutoError)
{
    QPlayAuto_OK=0,                             //成功
    QPlayAuto_QueryAutoFailed=100,              //查询车机信息失败
    QPlayAuto_QueryMobileFailed=101,            //查询移动设备失败
    QPlayAuto_QuerySongsFailed_WithoutID=102,   //查询歌单数据失败,父 ID 不存在
    QPlayAuto_QuerySongsFailed_NoNetwork=103,   //查询歌单数据失败,移动设备网络不通,无法下载数据
    QPlayAuto_QuerySongsFailed_Unknow=104,      //查询歌单数据失败,原因未知
    QPlayAuto_SongIDError=105,                  //歌曲 ID 不存在
    QPlayAuto_ReadError=106,                    //读取数据错误
    QPlayAuto_ParamError=107,                   //参数错误
    QPlayAuto_SystemError=108,                  //系统调用错误
    QPlayAuto_CopyRightError=109,               //无法播放,没有版权
    QPlayAuto_LoginError=110,                   //无法读取,没有登录
    QPlayAuto_PcmRepeat=111,                    //PCM 请求重复
    QPlayAuto_NoPermission=112,                 //没有权限
    QPlayAuto_NeedBuy = 113,                    //无法播放(数字专辑)
    QPlayAuto_NotSupportFormat=114,             //无法播放(不支持格式)
    QPlayAuto_NeedAuth=115,                     //需要授权
    QPlayAuto_NeedVIP = 116,                    //无法播放(需要购买VIP)
    QPlayAuto_TryListen = 117,                  //试听歌曲，购买听完整版
    QPlayAuto_TrafficAlert = 118,               //无法播放(流量弹窗阻断)
    QPlayAuto_OnlyWifi     = 119,               //无法播放(仅Wifi弹窗阻断)
    QPlayAuto_AlreadyConnected=120,             //已经连接车机
    QPlayAuto_SeekError = 121,                  //拖拽进度错误
    QPlayAuto_NoListenRight = 122,              //无法播放(无版权)
    QPlayAuto_SongNotMatch=123,                 //歌曲不匹配
    QPlayAuto_Disconnect=124,                   //连接已断开
};

/**
 QPlayAuto连接状态
 */
typedef NS_ENUM(NSUInteger, QPlayAutoConnectState)
{
    QPlayAutoConnectState_Connected  =  0,       //连接成功
    QPlayAutoConnectState_Disconnect =  1,       //断开连接
    QPlayAutoConnectState_Failed     = -1,       //连接失败
    QPlayAutoConnectState_Cancel     = -2,       //连接取消
};

/*
 QPlayAutoListItem类型
 */
typedef NS_ENUM(NSUInteger, QPlayAutoListItemType)
{
    QPlayAutoListItemType_Song   = 1,   //歌曲
    QPlayAutoListItemType_Normal = 2,   //普通目录
    QPlayAutoListItemType_Radio  = 3,   //电台
    QPlayAutoListItemType_Folder = 4,   //歌单
    QPlayAutoListItemType_Album  = 5,   //专辑
};

typedef NS_ENUM(NSUInteger, QPlayAutoSongListType)
{
    QPlayAutoSongListType_Daily = 108,   //每日30首
};


/**
 QPlayAuto播放状态
 */
typedef NS_ENUM(NSUInteger, QPlayAutoPlayState)
{
    QPlayAutoPlayState_Stop=0,      //停止
    QPlayAutoPlayState_Playing=1,   //播放
    QPlayAutoPlayState_Pause=2      //暂停
};

typedef NS_ENUM(NSInteger, QPlayAutoAssenceMode)
{
    QPlayAutoAssenceMode_Full = 0, // 默认整首播放
    QPlayAutoAssenceMode_Part = 1, // 仅播放精华片段
};

/**
 QPlayAuto播放模式
 */
typedef NS_ENUM(NSUInteger, QPlayAutoPlayMode)
{
    QPlayAutoPlayMode_SequenceCircle=0,     //列表循环
    QPlayAutoPlayMode_SingleCircle=1,       //单曲循环
    QPlayAutoPlayMode_RandomCircle=2        //随机播放
};

/**
 QPlayAuto搜索类型
 */
typedef NS_ENUM(NSInteger, QPlayAutoSearchType)
{
    QPlayAutoSearchType_Song   = 0,      //歌曲
    QPlayAutoSearchType_Album = 2,       //专辑
    QPlayAutoSearchType_Folder = 3,      //歌单
    QPlayAutoSearchType_Composite = 100, //综合
};

typedef NS_ENUM(NSInteger, QPlayAutoVipState)
{
    QPlayAutoVipState_Normal = 0,
    QPlayAutoVipState_VIP    = 1,
    QPlayAutoVipState_SVIP   = 2,
};

/**
 第三方App信息
 */
@interface QPlayAutoAppInfo : NSObject<NSCoding>

@property (nonatomic,strong) NSString *deviceId;   //AppId
@property (nonatomic,assign) NSInteger deviceType;
@property (nonatomic,strong) NSString *scheme;  //跳转scheme
@property (nonatomic,strong) NSString *brand;   //品牌
@property (nonatomic,strong) NSString *name;    //名称
@property (nonatomic,strong) NSString *appId;   //名称
@property (nonatomic,strong) NSString *secretKey;  //私钥
@property (nonatomic,strong) NSString *bundleId;   //bundleId
@property (nonatomic,assign) NSInteger qmCommandPort; //Q音接收命令端口
@property (nonatomic,strong) NSString *qmHost; //Q音接收命令IP
@property (nonatomic,strong) NSDate *lastConnectDate;//上次连接的日期
@end

@interface QPlayAutoSinger : NSObject
@property (nonatomic,strong) NSString *ID;          //ID
@property (nonatomic,strong) NSString *Mid;         //Mid
@property (nonatomic,strong) NSString *name;        //名称
@end


/*
 QPlayAuto列表项（歌单、电台、排行榜、歌曲、etc）
 */
@interface QPlayAutoListItem: NSObject

@property (nonatomic,strong) NSString *ID;            //ID
@property (nonatomic,strong) NSString *Name;          //名称
@property (nonatomic,strong) NSString *SubName;       //副标题
@property (nonatomic,strong) QPlayAutoSinger *singer; //歌手
@property (nonatomic,strong) NSString *Album;         //专辑
@property (nonatomic,strong) NSString *Mid;
@property (nonatomic,assign) QPlayAutoVipState vipState;
@property (nonatomic,assign) QPlayAutoListItemType Type;
@property (nonatomic,assign) NSInteger Duration;    //时长
@property (nonatomic,strong) NSString *CoverUri;    //封面Uri
@property (nonatomic,assign) NSInteger totalCount;  //总数
@property (nonatomic,assign) BOOL isFav; //是否收藏
@property (nonatomic,assign) BOOL isOrigin; //是否原唱
@property (nonatomic,strong) NSMutableArray<QPlayAutoListItem*> *items; //子列表
@property (nonatomic,weak)  QPlayAutoListItem *parentItem;      //父节点

@property (nonatomic,assign) BOOL isTryListen; //是否试听歌曲
@property (nonatomic,readonly) BOOL isSong;  //歌曲
@property (nonatomic,readonly) BOOL isFolder;//歌单
@property (nonatomic,readonly) BOOL isAlbum; //专辑
@property (nonatomic,readonly) BOOL isRadio; //电台
@property (nonatomic,readonly) BOOL isDirectory; //普通目录

@property (nonatomic,readonly) BOOL isVIP;      //VIP歌曲
@property (nonatomic,readonly) BOOL isSVIP;     //SVIP歌曲

- (instancetype)initWithDictionary:(NSDictionary*)dict;
- (instancetype)initSongWithId:(NSString *)identifier isFav:(BOOL)isFav;
- (instancetype)initWithId:(NSString *)identifier type:(QPlayAutoListItemType)type;

//是否是根节点
- (BOOL)isRoot;

//是否有更多
- (BOOL)hasMore;

- (QPlayAutoListItem*)findItemWithID:(NSString*)ID;

@end

/**
 QPlayAuto请求回调
 
 @param success 是否成功
 @param dict 结果Dictionary
 */
typedef void (^QPlayAutoRequestFinishBlock)(BOOL success, NSDictionary *dict);


@interface QPlayAutoRequestBase : NSObject

/** 请求类型 */
@property (nonatomic, assign) int type;

@end

@interface QPlayAutoSentence : NSObject <NSCoding>
@property (nonatomic, assign) NSInteger    startTime;
@property (nonatomic, assign) NSInteger    duration;
@property (nonatomic, strong) NSString     *text;
@end

@interface QPlayAutoLyric : NSObject <NSCoding>
@property(nonatomic,assign) BOOL isTxtType;//歌词是不是纯文本的歌词，没有时间标记
@property(nonatomic,strong) NSString *songId;
@property(nonatomic,strong) NSString *songName;
@property(nonatomic,strong) NSString *singerName;
@property(nonatomic,strong) NSString *albumName;
@property(nonatomic,strong) NSArray<QPlayAutoSentence *> *sentences;
- (NSString *)sentenceAtTime:(NSTimeInterval)time;
@end


#endif /* QPlayAutoDefine_h */
