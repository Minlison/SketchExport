//
//  SketchExportTool.h
//  SketchExport
//
//  Created by MinLison on 2016/10/24.
//  Copyright © 2016年 com.ichengzivrqianiu.orgz. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SketchExportToolContext;
/**
 *  进度回调功能暂时没有写
 *
 *  @param context 上下文
 */
typedef void(^ProgressCallBackBlock)(SketchExportToolContext *context);
/**
 *  完成回调
 *
 *  @param context 上下文，无论成功失败，都不会为空
 *  @param error   如果成功，为空
 */
typedef void(^CompletionCallBackBlock)(SketchExportToolContext *context, NSError *error);


// 可扩展接口
@interface SketchExportToolContext : NSObject

/**
 *  sketch 文件路径
 */
@property ( copy, nonatomic ) NSString *sketchFilePath;
/**
 *  到处文件路径
 */
@property ( copy, nonatomic ) NSString *targetPath;
/**
 *  当前输出的图片名
 */
@property (copy, nonatomic, readonly) NSString *currentOutPutImage;
/**
 *  进度回调
 */
@property (copy, nonatomic, readonly) ProgressCallBackBlock progressBlock;
/**
 *  完成回调
 */
@property (copy, nonatomic, readonly) CompletionCallBackBlock completionBlock;
- (void)setProgressCallBack:(ProgressCallBackBlock)progress;
- (void)setCompletionCallBack:(CompletionCallBackBlock)completion;

/**
 *  快速创建context
 *
 *  @param sketchPath sketch文件路径
 *  @param targetPath 输出文件路径
 *  @param progress   进度回调
 *  @param completion 完成回调
 *
 *  @return context
 */
+ (instancetype)sketchToolContextSketchFilePath:(NSString *)sketchPath targetPath:(NSString *)targetPath progress:(ProgressCallBackBlock)progress completion:(CompletionCallBackBlock)completion;

/**
 *  命令行,到处内容
 *  不能同时添加多个,只能有一个
 *
 *  @param command 例如：export
 *  @param type     例如：artboards
 */
- (void)setUpCommand:(NSString *)command type:(NSString *)type;

/**
 *  命令行附加参数
 *
 *  @param command 例如 -o
 *  @param arg     参数 <path>
 */
- (void)addCommand:(NSString *)command arg:(NSString *)arg;

@end




@interface SketchExportTool : NSObject
/**
 *  快速创建工具，不是单例
 */
+ (instancetype)exportTool;

- (void)exportImagesFromContext:(SketchExportToolContext *)context;

@end
