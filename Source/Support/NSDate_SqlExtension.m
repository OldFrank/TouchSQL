//
//  NSDate_SqlExtension.m
//  TouchCode
//
//  Created by Jonathan Wight on 9/8/08.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//     1. Redistributions of source code must retain the above copyright notice, this list of
//        conditions and the following disclaimer.
//
//     2. Redistributions in binary form must reproduce the above copyright notice, this list
//        of conditions and the following disclaimer in the documentation and/or other materials
//        provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY TOXICSOFTWARE.COM ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TOXICSOFTWARE.COM OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of toxicsoftware.com.

#import "NSDate_SqlExtension.h"

@implementation NSDate (NSDate_SqlExtension)

static NSDateFormatter *gDateFormatter = NULL;

+ (NSDateFormatter *)sqlDateStringFormatter
{
@synchronized([self class])
	{
// 2008-09-09 02:12:36
	if (gDateFormatter == NULL)
		{
		NSDateFormatter *theFormatter = [[NSDateFormatter alloc] init];
		[theFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[theFormatter setGeneratesCalendarDates:NO];
		[theFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
		[theFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
		
		gDateFormatter = theFormatter;
		}
	}
return(gDateFormatter);
}

+ (NSDateFormatter *)sqlDateOnlyStringFormatter
{
	@synchronized([self class])
	{
		if (gDateFormatter == NULL)
		{
			NSDateFormatter *theFormatter = [[NSDateFormatter alloc] init];
			[theFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
			[theFormatter setGeneratesCalendarDates:NO];
			[theFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
			[theFormatter setDateFormat:@"yyyy-MM-dd"];
			
			gDateFormatter = theFormatter;
		}
	}
	return(gDateFormatter);
}


+ (id)dateWithSqlDateString:(NSString *)inString
{
NSDate *theDate = [[self sqlDateStringFormatter] dateFromString:inString];
//NSLog(@"%@ -> %@", inString, theDate);
return(theDate);
}

- (NSString *)sqlDateString
{
NSString *theDateString = [[[self class] sqlDateStringFormatter] stringFromDate:self];
//NSLog(@"%@ -> %@", self, theDateString);
return(theDateString);
}

- (NSString *)sqlDateOnlyString {
	return [[[self class] sqlDateOnlyStringFormatter] stringFromDate:self];
}


@end
