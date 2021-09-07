//
//  TimeHiding.m
//  PentoFace WatchKit Extension
//
//  Created by Nicholaos Mouzourakis on 2020-04-03.
//  Copyright © 2020 NEVUM X. All rights reserved.
//

#import "TimeHiding.h"

#import <Foundation/Foundation.h>

@import ObjectiveC.runtime;

@interface NSObject (fs_override)
-(NSString*)timeText;
@end

void hideTime() {
    Class CLKTimeFormatter = NSClassFromString(@"CLKTimeFormatter");
    if ([CLKTimeFormatter instancesRespondToSelector:@selector(timeText)]) {
        Method m = class_getInstanceMethod(CLKTimeFormatter, @selector(timeText));
        method_setImplementation(m, imp_implementationWithBlock(^NSString*(id self, SEL _cmd) { return @" "; }));
    }
}
