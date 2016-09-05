//
//  assetModel.h
//  testAssetsLibrary
//
//  Created by nantu on 15/12/16.
//  Copyright © 2015年 nantu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@interface RNPhotoModel : NSObject

@property (nonatomic, strong) UIImage *thumbImage;
@property (nonatomic, strong) UIImage *bigImage;
@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, strong) NSDictionary *info;
@property (nonatomic, assign, getter=isChoosed) BOOL choose;

@end
