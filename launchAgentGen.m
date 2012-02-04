/*

launchAgentGen.m
setWeblocThumb

Copyright (c) 2009-2012 Ali Rantakari (http://hasseg.org)

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

#import "launchAgentGen.h"

#include <mach-o/dyld.h> // for _NSGetExecutablePath()
#import "HGCLIUtils.h"


NSString *encodeForXML(NSString *aStr)
{
    NSMutableString *str = [[aStr mutableCopy] autorelease];
    
    [str replaceOccurrencesOfString:@"&"  withString:@"&amp;"  options:NSLiteralSearch range:NSMakeRange(0, [str length])];
    [str replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:NSLiteralSearch range:NSMakeRange(0, [str length])];
    [str replaceOccurrencesOfString:@"'"  withString:@"&#x27;" options:NSLiteralSearch range:NSMakeRange(0, [str length])];
    [str replaceOccurrencesOfString:@">"  withString:@"&gt;"   options:NSLiteralSearch range:NSMakeRange(0, [str length])];
    [str replaceOccurrencesOfString:@"<"  withString:@"&lt;"   options:NSLiteralSearch range:NSMakeRange(0, [str length])];

    return str;
}


static NSString *launchAgentXMLFormat =
    @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    @"<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
    @"<plist version=\"1.0\">\n"
    @"<dict>\n"
    @"	<key>Label</key>\n"
    @"	<string>%@</string>\n"
    @"	<key>ProgramArguments</key>\n"
    @"	<array>\n"
    @"		<string>%@</string>\n"
    @"		<string>%@</string>\n"
    @"	</array>\n"
    @"	<key>WatchPaths</key>\n"
    @"	<array>\n"
    @"		<string>%@</string>\n"
    @"	</array>\n"
    @"</dict>\n"
    @"</plist>";

#define LAUNCHCTL_PATH @"/bin/launchctl"
#define USER_LAUNCH_AGENTS_PATH [@"~/Library/LaunchAgents" stringByStandardizingPath]
#define LAUNCH_AGENT_LABEL_PREFIX @"org.hasseg.setWeblocThumb."

NSString *getExecutablePath()
{
    // (If buffer is not long enough, _NSGetExecutablePath() sets buflen to
    // the correct length and returns -1)
    uint32_t buflen = 0;
    _NSGetExecutablePath(NULL, &buflen);
    char buf[buflen];
    _NSGetExecutablePath(buf, &buflen);
    
    return [[NSString stringWithUTF8String:buf] stringByStandardizingPath];
}

BOOL generateLaunchAgent(NSString *targetPath)
{
    // Determine absolute target path
    NSString *absTargetPath = nil;
    if ([targetPath isAbsolutePath])
        absTargetPath = targetPath;
    else
        absTargetPath = [targetPath stringByStandardizingPath];
    
    if (![absTargetPath isAbsolutePath])
    {
        PrintfErr(@"Cannot make path absolute: %@\n", targetPath);
        PrintfErr(@"Please provide an absolute path.\n");
        return NO;
    }
    
    // Format launch agent label suitable for XML and a filename
    NSMutableString *labelSuffix = [[absTargetPath mutableCopy] autorelease];
    if ([labelSuffix hasPrefix:@"/"])
        [labelSuffix deleteCharactersInRange:NSMakeRange(0,1)];
    [labelSuffix replaceOccurrencesOfString:@"/"  withString:@"." options:NSLiteralSearch range:NSMakeRange(0, [labelSuffix length])];
    [labelSuffix replaceOccurrencesOfString:@"\"" withString:@"-" options:NSLiteralSearch range:NSMakeRange(0, [labelSuffix length])];
    [labelSuffix replaceOccurrencesOfString:@"'"  withString:@"-" options:NSLiteralSearch range:NSMakeRange(0, [labelSuffix length])];
    NSString *label = [LAUNCH_AGENT_LABEL_PREFIX stringByAppendingString:labelSuffix];
    
    // Get absolute path to self (the setWeblocThumb executable)
    NSString *pathToExec = getExecutablePath();
    
    // Generate LaunchAgent property list XML
    NSString *plistXML = [NSString stringWithFormat:launchAgentXMLFormat,
        encodeForXML(label),
        encodeForXML(pathToExec),
        encodeForXML(absTargetPath),
        encodeForXML(absTargetPath)];
    
    // Determine target path for saving the .plist file into
    NSString *savePath = [USER_LAUNCH_AGENTS_PATH
                          stringByAppendingPathComponent:[label stringByAppendingString:@".plist"]];
    
    // Write property list XML into file
    if ([[NSFileManager defaultManager] fileExistsAtPath:savePath])
    {
        PrintfErr(@"File already exists:\n  %@\n", savePath);
        PrintfErr(@"If you want to replace the existing LaunchAgent, unload\n"
                  @"it with launchctl and then remove the file.\n");
        return NO;
    }
    NSError *writeErr = nil;
    if (![plistXML writeToFile:savePath atomically:NO encoding:NSUTF8StringEncoding error:&writeErr])
    {
        PrintfErr(@"Cannot write file:\n  %@\n", savePath);
        PrintfErr(@"Reason: %@", [writeErr description]);
        return NO;
    }
    
    Printf(@"The launch agent has been saved to:\n  %@\n", savePath);
    
    // Load the launch agent via launchctl
    NSTask *launchctlLoadTask = [NSTask
        launchedTaskWithLaunchPath:LAUNCHCTL_PATH
        arguments:[NSArray arrayWithObjects:@"load", savePath, nil]
        ];
    [launchctlLoadTask waitUntilExit];
    if (0 < [launchctlLoadTask terminationStatus])
    {
        PrintfErr(@"Error running 'launchctl load': exit status %i\n", [launchctlLoadTask terminationStatus]);
        PrintfErr(@"You will have to load the launch agent manually using launchctl.\n");
        return NO;
    }
    
    Printf(@"The launch agent has been successfully loaded.\n");
    
    return YES;
}


#define FM [NSFileManager defaultManager]

void iterateOurLaunchAgents(void(^workerBlock)(NSDictionary *agentPlist))
{
    NSError *dirEnumErr = nil;
    NSArray *launchAgentDirContents = [FM contentsOfDirectoryAtPath:USER_LAUNCH_AGENTS_PATH error:&dirEnumErr];
    if (dirEnumErr != nil)
    {
        PrintfErr(@"Error reading user launch agent directory contents:\n  %@\n", USER_LAUNCH_AGENTS_PATH);
        return;
    }
    
    for (NSString *filename in launchAgentDirContents)
    {
        NSString *path = [USER_LAUNCH_AGENTS_PATH stringByAppendingPathComponent:filename];
        // Ignore folders:
        BOOL isDir;
        if (![FM fileExistsAtPath:path isDirectory:&isDir] || isDir)
            continue;
        // Read plist into dictionary:
        NSDictionary *agentDict = [NSDictionary dictionaryWithContentsOfFile:path];
        if (agentDict == nil)
            continue;
        // Ignore if it does not seem to be executing this program:
        NSArray *programArgs = [agentDict objectForKey:@"ProgramArguments"];
        if (programArgs == nil || programArgs.count == 0)
            continue;
        if (![[programArgs objectAtIndex:0] hasSuffix:@"setWeblocThumb"])
            continue;
        // At this point we know this agent runs this program:
        workerBlock(agentDict);
    }
}

void printLaunchAgentWatchPaths()
{
    iterateOurLaunchAgents(^(NSDictionary *agentPlist)
    {
        NSArray *watchPaths = [agentPlist objectForKey:@"WatchPaths"];
        if (watchPaths == nil || watchPaths.count == 0)
            return;
        for (NSString *watchPath in watchPaths)
        {
            Printf(@"%@\n", watchPath);
        }
    });
}


