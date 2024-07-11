//
//  MainTableCell.m
//  QPlayAutoDemo
//
//  Created by macrzhou on 2024/7/9.
//  Copyright © 2024 腾讯音乐. All rights reserved.
//

#import "MainTableCell.h"
@interface MainTableCell()
@property (nonatomic) UIImageView *albumImageView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *subtitleLabel;
@end
@implementation MainTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.albumImageView.image = nil;
}


- (void)updateWithItem:(QPlayAutoListItem *)item {
    self.titleLabel.text = item.Name;
    if(item.SubName.length){
        self.subtitleLabel.hidden = NO;
        self.subtitleLabel.text = item.SubName;
    }else {
        self.subtitleLabel.hidden = YES;
        self.subtitleLabel.text = nil;
    }
    self.lyricButton.hidden = item.Type != QPlayAutoListItemType_Song;
    if(item.CoverUri.length){
        self.albumImageView.hidden = NO;
        NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:item.CoverUri] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            UIImage *image = [UIImage imageWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.albumImageView.image = image;
            });
        }];
        [downloadTask resume];
    }else {
        self.albumImageView.hidden = YES;
        self.albumImageView.image = nil;
    }
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        if(item.CoverUri.length){
            make.leading.mas_equalTo(self.albumImageView.mas_trailing).offset(6);
        }else {
            make.leading.mas_equalTo(self.contentView.mas_leading).offset(12);
        }
        if(self.lyricButton.hidden){
            make.trailing.mas_equalTo(self.contentView.mas_trailing).offset(-6);
        }else {
            make.trailing.mas_equalTo(self.lyricButton.mas_leading).offset(-4);
        }
        if(item.SubName.length){
            make.bottom.mas_equalTo(self.contentView.mas_centerY);
        }else {
            make.centerY.mas_equalTo(self.contentView.mas_centerY);
        }
    }];
}

- (void)commonInit {
    self.albumImageView = [[UIImageView alloc] init];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    self.titleLabel.font = [UIFont systemFontOfSize:15];
    self.titleLabel.textColor = UIColor.blackColor;
    
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.textAlignment = NSTextAlignmentLeft;
    self.subtitleLabel.font = [UIFont systemFontOfSize:12];
    self.subtitleLabel.textColor = [UIColor.blackColor colorWithAlphaComponent:0.5];
    
    self.lyricButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.lyricButton setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    [self.lyricButton setTitle:@"歌词" forState:UIControlStateNormal];
    self.lyricButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    
    [self.contentView addSubview:self.albumImageView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.subtitleLabel];
    [self.contentView addSubview:self.lyricButton];
    
    [self.albumImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.contentView.mas_leading).offset(12);
        make.top.mas_equalTo(self.contentView.mas_top).offset(2);
        make.bottom.mas_equalTo(self.contentView.mas_bottom).offset(-2);
        make.width.mas_equalTo(self.albumImageView.mas_height);
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.albumImageView.mas_trailing).offset(6);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
    }];
    [self.lyricButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.contentView.mas_trailing).offset(-6);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
        make.top.bottom.mas_equalTo(self.contentView);
        make.width.mas_equalTo(self.lyricButton.mas_height);
    }];
    [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.titleLabel);
        make.top.mas_equalTo(self.contentView.mas_centerY).offset(-3);
    }];
}

@end
