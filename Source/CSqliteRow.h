//
//  CSqliteRow.h
//  TouchSQL
//
//  Created by Jonathan Wight on 8/17/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CSqliteStatement;

@interface CSqliteRow : NSObject

- (id)initWithStatement:(CSqliteStatement *)inStatement;

- (id)objectAtIndex:(NSUInteger)inIndex;

- (id)objectForKey:(id)aKey;
- (NSArray *)allKeys;
- (NSArray *)allValues;

- (NSDictionary *)asDictionary;

@end
