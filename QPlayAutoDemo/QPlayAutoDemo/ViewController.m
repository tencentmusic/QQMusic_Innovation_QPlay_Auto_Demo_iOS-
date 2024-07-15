//
//  ViewController.m
//  QPlayAutoDemo
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import "ViewController.h"
#import "QPlayAutoSDK.h"
#import "MainTableCell.h"
#import "Masonry.h"

#define NormalPageSize  (30)
#define ID_GO_BACK @"GO_BACK"
#define ID_SEARCH_FOLDER @"SEARCH_FOLDER"
#define ID_SEARCH_SONG @"SEARCH_SONG"

@interface ViewController ()<QPlayAutoSDKDelegate,UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) QPlayAutoListItem *rootItem;
@property (nonatomic,strong) QPlayAutoListItem *currentItem;
@property (nonatomic,strong) QPlayAutoListItem *searchFolderItem;
@property (nonatomic,strong) QPlayAutoListItem *searchSongItem;
@property (nonatomic,strong) QPlayAutoListItem *currentSong;
@property (nonatomic,assign) QPlayAutoPlayState playState;
@property (nonatomic,strong) NSString *lastSearchKeyWord;
@property (nonatomic,strong) NSMutableArray<QPlayAutoListItem*> *pathStack;
@property (nonatomic,strong) NSMutableDictionary<NSString*,UIImage*> *imageCache;
@property (nonatomic,strong) NSTimer *progressTimer;
@property (nonatomic,assign) NSInteger currentProgress;
@property (nonatomic,assign) QPlayAutoPlayMode currentPlayMode;
@property (nonatomic,assign) BOOL isLove;
@property (nonatomic,assign) BOOL isLoginOK;

@property (nonatomic,strong) NSString *openId;
@property (nonatomic,strong) NSString *openToken;

@property (weak, nonatomic) IBOutlet UIButton *likeButtohn;
@property (nonatomic,strong) UISegmentedControl       *assenceSegmentedControl;
@property (nonatomic,strong) UIButton *reconnectButton;
@property (nonatomic,strong) UIButton *loginButton;
@property(nonatomic,strong) UIActivityIndicatorView *indicatorView;
@end

@implementation ViewController

- (UIActivityIndicatorView *)indicatorView {
    if(!_indicatorView){
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [_indicatorView setFrame:CGRectMake(0, 0, 30, 30)];
        _indicatorView.hidesWhenStopped = YES;
        [self.view addSubview:_indicatorView];
        _indicatorView.center = self.view.center;
    }
    return _indicatorView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [QPlayAutoSDK setDelegate:self];
    [self.tableview registerClass:[MainTableCell class] forCellReuseIdentifier:@"qplayautocell"];
    self.tableview.delegate = self;
    self.tableview.dataSource = self;
    self.tableview.rowHeight = 48;
    self.imageCache = [[NSMutableDictionary alloc]init];
    [self.btnConnect setTitleColor:[UIColor colorWithRed:50.f/255 green:188.f/255 blue:108.f/255 alpha:1] forState:UIControlStateNormal];
    [self.btnMore setTitleColor:self.btnConnect.currentTitleColor forState:UIControlStateNormal];
    [self setupUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if([QPlayAutoSDK isConnected])
    {
        [self onConnected];
    }
    else
    {
        [self.btnConnect setTitle:@"开始连接" forState:UIControlStateNormal];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _reconnectButton.layer.cornerRadius = _reconnectButton.frame.size.height/2.0;
}

- (void)setupUI {
    _assenceSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"整首",@"高潮"]];
    _assenceSegmentedControl.selectedSegmentIndex = 0;
    [_assenceSegmentedControl addTarget:self action:@selector(assenceSegmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
    _assenceSegmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_assenceSegmentedControl];
    
    _reconnectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_reconnectButton setTitle:@"重连" forState:UIControlStateNormal];
    _reconnectButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [_reconnectButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    _reconnectButton.backgroundColor = UIColor.whiteColor;
    [_reconnectButton addTarget:self action:@selector(reconnectButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_reconnectButton];
    
    NSLayoutConstraint *a = [NSLayoutConstraint constraintWithItem:_assenceSegmentedControl attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:-20];
    NSLayoutConstraint *b = [NSLayoutConstraint constraintWithItem:_assenceSegmentedControl attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_likeButtohn attribute:NSLayoutAttributeTop multiplier:1 constant:-15];
    [NSLayoutConstraint activateConstraints:@[a,b]];
    
    [self.reconnectButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.btnConnect.mas_trailing).offset(12);
        make.height.mas_equalTo(self.btnConnect.mas_height);
        make.width.centerY.equalTo(self.btnConnect);
    }];
}

- (void)assenceSegmentedControlChanged:(UISegmentedControl*)sender {
    if (sender.selectedSegmentIndex == 0) {
        [QPlayAutoSDK setAssenceMode:QPlayAutoAssenceMode_Full callback:^(BOOL success, NSDictionary *dict) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    UIAlertController *vc = [UIAlertController alertControllerWithTitle:nil message:@"设置 播放整首 成功" preferredStyle:UIAlertControllerStyleAlert];
                    [vc addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];                [self presentViewController:vc animated:YES completion:nil];
                }
                else {
                    UIAlertController *vc = [UIAlertController alertControllerWithTitle:nil message:@"设置 播放整首 失败" preferredStyle:UIAlertControllerStyleAlert];
                    [vc addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];                [self presentViewController:vc animated:YES completion:nil];
                }
                
            });
        }];
    }
    else {
        [QPlayAutoSDK setAssenceMode:QPlayAutoAssenceMode_Part callback:^(BOOL success, NSDictionary *dict) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    UIAlertController *vc = [UIAlertController alertControllerWithTitle:nil message:@"设置 播放高潮 成功" preferredStyle:UIAlertControllerStyleAlert];
                    [vc addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];                [self presentViewController:vc animated:YES completion:nil];
                }
                else {
                    UIAlertController *vc = [UIAlertController alertControllerWithTitle:nil message:@"设置 播放高潮 失败" preferredStyle:UIAlertControllerStyleAlert];
                    [vc addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];                [self presentViewController:vc animated:YES completion:nil];
                }
                
            });
        }];
    }
}

#pragma mark - Actions

- (void)reconnectButtonPressed {
    if(QPlayAutoSDK.isConnecting == NO){
        [QPlayAutoSDK reconnectWithTimeout:3 completion:^(BOOL success, NSDictionary *dict) {
            if(success)
            {
                [self showErrorCodeAlert:@"重连成功了😊"];
            }
            else
            {
                NSString *info = [NSString stringWithFormat:@"重连失败了😭 \n %@",[dict objectForKey:@"info"]];
                [self showErrorCodeAlert:info];
            }
        }];
    }
}

- (IBAction)onClickStart:(id)sender {
    if([QPlayAutoSDK isConnected])
    {
        [QPlayAutoSDK stop];
        self.currentItem = nil;
        self.currentSong = nil;
        [self.btnConnect setTitle:@"开始连接" forState:UIControlStateNormal];
        [self.tableview reloadData];
    }
    else
    {
        if(QPlayAutoSDK.isConnecting == NO){
            [QPlayAutoSDK connect];
        }
        else {
            [self showErrorCodeAlert:@"正在重连中"];
        }
    }
    
}

- (IBAction)onClickPlayPause:(id)sender {
    if(QPlayAutoSDK.isConnected==NO)
        return;
    if(self.playState == QPlayAutoPlayState_Playing)
    {
        [QPlayAutoSDK playerPlayPause];
    }
    else
    {
        [QPlayAutoSDK playerResume:^(BOOL success, NSDictionary *dict) {
            if (!success)
            {
                [self showErrorCodeAlert:[NSString stringWithFormat:@"%@",dict]];
            }
        }];
    }
}

- (IBAction)onClickPlayPrev:(id)sender {
    if(QPlayAutoSDK.isConnected==NO)
        return;
    [QPlayAutoSDK playerPlayPrev:^(BOOL success, NSDictionary *dict) {
        if (!success)
        {
            [self showErrorCodeAlert:[NSString stringWithFormat:@"%@",dict]];
        }
    }];
}

- (IBAction)onClickPlayNext:(id)sender {
    if(QPlayAutoSDK.isConnected==NO)
        return;
    [QPlayAutoSDK playerPlayNext:^(BOOL success, NSDictionary *dict) {
        if (!success)
        {
            [self showErrorCodeAlert:[NSString stringWithFormat:@"%@",dict]];
        }
    }];
}

- (IBAction)onClickPlayMode:(id)sender {
    if(QPlayAutoSDK.isConnected==NO)
        return;
    QPlayAutoPlayMode newMode;
    switch (self.currentPlayMode) {
        case QPlayAutoPlayMode_SequenceCircle:
            newMode = QPlayAutoPlayMode_RandomCircle;
            break;
        case QPlayAutoPlayMode_RandomCircle:
            newMode = QPlayAutoPlayMode_SingleCircle;
            break;
        default:
            newMode = QPlayAutoPlayMode_SequenceCircle;
            break;
    }
    [QPlayAutoSDK setPlayMode:newMode callback:^(BOOL success, NSDictionary *dict) {
        NSLog(@"setPlayMode compled:%d",(int)success);
        if(success)
        {
            self.currentPlayMode = newMode;
            [self updatePlayModeUI];
        }
    }];
}

- (IBAction)onClickLove:(id)sender {
    if(QPlayAutoSDK.isConnected==NO || self.currentSong==nil)
        return;
    [QPlayAutoSDK setFavoriteState:!self.isLove songId:self.currentSong.ID callback:^(BOOL success, NSDictionary *dict) {
        NSLog(@"setFavoriteState compled:%d",(int)success);
        if(success)
        {
            self.isLove = !self.isLove;
            [self updateFavUI:self.isLove];
        }
    }];
}

- (IBAction)onSliderSeek:(id)sender {
    if(QPlayAutoSDK.isConnected==NO || self.currentSong==nil)
        return;
    float newPos = self.progressSlider.value;
    [QPlayAutoSDK playerSeek:(NSInteger)newPos];
}

- (IBAction)onClickMore:(id)sender {
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* reloadDataAction = [UIAlertAction actionWithTitle:@"重新获取数据"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction* action)
                                   
                                   {
                                       if(QPlayAutoSDK.isConnected==NO)
                                           return;
                                       [self resetContent];
                                       [self requestContent:self.rootItem pageIndex:0 pageSize:NormalPageSize];
                                       [alertView dismissViewControllerAnimated: YES completion: nil];
                                   }];
    UIAlertAction* mvAction = [UIAlertAction actionWithTitle:@"同步播放信息"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction* action)
                               
                               {
                                   [self syncPlayInfo];
                                   [alertView dismissViewControllerAnimated: YES completion: nil];
                               }];
    UIAlertAction* midSongAction = [UIAlertAction actionWithTitle:@"Mid播放歌曲"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction* action)
                               
                               {
                                   [self playWithMid];
                                   [alertView dismissViewControllerAnimated: YES completion: nil];
                               }];
    UIAlertAction* requsetQQAction = [UIAlertAction actionWithTitle:@"查询QQ音乐信息"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction* action)
                               
                               {
                                   [self requestQQMusicInfo];
                                   [alertView dismissViewControllerAnimated: YES completion: nil];
                               }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction* action)
                                   
                                   {
                                       [alertView dismissViewControllerAnimated: YES completion: nil];
                                   }];
    UIAlertAction* loginQQAction = [UIAlertAction actionWithTitle:@"拉端登录QQ音乐"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction* action)
                               
                               {
                                   [QPlayAutoSDK loginQQMusicWithBundleId:@"com.tencent.QPlayAutoDemo" callbackUrl:@"qplayautodemo://"];
                                   [alertView dismissViewControllerAnimated: YES completion: nil];
                               }];
    
    [alertView addAction:reloadDataAction];
    [alertView addAction:mvAction];
    [alertView addAction:cancelAction];
    [alertView addAction:midSongAction];
    [alertView addAction:requsetQQAction];
    [alertView addAction:loginQQAction];
    [self presentViewController:alertView animated:NO completion:nil];
}

- (void)lyricButtonPressed:(UIButton *)sender {
    if(QPlayAutoSDK.isConnected==NO || !self.currentItem.items.count){
        return;
    }
    QPlayAutoListItem *item = [self.currentItem.items objectAtIndex:sender.tag];
    [self.indicatorView startAnimating];
    __weak __typeof(self)weakSelf = self;
    [QPlayAutoSDK requestLyricWithSongId:item.ID completion:^(BOOL success, NSDictionary *dict) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf.indicatorView stopAnimating];
        if(success){
            NSString *lyricsString = [dict objectForKey:@"lyricsString"];
            [strongSelf showErrorCodeAlert:lyricsString];
        }else {
            [strongSelf showErrorCodeAlert:[NSString stringWithFormat:@"获取歌词失败(%@)",item.Name]];
        }
    }];
}

#pragma mark Private Method

- (void)requestQQMusicInfo{
    [QPlayAutoSDK requestMobileDeviceInfos:^(BOOL success, NSDictionary *dict) {
        [self showErrorCodeAlert:[NSString stringWithFormat:@"%@",dict]];
    }];
}

- (void)startProgressTimer
{
    [self stopProgressTimer];
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(onUpdateProgress) userInfo:nil repeats:YES];
}

- (void)stopProgressTimer
{
    if (self.progressTimer)
    {
        [self.progressTimer invalidate];
        self.progressTimer = nil;
    }
}

- (void)resetContent
{
    self.rootItem = [[QPlayAutoListItem alloc]init];
    self.rootItem.ID = kQPlayAutoItemRootID;
    self.rootItem.items = [[NSMutableArray alloc]init];
    
    self.searchSongItem = [[QPlayAutoListItem alloc]init];
    self.searchSongItem.Name = @"搜索歌曲";
    self.searchSongItem.ID = ID_SEARCH_SONG;
    [self.rootItem.items addObject:self.searchSongItem];
    
    self.searchFolderItem = [[QPlayAutoListItem alloc]init];
    self.searchFolderItem.Name = @"搜索歌单";
    self.searchFolderItem.ID = ID_SEARCH_FOLDER;
    [self.rootItem.items addObject:self.searchFolderItem];
    

    
    self.currentItem = self.rootItem;
    self.pathStack = [[NSMutableArray alloc] init];
}

- (void)playWithMid
{
    //通过Mid播放陈亦迅两首歌
    [QPlayAutoSDK playSongMidAtIndex:@[@"0026ato22llymc",@"001fZLRw0Z0yRV"] playIndex:0 callback:^(BOOL success, NSDictionary *dict) {
        if (!success)
        {
            [self showErrorCodeAlert:[NSString stringWithFormat:@"%@",dict]];
        }
    }];
}

#pragma mark Update UI


- (void)updatePlayState:(QPlayAutoPlayState)playState song:(QPlayAutoListItem*)song position:(NSInteger)progress
{
    NSLog(@"- position (%ld)",(long)progress);
    if (song.Type!=QPlayAutoListItemType_Song)
        return;
    self.playState = playState;
    self.currentProgress  = progress;
    self.progressSlider.value = self.currentProgress;
    switch (playState) {
        case QPlayAutoPlayState_Stop:
            [self.btnPlayPause setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
            [self stopProgressTimer];
            break;
        case QPlayAutoPlayState_Pause:
            [self.btnPlayPause setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
            [self stopProgressTimer];
            break;
        case QPlayAutoPlayState_Playing:
            [self.btnPlayPause setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
            [self startProgressTimer];
            break;
    }
    
    if (![self.currentSong.ID isEqualToString:song.ID])
    {
        self.currentSong = song;
        [self updateCurrentSongUI];
    }
}

- (void)updateCurrentSongUI
{
    if(QPlayAutoSDK.isConnected==NO || self.currentSong==nil)
        return;
    self.progressSlider.maximumValue = (float)self.currentSong.Duration;
    self.songTitleLabel.text = self.currentSong.Name;
    self.singerLabel.text = [NSString stringWithFormat:@"%@-%@",self.currentSong.Album,self.currentSong.Artist];
    //专辑图
    if(self.currentSong.CoverUri.length>0)
    {
        UIImage *image = [self.imageCache objectForKey:self.currentSong.CoverUri];
        if(image)
        {
            [self.albumImgView setImage:image];
        }
        else
        {
            NSURL *url = [NSURL URLWithString:self.currentSong.CoverUri];
            if(url)
            {
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    NSData *data = [NSData dataWithContentsOfURL:url];
                    UIImage *image = [UIImage imageWithData:data];
                    if(image)
                    {
                        [self.imageCache setObject:image forKey:self.currentSong.CoverUri];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            [self.albumImgView setImage:image];
                        });
                    }
                });
            }
        }
    }
    
    self.isLove = NO;
    [self updateFavUI:self.isLove];
    [self syncFavState];
}

- (void)updateFavUI:(BOOL)isFav
{
    NSString *imgName = isFav ? @"loved" : @"love";
    [self.btnLove setImage:[UIImage imageNamed:imgName] forState:UIControlStateNormal];
}

- (void)updatePlayModeUI
{
    switch (self.currentPlayMode) {
        case QPlayAutoPlayMode_SingleCircle:
            [self.btnPlayMode setImage:[UIImage imageNamed:@"repeatone_normal"] forState:UIControlStateNormal];
            break;
        case QPlayAutoPlayMode_RandomCircle:
            [self.btnPlayMode setImage:[UIImage imageNamed:@"random_normal"] forState:UIControlStateNormal];
            break;
        default:
            [self.btnPlayMode setImage:[UIImage imageNamed:@"repeat_normal"] forState:UIControlStateNormal];
            break;
    }
}


- (void)onUpdateProgress
{
    if(QPlayAutoSDK.isConnected==NO)
    {
        [self stopProgressTimer];
        return;
    }
    if (self.currentSong==nil || self.playState!=QPlayAutoPlayState_Playing || self.currentSong.Duration<=0)
        return;
    self.currentProgress ++ ;
    //NSLog(@"更新进度:%d/%d",(int)self.currentProgress,(int)self.currentSong.Duration);
    if(self.currentProgress>self.currentSong.Duration)
        self.currentProgress = self.currentSong.Duration;
    else if(self.currentProgress<0)
        self.currentProgress = 0;
    self.progressSlider.value = self.currentProgress;
}


- (void)setLog:(NSString*)log
{
    NSString *logText = [NSString stringWithFormat:@"log：%@",log];
    if(NSThread.isMainThread)
    {
        [self.logLabel setText:logText];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.logLabel setText:logText];
        });
    }
}

#pragma mark SDK交互
- (void)onConnected
{
    [self setLog:@"连接成功"];
    [self resetContent];
    
    [self syncPlayInfo];
    [self syncPlayMode];
    [self requestOpenIDAuth];
    [self.btnConnect setTitle:@"停止连接" forState:UIControlStateNormal];
    [self.tableview reloadData];
}

- (void)onDisconnect
{
    [self setLog:@"连接断开"];
    [self stopProgressTimer];
    self.currentItem=nil;
    self.currentSong = nil;
    [self.tableview reloadData];
    [self.btnConnect setTitle:@"开始连接" forState:UIControlStateNormal];
}

- (void)syncPlayInfo
{
    if(QPlayAutoSDK.isConnected==NO)
        return;
    [QPlayAutoSDK getCurrentPlayInfo:^(BOOL success, NSDictionary *dataDict) {
        QPlayAutoPlayState playState = [[dataDict objectForKey:kQPlayAutoArgument_State] unsignedIntegerValue];
        NSInteger position = [[dataDict objectForKey:kQPlayAutoArgument_Position]integerValue];
        NSDictionary *songDict = [dataDict objectForKey:kQPlayAutoArgument_Song];
        QPlayAutoListItem *song =[[QPlayAutoListItem alloc] initWithDictionary:songDict];
        [self updatePlayState:playState song:song position:position];
    }];
}

- (void)syncFavState
{
    if(QPlayAutoSDK.isConnected==NO || self.currentSong==nil)
        return;
    //收藏状态
    [QPlayAutoSDK queryFavoriteState:self.currentSong.ID calllback:^(BOOL success, NSDictionary *dict) {
        if(success)
        {
            NSString *songId = [dict objectForKey:kQPlayAutoArgument_SongID];
            if([songId isEqualToString:self.currentSong.ID])
            {
                BOOL isFav = [[dict objectForKey:kQPlayAutoArgument_IsFav] boolValue];
                self.isLove = isFav;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateFavUI:isFav];
                });
            }
        }
        else
        {
            [self setLog:@"queryFavoriteState 失败"];
        }
    }];
}

- (void)syncPlayMode
{
    //同步播放模式设置
    [QPlayAutoSDK getPlayMode:^(BOOL success, NSDictionary *dict) {
        if(success)
        {
            QPlayAutoPlayMode playMode = [[dict objectForKey:kQPlayAutoArgument_PlayMode] integerValue];
            self.currentPlayMode = playMode;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updatePlayModeUI];
            });
        }
        else
        {
            [self setLog:@"getPlayMode 失败"];
        }
    }];
}

- (void)requestContent:(QPlayAutoListItem*)parentItem pageIndex:(NSUInteger)pageIndex pageSize:(NSUInteger)pageSize
{
    if(QPlayAutoSDK.isConnected==NO)
        return;
    [self setLog:[NSString stringWithFormat:@"requestContent:%@ %@",parentItem.Name,parentItem.ID]];
    [QPlayAutoSDK getDataItems:parentItem.ID
                     pageIndex:pageIndex
                      pageSize:pageSize
                        openId:self.openId
                     openToken:self.openToken
                     calllback:^(BOOL success, NSDictionary *dict) {
                         
                         NSInteger errorCode = [[dict objectForKey:@"Error"] integerValue];
                         if (errorCode!=0)
                         {
                             [self setLog:[NSString stringWithFormat:@"获取数据失败,error:%zd",errorCode]];
                             return;
                         }
                         
                         NSInteger count = [[dict objectForKey:kQPlayAutoArgument_Count] integerValue];
                         //NSInteger pageIndex = [[dict objectForKey:kQPlayAutoArgument_PageIndex] integerValue];
                         NSString *parentID = [dict objectForKey:kQPlayAutoArgument_ParentID];
                         
                         [self setLog:[NSString stringWithFormat:@"requestContent completed:%@ %@ count:%ld",parentItem.Name,parentItem.ID,(long)count]];
                         QPlayAutoListItem *currentItem = [parentItem findItemWithID:parentID];
                         NSAssert(currentItem, @"what's wrong");
                         
                         
                         
                         if (currentItem.items == nil)
                         {
                             currentItem.items = [[NSMutableArray alloc]init];
                         }
                         
                         currentItem.totalCount = count;
                         NSArray *itemList = [dict objectForKey:kQPlayAutoArgument_Lists];
                         if (itemList.count>0)
                         {
                             for(NSDictionary *itemDict in itemList)
                             {
                                 if ([itemDict isKindOfClass:[NSDictionary class]] ==NO )
                                 {
                                     continue;
                                 }
                                 QPlayAutoListItem *item = [[QPlayAutoListItem alloc] initWithDictionary:itemDict];
                                 item.parentItem = currentItem;
                                 [currentItem.items addObject:item];
                             }
                         }
                         
                         if (self.currentItem.ID == parentItem.ID)
                         {
                             [self.tableview reloadData];
                         }
                     }];
}

- (void)requestOpenIDAuth
{
    if(QPlayAutoSDK.isConnected==NO)
        return;
    [QPlayAutoSDK getOpenIdAuth:^(BOOL success, NSDictionary *dict) {
        if (success)
        {
            self.openId = [dict objectForKey:@"openId"];
            self.openToken = [dict objectForKey:@"openToken"];
            [self setLog:@"OpenId授权成功"];
        }
        else
        {
            [self setLog:@"OpenId授权失败"];
        }
        [self requestContent:self.rootItem pageIndex:0 pageSize:NormalPageSize];
    }];
}

- (void)requestSearch:(QPlayAutoSearchType)searchType
{
    if(QPlayAutoSDK.isConnected==NO)
        return;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString  stringWithFormat:@"搜索 %@",searchType==QPlayAutoSearchType_Song?@"歌曲":@"歌单"]message:@"请输入关键词" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"关键词";
        textField.text = self.lastSearchKeyWord?self.lastSearchKeyWord:@"周杰伦";
    }];
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"确定"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction* action)
                                    
                                    {
                                        [self presentViewController:alertController animated:YES completion:^{
                                            UITextField *textField = alertController.textFields.firstObject;
                                            if (textField.text.length>0){
                                                [self.indicatorView startAnimating];
                                                [QPlayAutoSDK search:textField.text type:searchType
                                                           firstPage:![textField.text isEqualToString:self.lastSearchKeyWord]
                                                             calback:^(BOOL success, NSDictionary *dict) {
                                                    [self.indicatorView stopAnimating];
                                                    NSInteger errorCode = [[dict objectForKey:@"Error"] integerValue];
                                                    if (errorCode!=0)
                                                    {
                                                        [self setLog:[NSString stringWithFormat:@"搜索失败,error:%zd",errorCode]];
                                                        return;
                                                    }
                                                    self.lastSearchKeyWord = textField.text;
                                                    NSArray *itemList = [dict objectForKey:kQPlayAutoArgument_Lists];
                                                    if (itemList.count>0)
                                                    {
                                                        for(NSDictionary *itemDict in itemList)
                                                        {
                                                            if ([itemDict isKindOfClass:[NSDictionary class]] ==NO )
                                                            {
                                                                continue;
                                                            }
                                                            QPlayAutoListItem *item = [[QPlayAutoListItem alloc] initWithDictionary:itemDict];
                                                            if (searchType==QPlayAutoSearchType_Song) {
                                                                item.parentItem = self.searchSongItem ;
                                                                [self.searchSongItem.items addObject:item];
                                                            }else{
                                                                item.parentItem = self.searchFolderItem ;
                                                                [self.searchFolderItem.items addObject:item];
                                                            }
                                                        }
                                                    }
                                                    [self.tableview reloadData];
                                                }];
                                            }
                                        }];
                                        [alertController dismissViewControllerAnimated: YES completion: nil];
                                    }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction* action)
                                   
                                   {
                                       [alertController dismissViewControllerAnimated: YES completion: nil];
                                   }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark ---tableview---

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.currentItem.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MainTableCell *cell = (MainTableCell *)[tableView dequeueReusableCellWithIdentifier:@"qplayautocell" forIndexPath:indexPath];
    QPlayAutoListItem *listItem = [self.currentItem.items objectAtIndex:indexPath.row];
    [cell.lyricButton addTarget:self action:@selector(lyricButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    cell.lyricButton.tag = indexPath.row;
    [cell updateWithItem:listItem];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.currentItem.items.count <= indexPath.row)
        return;
    QPlayAutoListItem *listItem = [self.currentItem.items objectAtIndex:indexPath.row];
    
    if ([listItem.ID isEqualToString:ID_GO_BACK])
    {
        if (self.pathStack.lastObject==nil)
        {
            self.currentItem = self.rootItem;
        }
        else
        {
            self.currentItem = self.pathStack.lastObject;
            [self.pathStack removeLastObject];
        }
        [self.tableview reloadData];
        return;
    }
    else if ([listItem.ID isEqualToString:ID_SEARCH_SONG])
    {
        self.currentItem = self.searchSongItem;
        self.currentItem.items = [[NSMutableArray alloc]init];
        QPlayAutoListItem *item = [self getGoBackItem];
        [self.currentItem.items addObject:item];
         [self.tableview reloadData];
        [self requestSearch:QPlayAutoSearchType_Song];
        return;
    }
    else if ([listItem.ID isEqualToString:ID_SEARCH_FOLDER])
    {
        self.currentItem = self.searchFolderItem;
        self.currentItem.items = [[NSMutableArray alloc]init];
        QPlayAutoListItem *item = [self getGoBackItem];
        [self.currentItem.items addObject:item];
         [self.tableview reloadData];
        [self requestSearch:QPlayAutoSearchType_Folder];
        return;
    }
    
    if (listItem.Type !=QPlayAutoListItemType_Song)
    {
        [self.pathStack addObject:self.currentItem];
        self.currentItem = listItem;
        self.currentItem.items = [[NSMutableArray alloc]init];
        if ([self.currentItem.ID isEqualToString:self.rootItem.ID]==NO)
        {
            QPlayAutoListItem *item = [self getGoBackItem];
            [self.currentItem.items addObject:item];
        }
        [self.tableview reloadData];
        
        [self requestContent:self.currentItem pageIndex:0 pageSize:NormalPageSize];
    }
    else
    {
        self.currentSong = listItem;
        
        NSArray<QPlayAutoListItem*> *songlist = [self.currentItem.items subarrayWithRange:NSMakeRange(1, self.currentItem.items.count-1)];//第一行是『..返回上一级』
        NSUInteger playIndex = [songlist indexOfObject:listItem];
        if(playIndex==NSNotFound)
        {
            playIndex = 0;
        }
        [QPlayAutoSDK playAtIndex:songlist playIndex:playIndex callback:^(BOOL success, NSDictionary *dict) {
            if (!success)
            {
                [self showErrorCodeAlert:[NSString stringWithFormat:@"%@",dict]];
            }
        }];
        [self updateCurrentSongUI];
    }
}

- (QPlayAutoListItem*)getGoBackItem
{
    QPlayAutoListItem *item = [[QPlayAutoListItem alloc] init];
    item.ID = ID_GO_BACK;
    item.Name = @"..返回上一级";
    return item;
}


#pragma mark ---QPlayAutoConnectStateDelegate---
- (void)onQPlayAutoConnectStateChanged:(QPlayAutoConnectState)newState
{
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (newState) {
            case QPlayAutoConnectState_Disconnect:
                [self onDisconnect];
                break;
            case QPlayAutoConnectState_Connected:
                [self onConnected];
                break;
            default:
                break;
        }
    }) ;
}

- (void)onQPlayAutoPlayStateChanged:(QPlayAutoPlayState)playState song:(QPlayAutoListItem*)song position:(NSInteger)position
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updatePlayState:playState song:song position:position];
    }) ;
    
}

- (void)onSongFavoriteStateChange:(NSString*)songID isFavorite:(BOOL)isFavorite
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.currentSong.ID isEqualToString:songID])
        {
            [self updateFavUI:isFavorite];
        }
    }) ;
}

- (void)onPlayModeChange:(QPlayAutoPlayMode)playMode
{
    self.currentPlayMode = playMode;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updatePlayModeUI];
    });
}

-(void)onPlayPausedByTimeoff
{
    [self showErrorCodeAlert:@"糟糕 定时关闭了"];
}

- (void)onLoginStateDidChanged:(BOOL)isLoginOK
{
    self.isLoginOK = isLoginOK;
    [self showErrorCodeAlert:[NSString stringWithFormat:@"QQ音乐 %@",isLoginOK?@"已登陆":@"未登录"]];
}

- (void)showErrorCodeAlert:(NSString *)content
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:content preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

@end
