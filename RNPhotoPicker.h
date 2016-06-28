//
//  DYBPhotoSelectionView.h
//  testAssetsLibrary
//
//  Created by nantu on 15/12/16.
//  Copyright © 2015年 nantu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^manyPhotos) (NSArray *photos);
typedef void (^failure) (NSError *error);

@interface RNPhotoPicker : UIView

+ (instancetype)photoPicker;

// 预览图片数量，默认 10 张
@property (nonatomic, assign) int previewCount;

@property (nonatomic, assign) CGFloat thumbWidth;
// 目标图片大小（以px为单位，默认1600 x 1600）
@property (nonatomic, assign) CGSize targetSize;

- (void)pickPhotoWithRequirCount:(int)requirCount ManyPhotos:(manyPhotos)manyPhotos failure:(failure)failure;

@end
