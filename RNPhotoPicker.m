//
//  DYBPhotoSelectionView.m
//  testAssetsLibrary
//
//  Created by nantu on 15/12/16.
//  Copyright © 2015年 nantu. All rights reserved.
//

#import "RNPhotoPicker.h"
#import "RNPhotoPickerCell.h"
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "RNPhotoModel.h"

#define isIOS8earlier [[[UIDevice currentDevice] systemVersion] floatValue] <= 8.0
static NSString *const myBundleID = @"tv.douyu.testAssetsLibrary";

typedef enum {
    RNPickStateLoad = 1,
    RNPickStateAppear,
    RNPickStateAmplying,
    RNPickStateDown,
    RNPickStateUp,
    RNPickStateDisappear
} RNPickState;
static RNPickState _pickState;

@interface RNPhotoPicker()<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, weak) UIView *containerView;
@property (nonatomic, weak) UIView *upstairView;

@property (nonatomic, weak) UICollectionView *collectionView;

@property (nonatomic, strong) NSMutableArray *previewArray;
@property (nonatomic, strong) NSMutableArray *selectedModels;

@property (nonatomic, weak) UIButton *confirmBtn;
@property (nonatomic, weak) UIButton *libraryBtn;
@property (nonatomic, weak) UIButton *cancleBtn;
@property (nonatomic, weak) UIView *blackLine1;

@property (nonatomic, copy) manyPhotos manyPhotosBlock;
@property (nonatomic, copy) failure failureBlock;
@property (nonatomic, assign) int requirCount;

@end

@implementation RNPhotoPicker


static CGFloat _buttonHeight = 54.0;
static CGFloat _originalCollectionHeight = 128.0;
static CGFloat _amplifyingCollectionHeight = 188.0;
static CGFloat _picHeight = 128.0;

static CGSize _resultSize;

- (void)setTargetSize:(CGSize)targetSize {
    _targetSize = targetSize;
    _resultSize = _targetSize;
}

+ (instancetype)photoPicker {
    
    CGRect rect = [UIScreen mainScreen].bounds;
    
    // 覆盖屏幕的半透明背景
    RNPhotoPicker *backView = [[RNPhotoPicker alloc] initWithFrame:rect];
    backView.alpha = 0;
    backView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    
    // 选择器和按钮的容器
    UIView *containerView = [[UIView alloc] init];
    [backView addSubview:containerView];
    backView.containerView = containerView;
    containerView.backgroundColor = [UIColor clearColor];
    
    // 上半部分容器
    UIView *upstairView = [[UIView alloc] init];
    [containerView addSubview:upstairView];
    upstairView.backgroundColor = [UIColor whiteColor];
    backView.upstairView = upstairView;
    upstairView.layer.cornerRadius = 4.0;
    upstairView.clipsToBounds = YES;
    
    // 确认按钮
    UIButton *confirmBtn = [[UIButton alloc] init];
    confirmBtn.hidden = YES;
    confirmBtn.backgroundColor = [UIColor whiteColor];
    confirmBtn.titleLabel.font = [UIFont systemFontOfSize:20];
    [confirmBtn setTitle:@"确认" forState:UIControlStateNormal];
    [confirmBtn setTitleColor:[UIColor colorWithRed:75 / 255.0 green:75 / 255.0 blue:75 / 255.0 alpha:1.0] forState:UIControlStateNormal];
    [confirmBtn addTarget:backView action:@selector(confirm) forControlEvents:UIControlEventTouchUpInside];
    [upstairView addSubview:confirmBtn];
    UIView *blackLine1 = [[UIView alloc] init];
    backView.blackLine1 = blackLine1;
    blackLine1.backgroundColor = [UIColor colorWithRed:200 / 255.0 green:200 / 255.0 blue:200 / 255.0 alpha:1.0];
    [confirmBtn addSubview:blackLine1];
    backView.confirmBtn = confirmBtn;
    
    // 从图库选择按钮
    UIButton *libraryBtn = [[UIButton alloc] init];
    libraryBtn.backgroundColor = [UIColor whiteColor];
    libraryBtn.titleLabel.font = [UIFont systemFontOfSize:20];
    [libraryBtn setTitle:@"从相册选择" forState:UIControlStateNormal];
    [libraryBtn setTitleColor:[UIColor colorWithRed:75 / 255.0 green:75 / 255.0 blue:75 / 255.0 alpha:1.0] forState:UIControlStateNormal];
    [libraryBtn addTarget:backView action:@selector(selecteFromLibrary) forControlEvents:UIControlEventTouchUpInside];
    [upstairView addSubview:libraryBtn];
    backView.libraryBtn = libraryBtn;
    
    // 取消按钮
    UIButton *cancleBtn = [[UIButton alloc] init];
    cancleBtn.backgroundColor = [UIColor whiteColor];
    cancleBtn.layer.cornerRadius = 4.0;
    cancleBtn.clipsToBounds = YES;
    cancleBtn.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [cancleBtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancleBtn setTitleColor:[UIColor colorWithRed:75 / 255.0 green:75 / 255.0 blue:75 / 255.0 alpha:1.0] forState:UIControlStateNormal];
    [cancleBtn addTarget:backView action:@selector(cancle) forControlEvents:UIControlEventTouchUpInside];
    [containerView addSubview:cancleBtn];
    backView.cancleBtn = cancleBtn;
    
    // 快速选择的 collection view
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, containerView.frame.size.width, _originalCollectionHeight) collectionViewLayout:flowLayout];
    collectionView.backgroundColor = [UIColor whiteColor];
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.showsVerticalScrollIndicator = NO;
    collectionView.dataSource = backView;
    collectionView.delegate = backView;
    backView.collectionView = collectionView;
    [collectionView registerClass:[RNPhotoPickerCell class] forCellWithReuseIdentifier:@"CollectionImage"];
    [upstairView addSubview:collectionView];
    
    _pickState = RNPickStateLoad;
    _resultSize = CGSizeMake(1600, CGFLOAT_MAX);
    [backView adjustFrameCompletion:nil];
    
    return backView;
}

- (void)pickPhotoWithRequirCount:(int)requirCount ManyPhotos:(manyPhotos)manyPhotos failure:(failure)failure {
    
    _failureBlock = failure;
    _requirCount = requirCount;
    _manyPhotosBlock = manyPhotos;
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self];
    
    [self requestAuthorization];
}

- (void)requestAuthorization {
    
    if (isIOS8earlier) {
        [self selecteFromLibrary];
    } else {
        
        PHAuthorizationStatus author = [PHPhotoLibrary authorizationStatus];
        
        if (author != PHAuthorizationStatusAuthorized) {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    
                    // 出现时从屏幕下边弹出
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        if (isIOS8earlier) {
                            [self selecteFromLibrary];
                        } else {
                            [self adjustFrameCompletion:nil];
                            [self pickpuPhtos];
                        }
                    });
                } else {
                    // 提示
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        UIAlertView *authorAleat = [[UIAlertView alloc] initWithTitle:@"提示" message:@"您关闭了访问相册的权限，请到设置里打开。" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                        [authorAleat show];
                    });
                }
            }];
        } else {
            if (isIOS8earlier) {
                [self selecteFromLibrary];
            } else {
                [self adjustFrameCompletion:nil];
                [self pickpuPhtos];
            }
        }
        
    }
    
}

#pragma mark - 获取预览图集
- (void)pickpuPhtos {
    
    // 获取所有资源的集合，并按资源的创建时间排序
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
    
    CGSize requestSize = CGSizeMake((_thumbWidth == 0 ? [UIScreen mainScreen].bounds.size.width : _thumbWidth), MAXFLOAT);
    
    [self.previewArray removeAllObjects];
    
    // 预览图片数
    int limitCount = _previewCount ? _previewCount : 10;
    __block NSInteger i = assetsFetchResults.count - 1;
    NSInteger limit = assetsFetchResults.count > limitCount ? (i - limitCount) : 0;
    
    while (i >= 0 && i > limit && assetsFetchResults.count) {
        
        PHAsset *asset = assetsFetchResults[i];
        [self requestPhotoForAsset:asset targetSize:requestSize success:^(UIImage *image, NSDictionary *info) {
            __block RNPhotoModel *model = [[RNPhotoModel alloc] init];
            model.thumbImage = image;
            model.asset = asset;
            model.info = info;
            [self.previewArray addObject:model];
        }];
        i--;
    }
    
    [self.collectionView reloadData];
}

+ (void)requestBigImageWith:(NSArray *)models index:(NSInteger)index {
    
    __block NSInteger currentIndex = index;
    __block RNPhotoModel *model = models[currentIndex];
    // 异步请求大图
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    requestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
    requestOptions.synchronous = NO;
    requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    requestOptions.networkAccessAllowed = NO;
    PHImageManager *manager = [PHImageManager defaultManager];
    [manager requestImageForAsset:model.asset targetSize:_resultSize contentMode:PHImageContentModeAspectFit options:requestOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result != nil) {
            NSData *comData = UIImageJPEGRepresentation(result, 0.65);
            model.bigImage = [UIImage imageWithData:comData];
        }
        
        currentIndex ++;
        if (currentIndex < models.count) {
            [self requestBigImageWith:models index:currentIndex];
        }
    }];
}

// 获取选定的图片
- (void)requestPhotoForAsset:(PHAsset *)asset targetSize:(CGSize)targetSize success:(void (^)(UIImage *image, NSDictionary *info))success {
    
    CGSize photoSize = CGSizeMake(targetSize.width, targetSize.height);
    
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    requestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
    requestOptions.synchronous = YES;
    requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    requestOptions.networkAccessAllowed = NO;
    PHImageManager *manager = [PHImageManager defaultManager];
    [manager requestImageForAsset:asset targetSize:photoSize contentMode:PHImageContentModeAspectFit options:requestOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result != nil) {
            success(result, info);
        }
    }];
}

#pragma mark - touch event
- (void)confirm {
    
    if (self.selectedModels.count && _manyPhotosBlock) {
        NSMutableArray *images = [NSMutableArray array];
        
        for (int i = 0; i < self.selectedModels.count; i++) {
            
            RNPhotoModel *model = self.selectedModels[i];
            
            if (model.bigImage) {
                [images addObject:model.bigImage];
            } else {
                [self requestPhotoForAsset:model.asset targetSize:_resultSize success:^(UIImage *image, NSDictionary *info) {
                    [images addObject:image];
                }];
            }
            
        }
        _manyPhotosBlock(images);
    }
    [self cancle];
}

- (void)selecteFromLibrary {
    
    [self.selectedModels removeAllObjects];
    _pickState = RNPickStateDisappear;
    [self adjustFrameCompletion:nil];
    
    UIImagePickerController *pickVC = [[UIImagePickerController alloc] init];
    pickVC.delegate = self;
    pickVC.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    
    UIBarButtonItem *item = [UIBarButtonItem appearance];
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[NSForegroundColorAttributeName] = [UIColor blackColor];
    [item setTitleTextAttributes:md forState:UIControlStateNormal];
    
    // 获取当前控制器
    UIViewController *rootController = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *vc = [self lastViewController:rootController];
    while (vc.presentedViewController) {
        vc = vc.presentedViewController;
        vc = [self lastViewController:vc];
    }
    
    [vc presentViewController:pickVC animated:YES completion:nil];
}

- (UIViewController *)lastViewController:(UIViewController *)vc
{
    if ([vc isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tab = (UITabBarController *)vc;
        if ([tab.selectedViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nav = (UINavigationController *)tab.selectedViewController;
            return [nav.viewControllers lastObject];
        } else {
            return tab.selectedViewController;
        }
    } else if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)vc;
        return [nav.viewControllers lastObject];
    } else {
        return vc;
    }
    return nil;
}

- (void)cancle {
    
    _pickState = RNPickStateDisappear;
    [self adjustFrameCompletion:^{
        [self removeFromSuperview];
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self cancle];
}

#pragma mark - 调整 frame
- (void)adjustFrameCompletion:(void(^)())completion{
    
    CGRect rect = [UIScreen mainScreen].bounds;
    // load
    CGRect backRect = rect;
    
    CGFloat x = 10;
    CGFloat magin = 10;
    CGFloat width = rect.size.width - 2 * x;
    
    // confirm 隐藏
    CGFloat containerHeight = self.containerView.frame.size.height;
    CGFloat confirmY = self.confirmBtn.frame.origin.y;
    // load
    CGFloat containerY = self.containerView.frame.origin.y;
    
    if (_pickState != RNPickStateDisappear) {
        if (self.containerView.frame.origin.y == rect.size.height) {
            _pickState = RNPickStateAppear;
            _picHeight = _originalCollectionHeight;
            self.confirmBtn.hidden = YES;
            
            // appear
            containerY = rect.size.height - containerHeight - magin;
        }
        if (self.selectedModels.count) {
            _pickState = RNPickStateAmplying;
            _picHeight = _amplifyingCollectionHeight;
            containerHeight = (_buttonHeight * 3 + magin + _picHeight);
            confirmY = _picHeight;
            containerY = rect.size.height - containerHeight - magin;
            self.confirmBtn.hidden = NO;
        }
        if (!self.selectedModels.count && self.collectionView.frame.size.height == _amplifyingCollectionHeight) {
            _pickState = RNPickStateDown;
            _picHeight = _amplifyingCollectionHeight;
            containerHeight = (_buttonHeight * 2 + magin + _picHeight);
            confirmY = _picHeight - _buttonHeight;
            containerY = rect.size.height - containerHeight - magin;
            self.confirmBtn.hidden = YES;
        }
        if (self.selectedModels.count && self.collectionView.frame.size.height != _amplifyingCollectionHeight) {
            _pickState = RNPickStateUp;
            _pickState = RNPickStateAmplying; // up 和 amplying 的布局完全一样
            _picHeight = _amplifyingCollectionHeight;
            containerHeight = (_buttonHeight * 3 + magin + _picHeight);
            confirmY = _picHeight;
            containerY = rect.size.height - containerHeight - magin;
            self.confirmBtn.hidden = NO;
        }
    }
    
    switch (_pickState) {
        case RNPickStateLoad:
            _picHeight = _originalCollectionHeight;
            containerHeight = (_buttonHeight * 2 + magin + _picHeight);
            containerY = rect.size.height;
            confirmY = _picHeight - _buttonHeight;
            break;
            
        case RNPickStateDisappear:
            containerY = rect.size.height;
            backRect = CGRectMake(0, rect.size.height, backRect.size.width, backRect.size.height);
            break;
            
        default:
            break;
    }
    
    CGRect collectionRect = CGRectMake(0, 0, width, _picHeight);
    CGRect upstairRect = CGRectMake(x, 0, width, containerHeight - _buttonHeight - magin);
    CGRect containerRect = CGRectMake(0, containerY, rect.size.width, containerHeight);
    CGRect confirmRect = CGRectMake(0, confirmY, width, _buttonHeight);
    CGRect libraryRect = CGRectMake(0, confirmY + _buttonHeight, width, _buttonHeight);
    CGRect cancleRect = CGRectMake(x, confirmY + 2 * _buttonHeight + magin, width, _buttonHeight);
    
    self.blackLine1.frame = CGRectMake(0, _buttonHeight - 0.5, width, 0.5);
    
    if (_pickState == RNPickStateLoad) {
        self.frame = backRect;
        self.containerView.frame = containerRect;
        self.upstairView.frame = upstairRect;
        self.collectionView.frame = collectionRect;
        self.confirmBtn.frame = confirmRect;
        self.libraryBtn.frame = libraryRect;
        self.cancleBtn.frame = cancleRect;
    } else {
        [UIView animateWithDuration:0.15 animations:^{
            self.containerView.frame = containerRect;
            self.upstairView.frame = upstairRect;
            self.collectionView.frame = collectionRect;
            self.confirmBtn.frame = confirmRect;
            self.libraryBtn.frame = libraryRect;
            self.cancleBtn.frame = cancleRect;
            if (_pickState == RNPickStateDisappear) {
                self.alpha = 0;
            }
            if (_pickState == RNPickStateAppear) {
                self.alpha = 1;
            }
        } completion:^(BOOL finished) {
            self.frame = backRect;
            if (completion) {
                completion();
            }
        }];
    }
}

#pragma mark - collection view data source
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return self.previewArray.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    RNPhotoPickerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionImage" forIndexPath:indexPath];
    RNPhotoModel *model = self.previewArray[indexPath.item];
    cell.photoModel = model;
    
    return cell;
}

#pragma mark - collection view delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    __block RNPhotoModel *model =  self.previewArray[indexPath.item];
    
    if (self.selectedModels.count >= _requirCount && !model.isChoosed) {
        // 提示
        [self showError];
        return;
    }
    model.choose = !model.isChoosed;
    if (model.isChoosed) {
        [self.selectedModels addObject:model];
        
        if (model.bigImage == nil) {
            // 异步请求大图
            PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
            requestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
            requestOptions.synchronous = NO;
            requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
            requestOptions.networkAccessAllowed = NO;
            PHImageManager *manager = [PHImageManager defaultManager];
            [manager requestImageForAsset:model.asset targetSize:_resultSize contentMode:PHImageContentModeAspectFit options:requestOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                if (result != nil) {
                    NSData *comData = UIImageJPEGRepresentation(result, 0.65);
                    model.bigImage = [UIImage imageWithData:comData];
                }
            }];
        }
        
    } else {
        [self.selectedModels removeObject:model];
    }
    [self.confirmBtn setTitle:[NSString stringWithFormat:@"插入 %tu 张图片", self.selectedModels.count] forState:UIControlStateNormal];
    [self.collectionView reloadData];
    
    [self adjustFrameCompletion:nil];
    
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

#pragma mark - flow layout
//定义每个UICollectionView 的大小
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat smallPicHeight = _picHeight - 10;
    
    RNPhotoModel *model = self.previewArray[indexPath.item];
    UIImage *image = model.thumbImage;
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    
    CGFloat scale = imageHeight / smallPicHeight;
    CGFloat viewWidth = imageWidth / scale;
    
    NSLog(@"%@", NSStringFromCGSize(image.size));
    
    return CGSizeMake(viewWidth, smallPicHeight);
}
//定义每个UICollectionView 的间距
-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}
//定义每个UICollectionView 纵向的间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 5;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 5;
}

#pragma mark - image picker controller delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    UIImage *selectedImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    
    if (self.selectedModels.count >= _requirCount) {
        // 提示
        [self showError];
    } else if (_manyPhotosBlock && selectedImage) {
        NSArray *images = @[selectedImage];
        _manyPhotosBlock(images);
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self removeFromSuperview];
}

#pragma mark - alert view delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (!(isIOS8earlier) && buttonIndex == 0) {
        NSURL *settingURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:settingURL];
    }
}

#pragma mark - alert view delegate
- (void)alertViewCancel:(UIAlertView *)alertView {
    [self cancle];
}

#pragma mark - lazy
- (NSMutableArray *)previewArray {
    if (_previewArray == nil) {
        _previewArray = [NSMutableArray array];
    }
    return _previewArray;
}
- (NSMutableArray *)selectedModels {
    if (_selectedModels == nil) {
        _selectedModels = [NSMutableArray array];
    }
    return _selectedModels;
}

#pragma mark - error
- (void)showError {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"插入图片不可超过 20 张" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
    if (_failureBlock) {
        NSError *error = [[NSError alloc] initWithDomain:@"照片数超限" code:1 userInfo:nil];
        _failureBlock(error);
    }
    [alertView show];
}

@end
