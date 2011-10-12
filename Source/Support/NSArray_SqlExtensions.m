//
//  NSArray_SqlExtensions.m
//  TouchCode
//
//  Created by Jonathan Wight on Fri Apr 16 2004.
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

#import "NSArray_SqlExtensions.h"

@implementation NSArray (NSArray_Extensions)

- (NSString *)componentsJoinedByQuotedSQLEscapedCommas
{
// ### Note I'm doing a certain amount of optimisation here which is why the code is a little bit fuggly (e.g. I'm avoiding NSEnumerators and trying not to create too many temporary objects).
NSMutableString *theString = [NSMutableString stringWithCapacity:512];
NSInteger theCount = [self count];
//
for (unsigned N = 0; N != theCount; ++N)
	{
	id theObject = [self objectAtIndex:N];
	if (theObject == NULL || [theObject isEqual:[NSNull null]])
		{
		[theString appendString:@"null"];
		}
	else
		{
		NSString *theTrimmedString = [theObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		if ([theTrimmedString length] == 0)
			{
			[theString appendString:@"null"];
			}
		else
			{
			[theString appendString:@"'"];
			NSInteger theStringLength = [theString length];
			[theString appendString:theTrimmedString];
			[theString replaceOccurrencesOfString:@"\'" withString:@"\'\'" options:NSLiteralSearch range:NSMakeRange(theStringLength, [theTrimmedString length])];
			[theString appendString:@"'"];
			}
		}
	if (N != theCount - 1)
		[theString appendString:@", "];
	}
return(theString);
}

@end
