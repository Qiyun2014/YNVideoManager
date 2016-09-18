//
//  IDYCameraDeviceManager.m
//  DYZB
//
//  Created by qiyun on 16/9/12.
//  Copyright © 2016年 mydouyu. All rights reserved.
//

#import "IDYCameraDeviceManager.h"
#import "DYUImageNamesDefine.h"

#if __has_include(<GPUImage/GPUImage.h>)
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *filterView;
#endif


@implementation IDYCameraDeviceManager


+ (void)cameraDemind:(void (^)(void))available unavailable:(void (^)(void))unavailable{
    
    NSString * mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus  authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if (authorizationStatus == AVAuthorizationStatusRestricted || authorizationStatus == AVAuthorizationStatusDenied) {
        
        DYLog(@"摄像头访问受限");
        if (unavailable) unavailable();
        
    }else if (available) available();
}


+ (AVCaptureSession *)configureCaptureSession:(AVCaptureSession *)session{
    
    /* 配置摄像机参数 */
    session = [[AVCaptureSession alloc] init];
    if ([session canSetSessionPreset:AVCaptureSessionPreset1280x720]) session.sessionPreset = AVCaptureSessionPreset1280x720;
    
    return session;
}


+ (AVCaptureMovieFileOutput *)capitalOutputWithSession:(AVCaptureSession *)session addToSuperView:(UIView *)view{
    
    AVCaptureMovieFileOutput *videoOutput = [[AVCaptureMovieFileOutput alloc] init];
    videoOutput.movieFragmentInterval = kCMTimeInvalid;
    
    if (!session) {
        
        /* 配置摄像机参数 */
        session = [[AVCaptureSession alloc] init];
        if ([session canSetSessionPreset:AVCaptureSessionPreset1280x720]) session.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    
    /* 获取设备（麦克风，摄像头等） */
    AVCaptureDevice *device;    /* ios9之后，次对象不支持实例化，只做对象申请地址空间，不做引用 */
    AVCaptureStillImageOutput *imageOutput = [[AVCaptureStillImageOutput alloc] init];
    
    NSArray *devices = [AVCaptureDevice devices];
    
    /* 媒体类型 */
    NSArray *audioCaptureDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    
    /* 视频输出类型实例化 */
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice.firstObject error:nil];
    
    for (AVCaptureDevice *aDevice in devices){
        
        if (aDevice.position == AVCaptureDevicePositionBack) {
            device = aDevice;
        }
    }
    
    /* 格式输出实例对象 */
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if (!videoInput) return nil;
    
    [session addInput:videoInput];
    [session addInput:audioInput];
    [session addOutput:imageOutput];    /* save images */
    [session addOutput:videoOutput];
    
    /* 预览显示 */
    AVCaptureVideoPreviewLayer *videoPlayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    videoPlayer.frame = view.bounds;
    videoPlayer.videoGravity = AVLayerVideoGravityResizeAspectFill; /* 视频边界 */
    [view.layer addSublayer:videoPlayer];
    
    [session startRunning];
    
    return videoOutput;
}

+ (AVPlayerViewController *)moviewPlayerWithFilePath:(NSString *)filePath
                                            observer:(id)observer periodicTimeObserver:(id)timeObserver
                                          usingBlock:(void (^)(CMTime time))time
                                   playerDidReachEnd:(SEL)sel{
    
    AVPlayerViewController *moviePlayer = [[AVPlayerViewController alloc] init];
    moviePlayer.showsPlaybackControls = NO;
    moviePlayer.view.backgroundColor = [UIColor whiteColor];
    moviePlayer.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:filePath]];
    [moviePlayer.player play];
    
    /* 添加播放完成的行为 */
    moviePlayer.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    /* 观察播放器进度 */
    timeObserver = [moviePlayer.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:time];
    
    /* 监听播放完成的事件 */
    [[NSNotificationCenter defaultCenter] addObserver:observer
                                             selector:sel
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[moviePlayer.player currentItem]];
    return moviePlayer;
}


+ (void)exportVideoFromUrl:(NSURL *)url exportVideoOfPath:(NSString *)exportPath completeHanlder:(void (^) (void))complete{
    
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    if ([compatiblePresets containsObject:AVAssetExportPresetLowQuality])
    {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetPassthrough];
        
        [[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
        
        /* 导入文件路径必须是一个空的文件 */
        exportSession.outputURL = [NSURL fileURLWithPath:exportPath];
        exportSession.outputFileType = AVFileTypeMPEG4;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            
            switch ([exportSession status]) {
                    
                case AVAssetExportSessionStatusFailed:
                    DYLog(@"~~~~~~~~~~~~ Export failed: %@", [[exportSession error] localizedDescription]);
                    break;
                    
                case AVAssetExportSessionStatusCancelled:
                    DYLog(@"~~~~~~~~~~~~ Export canceled");
                    break;
                    
                case AVAssetExportSessionStatusCompleted:
                {
                    DYLog(@"~~~~~~~~~~~~ 保存成功");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        if (complete) complete();
                    });
                }
                    break;
                    
                default:
                    break;
            }
        }];
    }
}

+ (void)swapFrontAndBackCamerasWithCaptureSession:(AVCaptureSession *)session{
    
    // Assume the session is already running
    NSArray *inputs = session.inputs;
    
    for ( AVCaptureDeviceInput *input in inputs ) {
        
        AVCaptureDevice *device = input.device;
        
        if ( [device hasMediaType:AVMediaTypeVideo] ) {
            
            AVCaptureDevicePosition position = device.position;
            AVCaptureDevice *newCamera = nil;
            AVCaptureDeviceInput *newInput = nil;
            
            if (position == AVCaptureDevicePositionFront)
                newCamera = [IDYCameraDeviceManager cameraWithPosition:AVCaptureDevicePositionBack];
            else
                newCamera = [IDYCameraDeviceManager cameraWithPosition:AVCaptureDevicePositionFront];
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            
            // beginConfiguration ensures that pending changes are not applied immediately
            [session beginConfiguration];
            [session removeInput:input];
            [session addInput:newInput];
            
            // Changes take effect once the outermost commitConfiguration is invoked.
            [session commitConfiguration];
            break;
        }
    }
}


+ (void)openFlashlight
{
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    
    if (captureDeviceClass != nil) {
        
        AVCaptureDevice *device;
        NSArray *devices = [AVCaptureDevice devices];
        
        /* 获取当前设备摄像头位置 */
        for (AVCaptureDevice *aDevice in devices){
            
            /* || (aDevice.position == AVCaptureDevicePositionFront) */
            if (aDevice.position == AVCaptureDevicePositionBack ) {
                
                device = aDevice;
                
                if ([device hasTorch] && [device hasFlash]){
                    
                    [device lockForConfiguration:nil];
                    
                    if (device.torchMode == AVCaptureTorchModeOn) {
                        
                        [device setTorchMode:AVCaptureTorchModeOff];
                        [device setFlashMode:AVCaptureFlashModeOff];
                    }else{
                        
                        [device setTorchMode:AVCaptureTorchModeOn];
                        [device setFlashMode:AVCaptureFlashModeOn];
                    }
                    
                    [device unlockForConfiguration];
                }
            }
        }
    }
}


+ (NSString *)createFile{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *testDirectory = [documentsDirectory stringByAppendingPathComponent:@"test"];
    
    //创建目录
    [fileManager createDirectoryAtPath:testDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    return testDirectory;
}


+ (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position )
            return device;
    return nil;
}


#pragma mark    -   use <Photos/Photos.h>


#if __has_include( <Photos/Photos.h> )
+ (void)getLastImageFromPhotosWithHanlder:(void (^) (UIImage *img))complete NS_AVAILABLE(10_10, 8_0){
    
    PHAsset *asset = nil;
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
    if (fetchResult != nil && fetchResult.count > 0) {
        // get last photo from Photos
        asset = [fetchResult lastObject];
    }
    
    if (asset) {
        // get photo info from this asset
        PHImageRequestOptions * imageRequestOptions = [[PHImageRequestOptions alloc] init];
        imageRequestOptions.synchronous = YES;
        [[PHImageManager defaultManager]
         requestImageDataForAsset:asset
         options:imageRequestOptions
         resultHandler:^(NSData *imageData, NSString *dataUTI,
                         UIImageOrientation orientation,
                         NSDictionary *info)
         {
             //NSLog(@"info = %@", info);
             if ([info objectForKey:@"PHImageFileURLKey"]) {
                 // path looks like this -
                 // file:///var/mobile/Media/DCIM/###APPLE/IMG_####.JPG
                 //NSURL *path = [info objectForKey:@"PHImageFileURLKey"];
                 
                 if (complete) complete([UIImage imageWithData:imageData]);
             }
         }];
    }
}


+ (void)getAllVideoFromPhotosWithHanlder:(void (^) (AVAsset *asset))complete NS_AVAILABLE(10_10, 8_0){
    
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    
    /* 根据视频创建日期进行遍历 */
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeVideo options:fetchOptions];
    
    /* 遍历所有的视频文件，将其转为asset格式进行输出 */
    [fetchResult enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        PHVideoRequestOptions *requestOption = [[PHVideoRequestOptions alloc] init];
        /* 是否为编辑的视频版本,如果编辑过，即为编辑后的版本 */
        requestOption.version = PHVideoRequestOptionsVersionCurrent;
        /* 不管花费多长时间，提供高质量图像 */
        requestOption.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
        
        /* Everything else. The result handler is called on an arbitrary queue. */
        [[PHImageManager defaultManager] requestAVAssetForVideo:obj
                                                        options:requestOption
                                                  resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                                                      
                                                      if (complete) complete(asset);
                                                  }];
    }];
}


+ (void)videoSaveOfPath:(NSString *)path photoAlbumHanlder:(void (^) (BOOL success, NSError *error))complete NS_AVAILABLE(10_10, 8_0){
    
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary;
    
    /* 通过PHAssetCollection的以下方法来获取指定的相册  countOfAssetsWithMediaType: 可用于获取当前媒体的个数 */
    PHFetchResult *fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                                                  subtype:PHAssetCollectionSubtypeAlbumRegular
                                                                                  options:fetchOptions];
    
    dispatch_block_t aBlock = ^{
        
        NSURL *localFileUrl = [NSURL fileURLWithPath:path];
        
        /* changeRequest 主要用于作为创建一个视频，PHAssetCollectionChangeRequest 可用来进行编辑视频 */
        PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:localFileUrl];
        
        if (fetchResult.firstObject != nil) {
            
            PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:fetchResult.firstObject];
            [assetCollectionChangeRequest addAssets:@[[assetChangeRequest placeholderForCreatedAsset]]];
        }
    };

    /* handlers are invoked on an arbitrary serial queue */
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:aBlock completionHandler:^(BOOL success, NSError *error) {
        
        if (complete) complete(success, error);
    }];
}

+ (void)makeAlbumWithTitle:(NSString *)title onSuccess:(void(^)(NSString *placeIdentifier))onSuccess onError:(void(^)(NSError * error))onError{
    
    //Check weather the album already exist or not
    if (![IDYCameraDeviceManager existsAtAblumName:title]) {
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            // Request editing the album.
            PHAssetCollectionChangeRequest *createAlbumRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title];
            
            // Get a placeholder for the new asset and add it to the album editing request.
            PHObjectPlaceholder * placeHolder = [createAlbumRequest placeholderForCreatedAssetCollection];
            if (placeHolder) {
                onSuccess(placeHolder.localIdentifier);
            }
            
        } completionHandler:^(BOOL success, NSError *error) {
            
            if (error)  onError(error);
        }];
    }
}

+ (void)addNewAssetWithImage:(UIImage *)image orNewAssetWithVideoUrl:(NSURL *)url toAlbum:(PHAssetCollection *)album onSuccess:(void(^)(NSString *placeIdentifier))onSuccess onError: (void(^)(NSError * error)) onError{
    
    if (!image && !url.path) return;
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        
        // Request creating an asset from the image.
        PHAssetChangeRequest *createAssetRequest;
        
        if (image) createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        else createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
        
        // Request editing the album.
        PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:album];
        
        // Get a placeholder for the new asset and add it to the album editing request.
        PHObjectPlaceholder * placeHolder = [createAssetRequest placeholderForCreatedAsset];
        [albumChangeRequest addAssets:@[ placeHolder ]];
        
        if (placeHolder) {
            onSuccess(placeHolder.localIdentifier);
        }
        
    } completionHandler:^(BOOL success, NSError *error) {

        if (error) onError(error);
    }];
}

/* 判断相册名是否已经存在 */
+ (PHAssetCollection *)existsAtAblumName:(NSString *)AlbumName{
    
    PHFetchResult *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                                               subtype:PHAssetCollectionSubtypeAlbumRegular
                                                                               options:nil];
    if (assetCollections.count == 0) return nil;
    
    __block PHAssetCollection * myAlbum;
    [assetCollections enumerateObjectsUsingBlock:^(PHAssetCollection *album, NSUInteger idx, BOOL *stop) {

        if ([album.localizedTitle isEqualToString:AlbumName]) {
            myAlbum = album;
            *stop = YES;
        }
    }];
    
    if (!myAlbum) return nil;
    return myAlbum;
}
#endif




#if __has_include(<GPUImage/GPUImage.h>)
- (GPUImageVideoCamera *)videoCamera{
    
    if (!_videoCamera) {
        
        _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionFront];
        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
        self.filterView = [[GPUImageView alloc] initWithFrame:self.view.frame];
        self.filterView.center = self.view.center;
        
        [self.avMoviePlayer.view addSubview:self.filterView];
        [_videoCamera addTarget:self.filterView];
        [_videoCamera startCameraCapture];
    }
    return _videoCamera;
}

- (void)cameraFilterWithOpen:(BOOL)open{
    
    [self.videoCamera removeAllTargets];
    
    if (!open) {
        
        [self.videoCamera addTarget:self.filterView];
        
    }else{
        
        DYGPUImageBeautifullyFilter *beautifyFilter = [[DYGPUImageBeautifullyFilter alloc] init];
        [self.videoCamera addTarget:beautifyFilter];
        [beautifyFilter addTarget:self.filterView];
    }
}
#endif

@end








#pragma mark    -   GPUImage filter group

#if __has_include(<GPUImage/GPUImage.h>)
// Internal CombinationFilter(It should not be used outside)
@interface GPUImageCombinationFilter : GPUImageThreeInputFilter
{
    GLint smoothDegreeUniform;
}

@property (nonatomic, assign) CGFloat intensity;

@end

NSString *const kGPUImageBeautifyFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 varying highp vec2 textureCoordinate3;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform sampler2D inputImageTexture3;
 uniform mediump float smoothDegree;
 
 void main()
 {
     highp vec4 bilateral = texture2D(inputImageTexture, textureCoordinate);
     highp vec4 canny = texture2D(inputImageTexture2, textureCoordinate2);
     highp vec4 origin = texture2D(inputImageTexture3,textureCoordinate3);
     highp vec4 smooth;
     lowp float r = origin.r;
     lowp float g = origin.g;
     lowp float b = origin.b;
     if (canny.r < 0.2 && r > 0.3725 && g > 0.1568 && b > 0.0784 && r > b && (max(max(r, g), b) - min(min(r, g), b)) > 0.0588 && abs(r-g) > 0.0588) {
         smooth = (1.0 - smoothDegree) * (origin - bilateral) + bilateral;
     }
     else {
         smooth = origin;
     }
     smooth.r = log(1.0 + 0.2 * smooth.r)/log(1.2);
     smooth.g = log(1.0 + 0.2 * smooth.g)/log(1.2);
     smooth.b = log(1.0 + 0.2 * smooth.b)/log(1.2);
     gl_FragColor = smooth;
 }
 );

@implementation GPUImageCombinationFilter

- (id)init {
    if (self = [super initWithFragmentShaderFromString:kGPUImageBeautifyFragmentShaderString]) {
        smoothDegreeUniform = [filterProgram uniformIndex:@"smoothDegree"];
    }
    self.intensity = 0.5;
    return self;
}

- (void)setIntensity:(CGFloat)intensity {
    _intensity = intensity;
    [self setFloat:intensity forUniform:smoothDegreeUniform program:filterProgram];
}

@end

@implementation DYGPUImageBeautifullyFilter

- (id)init;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    // First pass: face smoothing filter
    bilateralFilter = [[GPUImageBilateralFilter alloc] init];
    bilateralFilter.distanceNormalizationFactor = 4.0;
    [self addFilter:bilateralFilter];
    
    // Second pass: edge detection
    cannyEdgeFilter = [[GPUImageCannyEdgeDetectionFilter alloc] init];
    [self addFilter:cannyEdgeFilter];
    
    // Third pass: combination bilateral, edge detection and origin
    combinationFilter = [[GPUImageCombinationFilter alloc] init];
    [self addFilter:combinationFilter];
    
    // Adjust HSB
    hsbFilter = [[GPUImageHSBFilter alloc] init];
    [hsbFilter adjustBrightness:1.1];
    [hsbFilter adjustSaturation:1.1];
    
    [bilateralFilter addTarget:combinationFilter];
    [cannyEdgeFilter addTarget:combinationFilter];
    
    [combinationFilter addTarget:hsbFilter];
    
    self.initialFilters = [NSArray arrayWithObjects:bilateralFilter,cannyEdgeFilter,combinationFilter,nil];
    self.terminalFilter = hsbFilter;
    
    return self;
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in self.initialFilters)
    {
        if (currentFilter != self.inputFilterToIgnoreForUpdates)
        {
            if (currentFilter == combinationFilter) {
                textureIndex = 2;
            }
            [currentFilter newFrameReadyAtTime:frameTime atIndex:textureIndex];
        }
    }
}

- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in self.initialFilters)
    {
        if (currentFilter == combinationFilter) {
            textureIndex = 2;
        }
        [currentFilter setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
    }
}


@end

#endif
