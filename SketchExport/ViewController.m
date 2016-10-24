//
//  ViewController.m
//  SketchExport
//
//  Created by MinLison on 2016/10/24.
//  Copyright © 2016年 com.ichengzivrqianiu.orgz. All rights reserved.
//

#import "ViewController.h"
#import "SketchExportTool.h"
@interface ViewController()
@property (weak) IBOutlet NSTextField *sketchPath;
@property (weak) IBOutlet NSTextField *outputPath;
@property (strong, nonatomic) SketchExportTool *tool;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	// Do any additional setup after loading the view.
}
- (IBAction)export:(id)sender
{
	[self exportSketch];
}

- (IBAction)choseFile:(id)sender
{
	[self showPathOpenPanelCanChoseFiles:YES canChoseDir:YES allowMutipleSelection:NO directoryURL:nil contentTypes:nil completion:^(NSArray<NSURL *> *urls) {
		self.sketchPath.stringValue = urls.lastObject.path;
		NSLog(@"%@",urls.lastObject.path);
	}];
}
- (IBAction)choseOutPutPath:(id)sender
{
	[self showPathOpenPanelCanChoseFiles:YES canChoseDir:YES allowMutipleSelection:NO directoryURL:nil contentTypes:nil completion:^(NSArray<NSURL *> *urls) {
		self.outputPath.stringValue = urls.lastObject.path;
		NSLog(@"%@",urls.lastObject.path);
	}];
}

- (void)exportSketch
{
	if (self.sketchPath.stringValue.length <= 0 || self.outputPath.stringValue.length <= 0)
	{
		return;
	}
	
	SketchExportToolContext *context = [SketchExportToolContext sketchToolContextSketchFilePath:self.sketchPath.stringValue targetPath:self.outputPath.stringValue progress:^(SketchExportToolContext *context) {
		NSLog(@"%@",context.currentOutPutImage);
	} completion:^(SketchExportToolContext *context, NSError *error) {
		NSLog(@"%@",error);
	}];
	
	[context setUpCommand:@"export" type:@"artboards"];
	[context addCommand:@"--output" arg:self.outputPath.stringValue];
	self.tool = [SketchExportTool exportTool];
	[self.tool exportImagesFromContext:context];
	
}



- (void)showPathOpenPanelCanChoseFiles:(BOOL)canChoseFiles canChoseDir:(BOOL)canChoseDir allowMutipleSelection:(BOOL)mutiable directoryURL:(NSURL *)directoryURL contentTypes:(NSArray <NSString *>*)contentTypes completion:(void(^)(NSArray<NSURL *>*urls))completion
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setAllowsMultipleSelection:mutiable];
	[panel setCanChooseDirectories:canChoseDir];
	[panel setCanChooseFiles:canChoseFiles];
	[panel setResolvesAliases:YES];
	panel.allowedFileTypes = contentTypes;
	panel.directoryURL = directoryURL;
	panel.treatsFilePackagesAsDirectories = YES;
	panel.canCreateDirectories = YES;
	
	NSString *panelTitle = NSLocalizedString(@"Choose a file", @"Title for the open panel");
	[panel setTitle:panelTitle];
	
	NSString *promptString = NSLocalizedString(@"Choose", @"Prompt for the open panel prompt");
	[panel setPrompt:promptString];
	
	[panel beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:^(NSInteger result){
		
		// If the return code wasn't OK, don't do anything.
		if (result != NSModalResponseOK)
		{
			return;
		}
		if (completion != nil)
		{
			completion([panel URLs]);
		}
	}];
}

@end
