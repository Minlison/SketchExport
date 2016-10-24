//
//  SketchExportTool.m
//  SketchExport
//
//  Created by MinLison on 2016/10/24.
//  Copyright © 2016年 com.ichengzivrqianiu.orgz. All rights reserved.
//

#import "SketchExportTool.h"
@interface SketchExportToolContext()
@property (copy, nonatomic, readwrite) ProgressCallBackBlock progressBlock;
@property (copy, nonatomic, readwrite) CompletionCallBackBlock completionBlock;
@property (copy, nonatomic, readwrite) NSString *currentOutPutImage;
@property (strong, nonatomic) NSMutableArray *command;
@property (strong, nonatomic) NSMutableArray *commandArgs;
@property (assign, nonatomic) BOOL commandReady;
@end

@implementation SketchExportToolContext
+ (instancetype)sketchToolContextSketchFilePath:(NSString *)sketchPath targetPath:(NSString *)targetPath progress:(ProgressCallBackBlock)progress completion:(CompletionCallBackBlock)completion
{
	SketchExportToolContext *context = [[SketchExportToolContext alloc] init];
	context.sketchFilePath = sketchPath;
	context.targetPath = targetPath;
	context.progressBlock = progress;
	context.completionBlock = completion;
	return context;
}

- (NSArray *)getExportCommand
{
	if (!self.targetPath || !self.sketchFilePath)
	{
		return nil;
	}
	[self.command addObjectsFromArray:self.commandArgs];
	return self.command;
	
}
- (void)setProgressCallBack:(ProgressCallBackBlock)progress
{
	self.progressBlock = progress;
}
- (void)setCompletionCallBack:(CompletionCallBackBlock)completion
{
	self.completionBlock = completion;
}
- (void)setUpCommand:(NSString *)command type:(NSString *)type
{
	NSAssert((command != nil || type != nil), @"命令行和类型不能为空");
	if (self.commandReady)
	{
		return;
	}
	[self.command insertObject:command atIndex:0];
	[self.command insertObject:type atIndex:1];
	[self.command insertObject:self.sketchFilePath atIndex:2];
	self.commandReady = YES;
}
- (void)addCommand:(NSString *)command arg:(NSString *)arg
{
	NSAssert((command != nil || arg != nil), @"命令行和参数不能为空");
	[self.commandArgs addObject:[NSString stringWithFormat:@"%@=%@",command,arg]];

}
- (NSMutableArray *)command
{
	if (!_command)
	{
		_command = [[NSMutableArray alloc] init];
	}
	return _command;
}
- (NSMutableArray *)commandArgs
{
	if (_commandArgs == nil) {
		_commandArgs = [[NSMutableArray alloc] init];
	}
	return _commandArgs;
}

@end

@interface SketchExportTool()
@property (strong, nonatomic) NSTask *unixTask;
@property ( strong, nonatomic ) NSPipe *unixStandardOutputPipe;
@property ( strong, nonatomic ) NSPipe *unixStandardErrorPipe;
@property ( strong, nonatomic ) NSPipe *unixStandardInputPipe;
@property ( strong, nonatomic ) NSFileHandle *fhOutput;
@property ( strong, nonatomic ) NSFileHandle *fhError;
@property ( copy, nonatomic ) NSString *errorDes;
@property (strong, nonatomic) SketchExportToolContext *context;
@end

@implementation SketchExportTool

+ (instancetype)exportTool
{
	return [[self alloc] init];
}

- (void)exportImagesFromContext:(SketchExportToolContext *)context;
{
	
	NSAssert((context.sketchFilePath != nil || context.targetPath != nil), @"源文件，目标路径,导出命令不能为空");
	NSAssert(context.commandReady, @"未设置命令行");
	
	if (self.unixTask != nil && [self.unixTask isRunning])
	{
		return;
	}
	
	self.unixTask = [[NSTask alloc] init];
	self.context = context;
	
	NSPipe * unixStandardOutputPipe = [[NSPipe alloc] init];
	NSPipe * unixStandardErrorPipe = [[NSPipe alloc] init];
	self.unixStandardOutputPipe = unixStandardOutputPipe;
	self.unixStandardErrorPipe = unixStandardErrorPipe;
	
	NSFileHandle *fhOutput = [unixStandardOutputPipe fileHandleForReading];
	NSFileHandle *fhError = [unixStandardErrorPipe fileHandleForReading];
	self.fhOutput = fhOutput;
	self.fhError = fhError;
	
	//setup notification alerts
	NSNotificationCenter *notiCenter = [NSNotificationCenter defaultCenter];
	
	[notiCenter addObserver:self selector:@selector(notifiedForOutput:) name:NSFileHandleReadCompletionNotification object:fhOutput];
	[notiCenter addObserver:self selector:@selector(notifiedForOutput:) name:NSFileHandleReadCompletionNotification object:fhError];
	[notiCenter addObserver:self selector:@selector(notifiedForComplete:) name:NSTaskDidTerminateNotification object:self.unixTask];
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"sketchtool" ofType:nil inDirectory:@"bin"];
	
	if (path == nil)
	{
		return;
	}
	NSArray *exportCommand = [self.context getExportCommand];
	if (!exportCommand)
	{
		return;
	}
	[self.unixTask setLaunchPath:path];
	[self.unixTask setArguments:exportCommand];
	[self.unixTask setStandardOutput:unixStandardOutputPipe];
	[self.unixTask setStandardError:unixStandardErrorPipe];
	[self.unixTask setStandardInput:[NSPipe pipe]];
	@try {
		[self.unixTask launch];
	} @catch (NSException *exception) {
		NSLog(@"%@",exception);
	} @finally {
		
	}
	
	
	[fhOutput readInBackgroundAndNotify];
	[fhError readInBackgroundAndNotify];
}

- (void)notifiedForOutput: (NSNotification *)notified
{
	
	if (notified.object == self.fhOutput)
	{
		NSData * data = [[notified userInfo] valueForKey:NSFileHandleNotificationDataItem];
		
		if ([data length])
		{
			NSString * outputString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			self.context.currentOutPutImage = [outputString stringByReplacingOccurrencesOfString:@"Exported " withString:@""];
			if (self.context.progressBlock)
			{
				self.context.progressBlock(self.context);
			}
		}
		
		if (self.unixTask != nil && [self.unixTask isRunning])
		{
			[self.fhOutput readInBackgroundAndNotify];
			[self.fhError readInBackgroundAndNotify];
		}
	}
	else
	{
		NSData * data = [[notified userInfo] valueForKey:NSFileHandleNotificationDataItem];
		
		if ([data length])
		{
			self.errorDes = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		}
	}
}

- (void)notifiedForComplete:(NSNotification *)anotification
{
	
	NSTask *task = anotification.object;
	
	NSLog(@"%@ %@ task completed or was stopped with exit code %d", self.context.targetPath, task,[task terminationStatus]);
	
	
	if ([task terminationStatus] == 0 )
	{
		if (self.context.completionBlock && anotification.object == self.unixTask)
		{
			self.context.completionBlock(self.context,nil);
		}
		
	}
	else if ([task terminationStatus] != 0)
	{
		
		NSError *error = nil;
		if (self.errorDes != nil)
		{
			error = [NSError errorWithDomain:@"SketchExportToolError" code:[task terminationStatus] userInfo:@{
															   NSLocalizedDescriptionKey : self.errorDes
															   }];
			
		}
		else
		{
			error = [NSError errorWithDomain:@"SketchExportToolError" code:[task terminationStatus] userInfo:@{
															   NSLocalizedDescriptionKey : @"未知错误"
															   }];
		}
		if (self.context.completionBlock && anotification.object == self.unixTask)
		{
			self.context.completionBlock(self.context,error);
		}
	}
}
@end
