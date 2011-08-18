//
//  CSqliteRow.m
//  TouchSQL
//
//  Created by Jonathan Wight on 8/17/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import "CSqliteRow.h"

#import "CSqliteStatement.h"

@interface CSqliteRow ()
@property (readonly, nonatomic, weak) CSqliteStatement *statement;
@property (readonly, nonatomic, strong) NSArray *allValues;
@end

#pragma mark -

@implementation CSqliteRow

@synthesize statement;
@synthesize allValues;

- (id)initWithStatement:(CSqliteStatement *)inStatement
    {
    if ((self = [super init]) != NULL)
        {
        statement = inStatement;
                    
        int theColumnCount = (int)[statement columnCount:NULL];
        if (theColumnCount < 0)
            return(NULL);
        NSMutableArray *theRow = [NSMutableArray arrayWithCapacity:theColumnCount];
        for (int N = 0; N != theColumnCount; ++N)
            {
            id theValue = [statement columnValueAtIndex:N error:NULL];
            [theRow addObject:theValue];
            }
        allValues = [theRow copy];
        
        }
    return self;
    }

- (NSString *)description
    {
    return([[self asDictionary] description]);
    }

- (NSString *)debugDescription
    {
    return([[self asDictionary] description]);
    }


- (id)objectForKey:(id)aKey
    {
    return([self.statement columnValueForName:aKey error:NULL]);
    }
    
- (NSArray *)allKeys
    {
    return(self.statement.columnNames);
    }
    
- (NSDictionary *)asDictionary;
    {
    return([NSDictionary dictionaryWithObjects:self.allKeys forKeys:self.allValues]);
    }

@end
