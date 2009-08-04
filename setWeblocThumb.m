/*

setWeblocThumb
--------------
Sets custom icons for .webloc files that display a thumbnail of the
web page that the URL contained by the file points to.

Copyright (c) 2009 Ali Rantakari (http://hasseg.org)

--------------

Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License. You may obtain
a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations
under the License.

*/

#include <libgen.h>
#import <Cocoa/Cocoa.h>
#import <Webkit/Webkit.h>
#import "MBBase64.h"
#import "imgBase64.m"


#define DEBUG_LEVEL 0

#define DEBUG_ERROR   (DEBUG_LEVEL >= 1)
#define DEBUG_WARN    (DEBUG_LEVEL >= 2)
#define DEBUG_INFO    (DEBUG_LEVEL >= 3)
#define DEBUG_VERBOSE (DEBUG_LEVEL >= 4)

#define DDLogError(format, ...)		if(DEBUG_ERROR)   \
										NSLog((format), ##__VA_ARGS__)
#define DDLogWarn(format, ...)		if(DEBUG_WARN)    \
										NSLog((format), ##__VA_ARGS__)
#define DDLogInfo(format, ...)		if(DEBUG_INFO)    \
										NSLog((format), ##__VA_ARGS__)
#define DDLogVerbose(format, ...)	if(DEBUG_VERBOSE) \
										NSLog((format), ##__VA_ARGS__)


#define GETURL_AS_FORMAT_STR @"tell the application \"Finder\" to return location of (POSIX file \"%@\" as file)"


NSImage *baseIconImage = nil;
BOOL arg_verbose = NO;

NSData *standardWeblocIcon = nil;


BOOL fileHasCustomIcon(NSString *filePath)
{
	// we have to compare TIFFRepresentations since NSImage's isEqualTo: only
	// does pointer equality, which won't work for us here
	
	if (standardWeblocIcon == nil)
		standardWeblocIcon = [[[NSWorkspace sharedWorkspace] iconForFileType:@"webloc"] TIFFRepresentation];
	
	NSData *fileIcon = [[[NSWorkspace sharedWorkspace] iconForFile:filePath] TIFFRepresentation];
	if (standardWeblocIcon == nil || fileIcon == nil)
		return NO;
	return ![fileIcon isEqual:standardWeblocIcon];
}


// other NSPrintf functions call this, and you call them
void RealNSPrintf(NSString *aStr, va_list args)
{
	NSString *str = [
		[[NSString alloc]
			initWithFormat:aStr
			locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
			arguments:args
			] autorelease
		];
	
	[str writeToFile:@"/dev/stdout" atomically:NO encoding:NSUTF8StringEncoding error:NULL];
}

void VerboseNSPrintf(NSString *aStr, ...)
{
	if (!arg_verbose)
		return;
	va_list argList;
	va_start(argList, aStr);
	RealNSPrintf(aStr, argList);
	va_end(argList);
}

void NSPrintf(NSString *aStr, ...)
{
	if (!arg_verbose)
		return;
	va_list argList;
	va_start(argList, aStr);
	RealNSPrintf(aStr, argList);
	va_end(argList);
}

void NSPrintfErr(NSString *aStr, ...)
{
	va_list argList;
	va_start(argList, aStr);
	NSString *str = [
		[[NSString alloc]
			initWithFormat:aStr
			locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
			arguments:argList
			] autorelease
		];
	va_end(argList);
	
	[str writeToFile:@"/dev/stderr" atomically:NO encoding:NSUTF8StringEncoding error:NULL];
}







// a WeblocIconifier is responsible for loading the web page
// that a .webloc file's URL points to, creating an icon with
// the thumbnail of that web page and assigning it to the
// .webloc file
@interface WeblocIconifier:NSObject
{
	WebView *webView;
	NSString *weblocFilePath;
	BOOL doneLoading;
}

@property(retain) WebView *webView;
@property(copy) NSString *weblocFilePath;

- (BOOL) doneLoading;
- (NSString *) getURLOfWeblocFileAtPath:(NSString *)path;
- (void) start;
- (void) setSelfAsDone;

@end

@implementation WeblocIconifier

@synthesize webView;
@synthesize weblocFilePath;

- (id) init
{
	if (( self = [super init] ))
	{
		doneLoading = NO;
	}
	
	return self;
}

- (void) dealloc
{
	self.webView = nil;
	self.weblocFilePath = nil;
	[super dealloc];
}


- (void) start
{
	VerboseNSPrintf(@"start: %@\n", self.weblocFilePath);
	
	NSAssert((self.weblocFilePath != nil), @"self.weblocFilePath is nil");
	
	if (self.webView == nil)
	{
		self.webView = [[WebView alloc] init];
		[self.webView setFrame:NSMakeRect(0, 0, 700, 700)];
		[self.webView setDrawsBackground:YES];
		[self.webView setFrameLoadDelegate:self];
	}
	
	NSString *weblocFileURL = [self getURLOfWeblocFileAtPath:weblocFilePath];
	DDLogVerbose(@"url: %@", weblocFileURL);
	
	[self.webView setMainFrameURL:weblocFileURL];
	[self.webView reload:self];
}

- (BOOL) doneLoading
{
	return doneLoading;
}

- (void) setSelfAsDone
{
	doneLoading = YES;
	VerboseNSPrintf(@" -> done: %@\n", self.weblocFilePath);
}



- (NSString *) getURLOfWeblocFileAtPath:(NSString *)path
{
	NSDictionary *appleScriptError;
	NSString *asSource = [NSString stringWithFormat:GETURL_AS_FORMAT_STR, path];
	NSAppleScript *getURLAppleScript = [[NSAppleScript alloc] initWithSource:asSource];
	NSAppleEventDescriptor *ret = [getURLAppleScript executeAndReturnError:&appleScriptError];
	return [ret stringValue];
	[getURLAppleScript release];
}


- (void) webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	DDLogVerbose(@"didFinishLoadForFrame:. isLoading = %@, estimatedProgress = %f",
		  ([self.webView isLoading]?@"YES":@"NO"),
		  [self.webView estimatedProgress]
		  );
	
	if ([self.webView isLoading] || doneLoading)
		return;
	
	DDLogVerbose(@"drawing icon for: %@", self.weblocFilePath);
	
	NSBitmapImageRep *webViewImageRep = [webView bitmapImageRepForCachingDisplayInRect:[webView frame]];
    [webView cacheDisplayInRect:[webView frame] toBitmapImageRep:webViewImageRep];
    NSImage *webViewImage = [[NSImage alloc] initWithSize:NSMakeSize(1280, 1024)];
    [webViewImage addRepresentation:webViewImageRep];
	
	NSImage *newIconImage = [[baseIconImage copy] autorelease];
	[newIconImage lockFocus];
	[webViewImage
	 drawInRect:NSMakeRect(95, 160, 320, 320)
	 fromRect:NSZeroRect
	 operation:NSCompositeCopy
	 fraction:1.0
	 ];
	[newIconImage unlockFocus];
	
	[[NSWorkspace sharedWorkspace]
	 setIcon:newIconImage
	 forFile:weblocFilePath
	 options:0
	 ];
	 
	 [self setSelfAsDone];
}

- (void) webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	NSPrintfErr(@" -> FAIL: %@\n    %@\n", self.weblocFilePath, error);
	[self setSelfAsDone];
}

- (void) webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	NSPrintfErr(@" -> FAIL: %@\n    %@\n", self.weblocFilePath, error);
	[self setSelfAsDone];
}


@end



int main(int argc, char *argv[])
{
	NSAutoreleasePool *autoReleasePool = [[NSAutoreleasePool alloc] init];
	
	NSApplicationLoad(); // initialize some Cocoa stuff
	
	char *myBasename = basename(argv[0]);
	if (argc == 1)
	{
		printf("usage: %s [-f] [-v] <path>\n", myBasename);
		printf("\n");
		printf("       Sets custom icons for .webloc files that display\n");
		printf("       a thumbnail of the web page that they point to.\n");
		printf("\n");
		printf("       <path> may point to a .webloc file or a directory\n");
		printf("       that contains .webloc files.\n");
		printf("\n");
		printf("       -f  sets icons also for files that already have a\n");
		printf("           custom icon.\n");
		printf("\n");
		printf("       -v  makes the output verbose.\n");
		printf("\n");
		exit(0);
	}
	
	BOOL arg_forceRun = NO;
	NSMutableArray *weblocFilePaths = [NSMutableArray array];
	
	NSString *providedPath = [[NSString stringWithUTF8String:argv[argc-1]] stringByStandardizingPath];
	
	if (argc > 2)
	{
		int i;
		for (i = 0; i < argc; i++)
		{
			if (strcmp(argv[i], "-f") == 0)
				arg_forceRun = YES;
			else if (strcmp(argv[i], "-v") == 0)
				arg_verbose = YES;
		}
	}
	
	BOOL isDir = NO;
	if (![[NSFileManager defaultManager] fileExistsAtPath:providedPath isDirectory:&isDir])
	{
		NSPrintfErr(@"Error: provided path does not exist:\n%s\n\n", [providedPath UTF8String]);
		exit(1);
	}
	if (!isDir && ![[providedPath pathExtension] isEqualToString:@"webloc"])
	{
		NSPrintfErr(@"Error: specified filename does not have extension: .webloc\n\n");
		exit(1);
	}
	
	if (!isDir)
	{
		[weblocFilePaths addObject:providedPath];
	}
	else
	{
		NSArray *dirContents = [[NSFileManager defaultManager]
			contentsOfDirectoryAtPath:providedPath
			error:NULL
			];
		
		if (dirContents != nil)
		{
			NSString *aFile;
			for (aFile in dirContents)
			{
				if ([[aFile pathExtension] isEqualToString:@"webloc"])
					[weblocFilePaths addObject:[providedPath stringByAppendingPathComponent:aFile]];
			}
		}
	}
	
	
	
	NSMutableArray *weblocIconifiers = [NSMutableArray arrayWithCapacity:[weblocFilePaths count]];
	
	NSString *aFilePath;
	for (aFilePath in weblocFilePaths)
	{
		if (!arg_forceRun && fileHasCustomIcon(aFilePath))
			VerboseNSPrintf(@"File already has a custom icon: %@\n", aFilePath);
		else
		{
			WeblocIconifier *weblocIconifier = [[[WeblocIconifier alloc] init] autorelease];
			weblocIconifier.weblocFilePath = aFilePath;
			[weblocIconifiers addObject:weblocIconifier];
		}
	}
	
	if ([weblocIconifiers count] == 0)
		exit(0);
	
	
	baseIconImage = [[NSImage alloc] initWithData:(NSData *)[NSData dataWithBase64EncodedString:imgBase64]];
	NSCAssert((baseIconImage != nil), @"baseIconImage is nil");
	
	
	WeblocIconifier *aWeblocIconifier;
	for (aWeblocIconifier in weblocIconifiers)
	{
		[aWeblocIconifier start];
	}
	
	
	BOOL isRunning = YES;
	BOOL someStillLoading = YES;
	do
	{
		isRunning = [[NSRunLoop currentRunLoop]
			runMode:NSDefaultRunLoopMode
			beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.2]
			];
		
		someStillLoading = NO;
		for (aWeblocIconifier in weblocIconifiers)
		{
			someStillLoading = ![aWeblocIconifier doneLoading];
			if (someStillLoading)
				break;
		}
	}
	while(isRunning && someStillLoading);
	
	[baseIconImage release];
	[autoReleasePool release];
	exit(0);
}


