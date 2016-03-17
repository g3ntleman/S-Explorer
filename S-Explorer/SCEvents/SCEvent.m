/*
 *  $Id: SCEvent.m 195 2011-03-15 21:47:34Z stuart $
 *
 *  SCEvents
 *  http://stuconnolly.com/projects/code/
 *
 *  Copyright (c) 2011 Stuart Connolly. All rights reserved.
 *
 *  Permission is hereby granted, free of charge, to any person
 *  obtaining a copy of this software and associated documentation
 *  files (the "Software"), to deal in the Software without
 *  restriction, including without limitation the rights to use,
 *  copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following
 *  conditions:
 *
 *  The above copyright notice and this permission notice shall be
 *  included in all copies or substantial portions of the Software.
 * 
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 *  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 *  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 *  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 *  OTHER DEALINGS IN THE SOFTWARE.
 */

#import "SCEvent.h"

@implementation SCEvent

#pragma mark -
#pragma mark Initialisation

/**
 * Returns an initialized instance of SCEvent using the supplied event ID, date, path 
 * and flag.
 *
 * @param identifer The ID of the event
 * @param date      The date of the event
 * @param path      The file system path of the event
 * @param flags     The flags associated with the event
 *
 * @return The initialized (autoreleased) instance
 */
+ (SCEvent *)eventWithEventId:(NSUInteger)identifier 
					eventDate:(NSDate *)date 
					eventPath:(NSString *)path 
				   eventFlags:(SCEventFlags)flags
{
    return [[SCEvent alloc] initWithEventId:identifier eventDate:date eventPath:path eventFlags:flags];
}

/**
 * Initializes an instance of SCEvent using the supplied event ID, path and flag.
 *
 * @param identifer The ID of the event
 * @param date      The date of the event
 * @param path      The file system path of the event
 * @param flags     The flags associated with the event
 *
 * @return The initialized instance
 */
- (id)initWithEventId:(NSUInteger)identifier 
			eventDate:(NSDate *)date 
			eventPath:(NSString *)path 
		   eventFlags:(SCEventFlags)flags {
    if ((self = [super init])) {
        [self setEventId:identifier];
        [self setEventDate:date];
        [self setEventPath:path];
        [self setEventFlags:flags];
    }
    
    return self;
}

#pragma mark -
#pragma mark Other

/**
 * Provides a textual representation of the eventFlags property. Useful for
 * debugging purposes.
 *
 * @return The description string
 */
- (NSString*) flagDescription {
    NSMutableArray* flagDescriptions = [NSMutableArray array];
    if (_eventFlags & SCEventStreamEventFlagMustScanSubDirs) {
        [flagDescriptions addObject: @"MustScanSubDirs"];
    }
    if (_eventFlags & SCEventStreamEventFlagUserDropped)       [flagDescriptions addObject: @"UserDropped"];
    if (_eventFlags & SCEventStreamEventFlagKernelDropped)     [flagDescriptions addObject: @"KernelDropped"];
    if (_eventFlags & SCEventStreamEventFlagEventIdsWrapped)   [flagDescriptions addObject: @"EventIdsWrapped"];
    if (_eventFlags & SCEventStreamEventFlagHistoryDone)       [flagDescriptions addObject: @"HistoryDone"];
    if (_eventFlags & SCEventStreamEventFlagRootChanged)       [flagDescriptions addObject: @"RootChanged"];
    if (_eventFlags & SCEventStreamEventFlagMount)             [flagDescriptions addObject: @"Mount"];
    if (_eventFlags & SCEventStreamEventFlagUnmount)           [flagDescriptions addObject: @"Unmount"];
    if (_eventFlags & SCEventStreamEventFlagItemCreated)       [flagDescriptions addObject: @"ItemCreated"];
    if (_eventFlags & SCEventStreamEventFlagItemRemoved)       [flagDescriptions addObject: @"ItemRemoved"];
    if (_eventFlags & SCEventStreamEventFlagItemInodeMetaMod)  [flagDescriptions addObject: @"ItemInodeMetaMod"];
    if (_eventFlags & SCEventStreamEventFlagItemRenamed)       [flagDescriptions addObject: @"ItemRenamed"];
    if (_eventFlags & SCEventStreamEventFlagItemModified)      [flagDescriptions addObject: @"ItemModified"];
    if (_eventFlags & SCEventStreamEventFlagItemFinderInfoMod) [flagDescriptions addObject: @"ItemFinderInfoMod"];
    if (_eventFlags & SCEventStreamEventFlagItemChangeOwner)   [flagDescriptions addObject: @"ItemChangeOwner"];
    if (_eventFlags & SCEventStreamEventFlagItemXattrMod)      [flagDescriptions addObject: @"ItemXattrMod"];
    if (_eventFlags & SCEventStreamEventFlagItemIsFile)        [flagDescriptions addObject: @"ItemIsFile"];
    if (_eventFlags & SCEventStreamEventFlagItemIsDir)         [flagDescriptions addObject: @"ItemIsDir"];
    if (_eventFlags & SCEventStreamEventFlagItemIsSymlink)     [flagDescriptions addObject: @"IsSymlink"];
    if (_eventFlags & SCEventStreamEventFlagOwnEvent)          [flagDescriptions addObject: @"OwnEvent"];
    
    return [flagDescriptions componentsJoinedByString: @", "];
}

/**
 * Provides the string used when printing this object in NSLog, etc. Useful for
 * debugging purposes.
 *
 * @return The description string
 */
- (NSString*) description {
    
	return [NSString stringWithFormat:@"<%@ { eventId = %ld, eventPath = %@, eventFlags = (%@) } >",
			[self className], 
			((unsigned long)_eventId), 
			[self eventPath], 
            [self flagDescription]];
}

@end
