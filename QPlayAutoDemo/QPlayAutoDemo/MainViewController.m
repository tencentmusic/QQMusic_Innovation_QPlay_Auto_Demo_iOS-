//
//  MainViewController.m
//  QPlayAutoDemo
//
//  Created by macrzhou on 2024/8/6.
//  Copyright © 2024 腾讯音乐. All rights reserved.
//

#import "MainViewController.h"
#import "QPlayAutoSDK.h"
#import "MainTableCell.h"
#import "Masonry.h"
#import "ResultsViewController.h"
#import "MJRefresh.h"
#import "CustomSlider.h"
#import "SDWebImage.h"

#define NormalPageSize  (30)

@interface MainViewController ()<QPlayAutoSDKDelegate,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate>
@property (nonatomic) UIActivityIndicatorView *indicatorView;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) CustomSlider *slider;
@property (nonatomic) UIButton *playButton;
@property (nonatomic) UIButton *modeButton;
@property (nonatomic) UIButton *loveButton;
@property (nonatomic) UIButton *nextButton;
@property (nonatomic) UIButton *previousButton;
@property (nonatomic) UILabel *beginTimeLabel;
@property (nonatomic) UILabel *endTimeLabel;
@property (nonatomic) UIView *bottomView;
@property (nonatomic) UIImageView *coverImageView;
@property (nonatomic) UILabel *songLabel;
@property (nonatomic) UILabel *singerLabel;
@property (nonatomic) UISegmentedControl *assenceSegmentedControl;
@property (nonatomic) UIButton *similarButton;
@property (nonatomic) UISearchController *searchController;
@property (nonatomic) UITapGestureRecognizer *tapped;
@property (nonatomic) UIBarButtonItem *connectButton;
@property (nonatomic) UIBarButtonItem *reconnectButton;
@property (nonatomic) UILabel *lyricLabel;
 
@property (nonatomic) QPlayAutoListItem *rootItem;
@property (nonatomic) QPlayAutoListItem *currentSong;
@property (nonatomic) QPlayAutoListItem *currentItem;
@property (nonatomic) NSString *lastSearchKeyWord;
@property (nonatomic) QPlayAutoSearchType lastSearchType;
@property (nonatomic) BOOL sliderDragged;
@property (nonatomic) NSInteger currentPageIndex;
@property (nonatomic) QPlayAutoLyric *currentLyric;
@end

@implementation MainViewController

#pragma mark - Getters
- (UIActivityIndicatorView *)indicatorView {
    if(!_indicatorView){
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        [_indicatorView setFrame:CGRectMake(0, 0, 30, 30)];
        _indicatorView.hidesWhenStopped = YES;
        [self.view addSubview:_indicatorView];
        _indicatorView.center = self.view.center;
    }
    return _indicatorView;
}


#pragma mark - life circle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self commonInit];
    [self setupConstraints];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if([QPlayAutoSDK isConnected]) {
        [self onConnected];
    } else {
        [self.connectButton setTitle:@"连接"];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)commonInit {
    [QPlayAutoSDK setDelegate:self];
    
    [self setNeedsStatusBarAppearanceUpdate];
    self.view.backgroundColor = UIColor.whiteColor;
    self.connectButton = [[UIBarButtonItem alloc] initWithTitle:@"连接" style:UIBarButtonItemStylePlain target:self action:@selector(connectButtonPressed:)];
    self.reconnectButton = [[UIBarButtonItem alloc] initWithTitle:@"重接" style:UIBarButtonItemStylePlain target:self action:@selector(reconnectButtonPressed)];
    [self.connectButton setTintColor:UIColor.orangeColor];
    [self.reconnectButton setTintColor:UIColor.orangeColor];
    self.navigationItem.leftBarButtonItems = @[self.connectButton,self.reconnectButton];
    self.navigationController.navigationBar.backgroundColor = UIColor.whiteColor;
    
    self.bottomView = [[UIView alloc] init];
    self.bottomView.backgroundColor = UIColor.systemGray5Color;
    self.tableView = [[UITableView alloc] init];
    [self.tableView registerClass:[MainTableCell class] forCellReuseIdentifier:@"MainTableCell"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 48;
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"搜索";
    self.navigationItem.searchController = self.searchController;
    self.definesPresentationContext = YES;
    self.searchController.searchBar.scopeButtonTitles = @[@"综合",@"单曲",@"歌单",@"专辑"];
    self.searchController.searchBar.delegate = self;
    self.tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped)];
    
    self.slider = [[CustomSlider alloc] init];
    [self.slider setThumbImage:[[UIImage systemImageNamed:@"circle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:12 weight:UIImageSymbolWeightRegular]] imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [self.slider addTarget:self action:@selector(onSliderValChanged:forEvent:) forControlEvents:UIControlEventValueChanged];
    
    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playButton addTarget:self action:@selector(playButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIImage *playImage = [[UIImage systemImageNamed:@"play.circle" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:45 weight:UIImageSymbolWeightRegular]] imageWithTintColor:UIColor.blackColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    [self.playButton setImage:playImage forState:UIControlStateNormal];
    [self.playButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.playButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];

    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.nextButton addTarget:self action:@selector(nextButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIImage *nextImage = [[UIImage systemImageNamed:@"forward.end" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:30 weight:UIImageSymbolWeightRegular]] imageWithTintColor:UIColor.blackColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    [self.nextButton setImage:nextImage forState:UIControlStateNormal];

    self.previousButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *previousImage = [[UIImage systemImageNamed:@"backward.end" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:30 weight:UIImageSymbolWeightRegular]] imageWithTintColor:UIColor.blackColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    [self.previousButton setImage:previousImage forState:UIControlStateNormal];
    [self.previousButton addTarget:self action:@selector(previousButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    self.loveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *loveImage = [[UIImage systemImageNamed:@"heart" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:23 weight:UIImageSymbolWeightRegular]] imageWithTintColor:UIColor.redColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    [self.loveButton setImage:loveImage forState:UIControlStateNormal];
    [self.loveButton addTarget:self action:@selector(loveButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    self.modeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.modeButton addTarget:self action:@selector(modeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    self.beginTimeLabel = [[UILabel alloc] init];
    self.beginTimeLabel.textColor = UIColor.grayColor;
    self.beginTimeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    self.beginTimeLabel.text = @"00:00";
    self.beginTimeLabel.textAlignment = NSTextAlignmentLeft;
    [self.beginTimeLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.beginTimeLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    
    self.endTimeLabel = [[UILabel alloc] init];
    self.endTimeLabel.textColor = UIColor.grayColor;
    self.endTimeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    self.endTimeLabel.text = @"00:00";
    self.endTimeLabel.textAlignment = NSTextAlignmentRight;
    
    self.coverImageView = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"photo" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightRegular]] imageWithTintColor:UIColor.lightGrayColor renderingMode:UIImageRenderingModeAlwaysOriginal]];
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverImageView.clipsToBounds = YES;
    
    self.songLabel = [[UILabel alloc] init];
    self.songLabel.textAlignment = NSTextAlignmentLeft;
    self.songLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    self.songLabel.textColor = UIColor.blackColor;
    
    self.singerLabel = [[UILabel alloc] init];
    self.singerLabel.textAlignment = NSTextAlignmentLeft;
    self.singerLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.singerLabel.textColor = [UIColor.blackColor colorWithAlphaComponent:0.5];
    
    self.assenceSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"整首",@"高潮"]];
    self.assenceSegmentedControl.selectedSegmentIndex = 0;
    [self.assenceSegmentedControl addTarget:self action:@selector(assenceSegmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
    [self.assenceSegmentedControl setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.assenceSegmentedControl setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    self.similarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.similarButton setTitle:@"相似歌曲" forState:UIControlStateNormal];
    self.similarButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [self.similarButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    self.similarButton.backgroundColor = UIColor.whiteColor;
    self.similarButton.layer.cornerRadius = 6;
    [self.similarButton addTarget:self action:@selector(similarButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.similarButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.similarButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self setupRightMenu];
    
    self.lyricLabel = [[UILabel alloc] init];
    self.lyricLabel.textAlignment = NSTextAlignmentCenter;
    self.lyricLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    self.lyricLabel.textColor = UIColor.redColor;
    
    [self.view addSubview:self.bottomView];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.playButton];
    [self.view addSubview:self.slider];
    [self.view addSubview:self.nextButton];
    [self.view addSubview:self.previousButton];
    [self.view addSubview:self.modeButton];
    [self.view addSubview:self.beginTimeLabel];
    [self.view addSubview:self.endTimeLabel];
    [self.view addSubview:self.loveButton];
    [self.view addSubview:self.coverImageView];
    [self.view addSubview:self.songLabel];
    [self.view addSubview:self.singerLabel];
    [self.view addSubview:self.assenceSegmentedControl];
    [self.view addSubview:self.similarButton];
    [self.view addSubview:self.lyricLabel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)setupRightMenu {
    UIAction *action1 = [UIAction actionWithTitle:@"回首页" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [self resetContent];
        [self requestContent:self.rootItem pageIndex:0 pageSize:NormalPageSize];
    }];
    UIAction *action2 = [UIAction actionWithTitle:@"登陆QQ音乐" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        if(QPlayAutoSDK.isLoginOK == NO) {
            [QPlayAutoSDK loginQQMusicWithBundleId:@"com.tencent.QPlayAutoDemo" callbackUrl:@"qplayautodemo://"];
        }else {
            [self showAlertWithContent:@"QQ音乐 已经登陆了"];
        }
    }];
    UIAction *action3 = [UIAction actionWithTitle:@"设备信息" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [self showAlertWithContent:[NSString stringWithFormat:@"%@",QPlayAutoSDK.deviceInfo]];
    }];
    __weak __typeof(self)weakSelf = self;
    UIAction *action4 = [UIAction actionWithTitle:@"每日30首" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [QPlayAutoSDK requestSonglistWithType:QPlayAutoSongListType_Daily completion:^(NSInteger errorCode, NSArray<QPlayAutoListItem *> * _Nullable items) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if(items.count) {
                [strongSelf resetContent];
                [strongSelf.currentItem.items addObjectsFromArray:items];
                [strongSelf.tableView reloadData];
            } else {
                [strongSelf showAlertWithContent:[NSString stringWithFormat:@"errorCode:%ld",(long)errorCode]];
            }
        }];
    }];
    UIAction *action5 = [UIAction actionWithTitle:@"通过SongId播歌" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        UIAlertController *vc = [UIAlertController alertControllerWithTitle:@"通过SongId播歌" message:@"请输入songId" preferredStyle:UIAlertControllerStyleAlert];
        [vc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = @"269707426|1";
        }];
        [vc addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [vc addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if(vc.textFields.firstObject.text.length){
                QPlayAutoListItem *item = [[QPlayAutoListItem alloc] init];
                item.ID = vc.textFields.firstObject.text;
                item.Type = QPlayAutoListItemType_Song;
                [QPlayAutoSDK playAtIndex:@[item] playIndex:0 completion:^(NSInteger errorCode) {
                    [self showAlertWithContent:[NSString stringWithFormat:@"errorCode(%ld)",(long)errorCode]];
                }];
            }
        }]];
        [self presentViewController:vc animated:YES completion:nil];
    }];
    UIMenu *menu = [UIMenu menuWithTitle:@"" children:@[action1, action2,action3,action4,action5]];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage systemImageNamed:@"ellipsis" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightRegular]] imageWithTintColor:UIColor.orangeColor renderingMode:UIImageRenderingModeAlwaysOriginal] menu:menu];
}

- (void)setupConstraints {
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.top.equalTo(self.view);
    }];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(self.view.mas_height).multipliedBy(0.24);
    }];
    [self.lyricLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.bottom.mas_equalTo(self.bottomView.mas_top);
        make.top.mas_equalTo(self.tableView.mas_bottom);
        make.height.mas_equalTo(30);
    }];
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.bottom.mas_equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
    [self.nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.playButton.mas_centerY);
        make.leading.mas_equalTo(self.playButton.mas_trailing).offset(40);
    }];
    [self.previousButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.playButton.mas_centerY);
        make.trailing.mas_equalTo(self.playButton.mas_leading).offset(-40);
    }];
    [self.loveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.playButton.mas_centerY);
        make.trailing.mas_equalTo(self.view.mas_trailing).offset(-20);
    }];
    [self.modeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.playButton.mas_centerY);
        make.leading.mas_equalTo(self.view.mas_leading).offset(20);
    }];
    [self.slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.coverImageView.mas_leading);
        make.trailing.mas_equalTo(self.loveButton.mas_trailing);
        make.height.mas_equalTo(1);
        make.top.mas_equalTo(self.bottomView.mas_top).offset(10);
    }];
    [self.beginTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.slider.mas_leading);
        make.top.mas_equalTo(self.slider.mas_bottom).offset(3);
    }];
    [self.endTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.slider.mas_trailing);
        make.top.mas_equalTo(self.slider.mas_bottom).offset(3);
    }];
    [self.coverImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.modeButton.mas_leading);
        make.top.mas_equalTo(self.beginTimeLabel.mas_bottom).offset(8);
        make.bottom.mas_equalTo(self.modeButton.mas_top).offset(-20);
        make.width.mas_equalTo(self.coverImageView.mas_height);
    }];
    [self.assenceSegmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self.coverImageView.mas_bottom);
        make.trailing.mas_equalTo(self.loveButton.mas_trailing);
        make.width.mas_equalTo(80);
    }];
    [self.similarButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.loveButton.mas_trailing);
        make.top.mas_equalTo(self.coverImageView.mas_top);
        make.width.mas_equalTo(self.assenceSegmentedControl.mas_width);
    }];
    [self.songLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self.coverImageView.mas_centerY);
        make.leading.mas_equalTo(self.coverImageView.mas_trailing).offset(4);
        make.trailing.mas_lessThanOrEqualTo(self.assenceSegmentedControl.mas_leading).offset(-3);
    }];
    [self.singerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.coverImageView.mas_centerY).offset(2);
        make.leading.trailing.equalTo(self.songLabel);
    }];
}

#pragma mark -SDK交互-
- (void)onConnected {
    [self resetContent];
    [self requestContent:self.rootItem pageIndex:0 pageSize:NormalPageSize];
    [self.connectButton setTitle:@"断开"];
    [self.tableView reloadData];
}

- (void)onDisconnect {
    self.currentItem=nil;
    self.currentSong = nil;
    [self.tableView reloadData];
    [self.connectButton setTitle:@"连接"];
}

- (void)requestContent:(QPlayAutoListItem*)parentItem pageIndex:(NSUInteger)pageIndex pageSize:(NSUInteger)pageSize {
    __weak __typeof(self)weakSelf = self;
    [QPlayAutoSDK getDataItemsFromParent:parentItem pageIndex:pageIndex pageSize:pageSize completion:^(NSInteger errorCode, QPlayAutoListItem * _Nonnull parentItem) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if(errorCode == 0) {
            strongSelf.currentItem = parentItem;
            [strongSelf.tableView reloadData];
        }
        [strongSelf.tableView.mj_footer endRefreshing];
    }];
}

- (void)resetContent
{
    self.currentLyric = nil;
    self.currentPageIndex = 0;
    self.lastSearchKeyWord = nil;
    self.rootItem = [[QPlayAutoListItem alloc] init];
    self.rootItem.items = [NSMutableArray array];
    self.rootItem.ID = kQPlayAutoItemRootID;
    self.currentItem = self.rootItem;
    self.songLabel.text = nil;
    self.singerLabel.text = nil;
    self.lyricLabel.text = nil;
}

#pragma mark - QPlayAutoSDKDelegate
- (void)onSongFavoriteStateChange:(NSString *)songID isFavorite:(BOOL)isFavorite {
    if(self.currentSong && [self.currentSong.ID isEqualToString:songID]){
        self.currentSong.isFav = isFavorite;
        [self updateUIWithSong:self.currentSong];
    }
}

- (void)onQPlayAutoPlayProgressChanged:(QPlayAutoListItem *)song progress:(NSTimeInterval)progress duration:(NSTimeInterval)duration {
    if(self.sliderDragged == NO){
        self.slider.maximumValue = duration;
        self.slider.value = progress;
        self.beginTimeLabel.text = [self formatDuration:progress];
    }
    if(self.currentLyric && [self.currentLyric.songId isEqualToString:song.ID]){
        self.lyricLabel.text = [self.currentLyric sentenceAtTime:progress];
    }else {
        self.lyricLabel.text = nil;
    }
}

-(void)onPlayPausedByTimeoff {
    [self showAlertWithContent:@"糟糕 定时关闭了"];
}

- (void)onLoginStateDidChanged:(BOOL)isLoginOK {
    [self setupRightMenu];
}

- (void)onPlayModeChange:(QPlayAutoPlayMode)playMode {
    UIImage *modeImage = nil;
    switch (playMode) {
        case QPlayAutoPlayMode_SingleCircle:
            modeImage = [[UIImage systemImageNamed:@"repeat.1.circle" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:25 weight:UIImageSymbolWeightRegular]] imageWithTintColor:UIColor.systemTealColor renderingMode:UIImageRenderingModeAlwaysOriginal];
            break;
        case QPlayAutoPlayMode_RandomCircle:
            modeImage = [[UIImage systemImageNamed:@"shuffle.circle" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:25 weight:UIImageSymbolWeightRegular]] imageWithTintColor:UIColor.systemTealColor renderingMode:UIImageRenderingModeAlwaysOriginal];
            break;
        case QPlayAutoPlayMode_SequenceCircle:
            modeImage = [[UIImage systemImageNamed:@"repeat.circle" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:25 weight:UIImageSymbolWeightRegular]] imageWithTintColor:UIColor.systemTealColor renderingMode:UIImageRenderingModeAlwaysOriginal];
            break;
    }
    [self.modeButton setImage:modeImage forState:UIControlStateNormal];
}

- (void)onQPlayAutoConnectStateChanged:(QPlayAutoConnectState)newState {
    switch (newState) {
        case QPlayAutoConnectState_Disconnect:
            [self onDisconnect];
            break;
        case QPlayAutoConnectState_Connected:
            [self onConnected];
            break;
        case QPlayAutoConnectState_Cancel:
            [self showAlertWithContent:@"取消连接"];
            break;
        case QPlayAutoConnectState_Failed:
            [self showAlertWithContent:@"连接失败"];
            break;
    }
}

- (void)onQPlayAutoPlayStateChanged:(QPlayAutoPlayState)playState song:(QPlayAutoListItem *)song position:(NSInteger)position {
    NSLog(@"state change:(%lu)",(unsigned long)playState);
    switch (playState) {
        case QPlayAutoPlayState_Stop:
            [self.playButton setImage:[[UIImage systemImageNamed:@"play.circle" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:45 weight:UIImageSymbolWeightRegular]] imageWithTintColor:UIColor.blackColor renderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
            break;
        case QPlayAutoPlayState_Pause:
            [self.playButton setImage:[[UIImage systemImageNamed:@"play.circle" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:45 weight:UIImageSymbolWeightRegular]] imageWithTintColor:UIColor.blackColor renderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
            break;
        case QPlayAutoPlayState_Playing:
            [self.playButton setImage:[[UIImage systemImageNamed:@"pause.circle" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:45 weight:UIImageSymbolWeightRegular]] imageWithTintColor:UIColor.blackColor renderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
            break;
    }
    [self updateUIWithSong:song];
    self.slider.value = position;
    self.beginTimeLabel.text = [self formatDuration:position];
}

#pragma mark - Notifactions
- (void)keyboardDidShow:(NSNotification *)notification {
    [self.view addGestureRecognizer:self.tapped];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self.view removeGestureRecognizer:self.tapped];
}

#pragma mark - Actions
- (void)connectButtonPressed:(UIBarButtonItem *)sender {
    if([QPlayAutoSDK isConnected]) {
        [QPlayAutoSDK stop];
        self.currentItem = nil;
        self.currentSong = nil;
        [self.connectButton setTitle:@"连接"];
        [self.tableView reloadData];
    } else {
        if(QPlayAutoSDK.isConnecting == NO){
            [QPlayAutoSDK connectAndForceLogin:YES];
        } else {
            [self showAlertWithContent:@"正在重连中"];
        }
    }
}

- (void)reconnectButtonPressed {
    if(QPlayAutoSDK.isConnecting == NO){
        [QPlayAutoSDK reconnectWithTimeout:3 completion:^(BOOL success, NSDictionary *dict) {
            if(success)
            {
                [self showAlertWithContent:@"重连成功了😊"];
            }
            else
            {
                NSString *info = [NSString stringWithFormat:@"重连失败了😭 \n %@",[dict objectForKey:@"info"]];
                [self showAlertWithContent:info];
            }
        }];
    }
}

- (void)viewTapped {
    [self.searchController.searchBar resignFirstResponder];
    [self.view endEditing:YES];
}

- (void)assenceSegmentedControlChanged:(UISegmentedControl*)sender {
    if (sender.selectedSegmentIndex == 0) {
        [QPlayAutoSDK setAssenceMode:QPlayAutoAssenceMode_Full callback:^(BOOL success, NSDictionary *dict) {
            [self showAlertWithContent:success?@"设置 播放整首 成功":@"设置 播放整首 失败"];
        }];
    } else {
        [QPlayAutoSDK setAssenceMode:QPlayAutoAssenceMode_Part callback:^(BOOL success, NSDictionary *dict) {
            [self showAlertWithContent:success?@"设置 播放高潮 成功":@"设置 播放高潮 失败"];
        }];
    }
}

- (void)loadMoreData {
    if(QPlayAutoSDK.isConnected){
        __weak __typeof(self)weakSelf = self;
        if(self.lastSearchKeyWord.length){
            [QPlayAutoSDK search:self.lastSearchKeyWord type:self.lastSearchType firstPage:NO completion:^(NSInteger errorCode, NSArray<QPlayAutoListItem *> * _Nullable items) {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf.tableView.mj_footer endRefreshing];
                if(items.count){
                    [self.currentItem.items addObjectsFromArray:items];
                }
                [strongSelf.tableView reloadData];
                
            }];
        }else if (self.currentItem && self.currentItem.isSong == NO && self.currentItem.hasMore) {
            self.currentPageIndex++;
            [self requestContent:self.currentItem pageIndex:self.currentPageIndex pageSize:NormalPageSize];
        }else {
            [self.tableView.mj_footer endRefreshing];
        }
    } else {
        [self.tableView.mj_footer endRefreshing];
    }
}

- (void)lyricButtonPressed:(UIButton *)sender {
    QPlayAutoListItem *item = [self.currentItem.items objectAtIndex:sender.tag];
    [self.indicatorView startAnimating];
    __weak __typeof(self)weakSelf = self;
    [QPlayAutoSDK requestLyricWithSong:item completion:^(NSInteger errorCode, QPlayAutoLyric * _Nullable lyric) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf.indicatorView stopAnimating];
        if(lyric) {
            [strongSelf showAlertWithContent:lyric.text];
        } else {
            [strongSelf showAlertWithContent:[NSString stringWithFormat:@"获取歌词失败(%@)",item.Name]];
        }
    }];
}

- (void)onSliderValChanged:(UISlider*)slider forEvent:(UIEvent*)event {
    UITouch *touchEvent = [[event allTouches] anyObject];
    switch (touchEvent.phase) {
        case UITouchPhaseBegan:
            self.sliderDragged = YES;
            break;
        case UITouchPhaseMoved:
            self.beginTimeLabel.text = [self formatDuration:slider.value];
            break;
        case UITouchPhaseEnded:
            [QPlayAutoSDK playerSeek:slider.value];
            self.sliderDragged = NO;
            break;
        default:
            break;
    }
}

- (void)similarButtonPressed {
    if([QPlayAutoSDK isConnected] && self.currentSong){
        [self.indicatorView startAnimating];
        __weak __typeof(self)weakSelf = self;
        [QPlayAutoSDK requestSimilarWithSong:self.currentSong completion:^(NSInteger errorCode, NSArray<QPlayAutoListItem *> * _Nullable items) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf.indicatorView stopAnimating];
            if(items.count){
                ResultsViewController *vc = [[ResultsViewController alloc] initWithItems:items title:@"相似歌曲"];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                [self presentViewController:nav animated:YES completion:nil];
            }
        }];
    }
}

- (void)playButtonPressed {
    if(QPlayAutoSDK.currentPlayState == QPlayAutoPlayState_Playing) {
        [QPlayAutoSDK playerPlayPause];
    } else {
        [QPlayAutoSDK playerPlayResumeWithCompletion:^(NSInteger errorCode) {
            if(errorCode != 0){
                [self showAlertWithContent:[NSString stringWithFormat:@"errorCode:%ld",(long)errorCode]];
            }
        }];
    }
}

- (void)nextButtonPressed {
    [QPlayAutoSDK playerPlayNextWithCompletion:^(NSInteger errorCode) {
        if(errorCode != 0){
            [self showAlertWithContent:[NSString stringWithFormat:@"errorCode:%ld",(long)errorCode]];
        }
    }];
}

- (void)previousButtonPressed {
    [QPlayAutoSDK playerPlayPrevWithCompletion:^(NSInteger errorCode) {
        if(errorCode != 0){
            [self showAlertWithContent:[NSString stringWithFormat:@"errorCode:%ld",(long)errorCode]];
        }
    }];
}

- (void)modeButtonPressed {
    QPlayAutoPlayMode newMode;
    switch (QPlayAutoSDK.currentPlayMode) {
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
    [QPlayAutoSDK setPlayMode:newMode callback:^(BOOL success, NSDictionary *dict) {}];
}

- (void)loveButtonPressed {
    if(self.currentSong){
        [QPlayAutoSDK setFavoriteStateWithSong:self.currentSong isFavorite:!self.currentSong.isFav completion:^(NSInteger errorCode) {
            if(errorCode != 0){
                [self showAlertWithContent:@"收藏/取消收藏 失败"];
            }
        }];
    }
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    QPlayAutoListItem *listItem = [self.currentItem.items objectAtIndex:indexPath.row];
    if (listItem.Type !=QPlayAutoListItemType_Song) {
        self.currentItem = listItem;
        self.currentPageIndex = 0;
        [self.tableView reloadData];
        [self requestContent:self.currentItem pageIndex:0 pageSize:NormalPageSize];
    } else {
        [QPlayAutoSDK playAtIndex:self.currentItem.items playIndex:indexPath.row completion:^(NSInteger errorCode) {
            if(errorCode != 0){
                [self showAlertWithContent:[NSString stringWithFormat:@"%ld",(long)errorCode]];
            }
        }];
        [self updateUIWithSong:listItem];
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.currentItem.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MainTableCell *cell = (MainTableCell *)[tableView dequeueReusableCellWithIdentifier:@"MainTableCell" forIndexPath:indexPath];
    QPlayAutoListItem *listItem = [self.currentItem.items objectAtIndex:indexPath.row];
    [cell.lyricButton addTarget:self action:@selector(lyricButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    cell.lyricButton.tag = indexPath.row;
    [cell updateWithItem:listItem];
    return cell;
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {

}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if (searchBar.selectedScopeButtonIndex == 0) {
        self.lastSearchType = QPlayAutoSearchType_Composite;
    }
    else if (searchBar.selectedScopeButtonIndex == 1){
        self.lastSearchType = QPlayAutoSearchType_Song;
    }
    else if (searchBar.selectedScopeButtonIndex == 2){
        self.lastSearchType = QPlayAutoSearchType_Folder;
    }
    else if (searchBar.selectedScopeButtonIndex == 3){
        self.lastSearchType = QPlayAutoSearchType_Album;
    }
    if(searchBar.text.length){
        self.lastSearchKeyWord = searchBar.text;
        __weak __typeof(self)weakSelf = self;
        [QPlayAutoSDK search:searchBar.text type:self.lastSearchType firstPage:YES completion:^(NSInteger errorCode, NSArray<QPlayAutoListItem *> * _Nullable items) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if(items.count){
                strongSelf.currentItem = [[QPlayAutoListItem alloc] init];
                strongSelf.currentItem.items = [NSMutableArray array];
                [strongSelf.currentItem.items addObjectsFromArray:items];
                [strongSelf.tableView reloadData];
            }
        }];
    }
}

#pragma mark - Helpers
- (void)showAlertWithContent:(NSString *)content
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:content preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)updateUIWithSong:(QPlayAutoListItem *)song {
    if(song.CoverUri.length){
        [self.coverImageView sd_setImageWithURL:[NSURL URLWithString:song.CoverUri]];
    }
    self.songLabel.text = song.Name;
    self.singerLabel.text = song.singer.name;
    self.slider.maximumValue = song.Duration;
    self.endTimeLabel.text = [self formatDuration:song.Duration];
    UIImage *loveImage = [[UIImage systemImageNamed:song.isFav?@"heart.fill":@"heart" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:23 weight:UIImageSymbolWeightRegular]] imageWithTintColor:song.isFav?UIColor.redColor:UIColor.systemTealColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    [self.loveButton setImage:loveImage forState:UIControlStateNormal];
    if([song.ID isEqualToString:self.currentSong.ID] == NO) {
        __weak __typeof(self)weakSelf = self;
        [QPlayAutoSDK requestLyricWithSong:song completion:^(NSInteger errorCode, QPlayAutoLyric * _Nullable lyric) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if(lyric){
                strongSelf.currentLyric = lyric;
            }else {
                [self showAlertWithContent:[NSString stringWithFormat:@"%ld",(long)errorCode]];
            }
        }];
    }
    self.currentSong = song;
}

- (NSString *)formatDuration:(NSInteger)seconds {
    NSInteger minutes = seconds / 60;
    NSInteger remainingSeconds = seconds % 60;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)remainingSeconds];
}

@end
