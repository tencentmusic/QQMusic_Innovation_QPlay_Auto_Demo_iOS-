//
//  ResultsViewController.m
//  QPlayAutoDemo
//
//  Created by macrzhou on 2024/7/31.
//  Copyright © 2024 腾讯音乐. All rights reserved.
//

#import "ResultsViewController.h"
#import "Masonry.h"
#import "MainTableCell.h"

@interface ResultsViewController ()<UITableViewDataSource>
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSArray<QPlayAutoListItem *> *items;
@property (nonatomic) NSString *titleStr;
@end

@implementation ResultsViewController

- (instancetype)initWithItems:(NSArray *)items title:(nonnull NSString *)title{
    self = [super initWithNibName:nil bundle:nil];
    if(self){
        _items = items;
        _titleStr = title;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self commonInit];
    [self setupConstraints];
}

- (void)commonInit{
    self.navigationItem.title = self.titleStr;
    self.tableView = [[UITableView alloc] init];
    [self.tableView registerClass:[MainTableCell class] forCellReuseIdentifier:@"MainTableCell"];
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 48;
    
    [self.view addSubview:self.tableView];
}

- (void)setupConstraints{
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MainTableCell *cell = (MainTableCell *)[tableView dequeueReusableCellWithIdentifier:@"MainTableCell" forIndexPath:indexPath];
    [cell updateWithItem:self.items[indexPath.row]];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

@end
