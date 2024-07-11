//
//  QMMacros.h
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#ifndef QMMacros_h
#define QMMacros_h

#define DeviceID        @"X-Car-007"
#define DeviceName      @"X-Car"
#define DeviceBrand     @"QQMusic"
#define DeviceModel     @"Future"
#define DeviceOS        @"iOS"
#define RemoteCommandPort     (43921)
#define LocalCommandPort     (43911)
#define LocalResultPort      (43912)
#define LocalDataPort        (43913)
#define PCMBufSize      (1024)
#define PicBufSize      (1024)
#define LrcBufSize      (1024)

#define NormalPageSize  (30)


#define kNotifyConnectSuccess @"kNotifyConnectSuccess"
#define kNotifyDisconnect @"kNotifyDisconnect"
#define kNotifyListDataChanged @"kNotifyListDataChanged"
#define kNotifyMediaInfo @"kNotifyMediaInfo"
#define kNotifyPlayInfo @"kNotifyPlayInfo"
#define kNotifySongFavariteStateChange @"kNotifySongFavariteStateChange"
#define kNotifyPlayModeChange @"kNotifyPlayModeChange"
#define kNotifyPlayPausedByTimeOff @"kNotifyPlayPausedByTimeOff" //Q音开启了定时关闭播放
#define kNotifyLoginStateDidChanged @"kNotifyLoginStateDidChanged"

#endif /* QMMacros_h */
