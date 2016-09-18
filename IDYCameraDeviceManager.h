//
//  IDYCameraDeviceManager.h
//  DYZB
//
//  Created by qiyun on 16/9/12.
//  Copyright © 2016年 mydouyu. All rights reserved.
//
//  @brief  ----> 主要用于相机硬件设备的常见操作，以及ios8之后本地相册视频或照片的读取或创建  <-----


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVPlayerViewController.h>
#import <AVFoundation/AVFoundation.h>

#if __has_include(<GPUImage/GPUImage.h>)
#import <GPUImage/GPUImage.h>
#endif

#if __has_include( <Photos/Photos.h> )
#import <Photos/Photos.h>
#endif

@interface IDYCameraDeviceManager : NSObject

/**!
 *   判断当前相机的全新
 */
+ (void)cameraDemind:(void (^)(void))available unavailable:(void (^)(void))unavailable;


/**!
 *   配置摄像头，像素和画质等
 */
+ (AVCaptureSession *)configureCaptureSession:(AVCaptureSession *)session;


/**!
 *   写入和捕获媒体QuickTime的一个具象类，也是AVCaptureFileOutput的子类
 *
 *   @discussion (AVCaptureMovieFileOutput is a concrete subclass of AVCaptureFileOutput that writes captured media to QuickTime movie files)
 *   @brief 
 *       view:添加到此对象上，进行预览
 */
+ (AVCaptureMovieFileOutput *)capitalOutputWithSession:(AVCaptureSession *)session addToSuperView:(UIView *)view;


/**!
 *   AVPlayer播放器
 *
 *   @discussion (The player from which to source the media content for the view controller)
 *   @brief  
 *       filePath:播放地址；
 *       observer：观察者，用于观察播放进度；
 *       time：进度；
 *       sel：播放完成后
 */
+ (AVPlayerViewController *)moviewPlayerWithFilePath:(NSString *)filePath
                                            observer:(id)observer
                                periodicTimeObserver:(id)timeObserver
                                          usingBlock:(void (^)(CMTime time))time playerDidReachEnd:(SEL)sel;


/**!
 *   从视频地址捕捉Asset对象，将其转为可播放的mp4格式文件到处到指定位置
 *
 *   @brief
 *      url：视频存放位置
 *      exportPath：导出视频存放地址
 *      complete：导出完成后的回执
 */
+ (void)exportVideoFromUrl:(NSURL *)url exportVideoOfPath:(NSString *)exportPath completeHanlder:(void (^) (void))complete;


/**!
 *   前后摄像头更换
 */
+ (void)swapFrontAndBackCamerasWithCaptureSession:(AVCaptureSession *)session;


/**!
 *   开启背面闪光灯
 */
+ (void)openFlashlight;


/**!
 *   创建一个临时文件，用于存储写出的临时视频
 */
+ (NSString *)createFile;



#pragma mark    -   use <Photos/Photos.h>


/**!
 *   获取相册中，最近的一张图片
 */
+ (void)getLastImageFromPhotosWithHanlder:(void (^) (UIImage *img))complete NS_AVAILABLE(10_10, 8_0);




/**!
 *   获取相册中，所有的视频，一段一段地进行输出
 */
+ (void)getAllVideoFromPhotosWithHanlder:(void (^) (AVAsset *asset))complete NS_AVAILABLE(10_10, 8_0);




/**!
 *   从视频路径地址path读取视频数据，保存到系统默认相册
 *   当前使用后的是默认相册文件，并没有制定相册名称
 *
 *   @example                         
 *   [IDYCameraDeviceManager videoSaveOfPath:exportPath photoAblumHanlder:^(BOOL success, NSError *error) {
 
           NSLog(@"success = %@, error = %@",success?@"yes":@"no",[error description]);
      }];
 */
+ (void)videoSaveOfPath:(NSString *)path photoAlbumHanlder:(void (^) (BOOL success, NSError *error))complete NS_AVAILABLE(10_10, 8_0);




/**!
 *   创建一个相册文件夹
 *
 *   @param 
 *       title:文件夹名称
 *       onSuccess：成功后返回的文件夹identifier
 *       onError：创建失败
 */
+ (void)makeAlbumWithTitle:(NSString *)title onSuccess:(void(^)(NSString *placeIdentifier))onSuccess onError:(void(^)(NSError * error))onError;




/**!
 *   添加一个新的图片或者视频到系统相册，默认上传图片，没有图片则上传视频
 *
 *   @param
 *       image:图片
 *       url：视频地址
 *       album：相册对象
 *       onSuccess：添加成功后返回的文件夹identifier
 *       onError：创建失败
 */
+ (void)addNewAssetWithImage:(UIImage *)image orNewAssetWithVideoUrl:(NSURL *)url toAlbum:(PHAssetCollection *)album onSuccess:(void(^)(NSString *placeIdentifier))onSuccess onError: (void(^)(NSError * error)) onError;




/**!
 *   判断相册名称是否已经存在，不存在则创建一个
 */
+ (PHAssetCollection *)existsAtAblumName:(NSString *)AlbumName;

@end


#if __has_include(<GPUImage/GPUImage.h>)
@class GPUImageCombinationFilter;
@interface DYGPUImageBeautifullyFilter : GPUImageFilterGroup{
    
    GPUImageBilateralFilter *bilateralFilter;
    GPUImageCannyEdgeDetectionFilter *cannyEdgeFilter;
    GPUImageCombinationFilter *combinationFilter;
    GPUImageHSBFilter *hsbFilter;
}

@end
#endif

