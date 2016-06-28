//
//  DYBRecommendPhotoCell.m
//  DouyuYuba
//
//  Created by nantu on 15/9/16.
//  Copyright (c) 2015年 nantu. All rights reserved.
//

#import "RNPhotoPickerCell.h"
#import <ImageIO/ImageIO.h>

@interface RNPhotoPickerCell()

@property (strong, nonatomic) UIImageView *iconView;
@property (nonatomic, weak) UIImageView *seleBackView;
@property (nonatomic, weak) UIImageView *seleView;

@end

@implementation RNPhotoPickerCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIImageView *iconView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        self.iconView = iconView;
        [self.contentView addSubview:iconView];
        
        UIImageView *seleBackView = [[UIImageView alloc] initWithFrame:CGRectMake(iconView.frame.size.width - 28 - 10, iconView.frame.size.height - 28 - 10, 28, 28)];
        seleBackView.image = [UIImage imageNamed:@"RNPhotoPicker.bundle/photo_picker_back"];
        self.seleBackView = seleBackView;
        [self.contentView addSubview:seleBackView];
        
        UIImageView *seleView = [[UIImageView alloc] initWithFrame:CGRectMake(3, 3, 22, 22)];
        seleView.image = [UIImage imageNamed:@"RNPhotoPicker.bundle/photo_picker_selected"];
        [seleBackView addSubview:seleView];
        self.seleView = seleView;
        seleView.hidden = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.iconView.frame = self.contentView.bounds;
    self.seleBackView.frame = CGRectMake(self.iconView.frame.size.width - 33, self.iconView.frame.size.height - 33, 28, 28);
}

- (void)setPhotoModel:(RNPhotoModel *)model {
    _photoModel = model;
    self.iconView.image = model.thumbImage;
    self.seleView.hidden = !_photoModel.isChoosed;
}

@end
