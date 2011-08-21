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
        
        NSError *theError = NULL;
        
        NSInteger theColumnCount = [statement columnCount:&theError];
        if (theColumnCount < 0)
            return(NULL);
        NSMutableArray *theRow = [NSMutableArray arrayWithCapacity:theColumnCount];
        for (NSInteger N = 0; N != theColumnCount; ++N)
            {
            id theValue = [statement columnValueAtIndex:N error:&theError];
            if (theError != NULL)
                {
                self = NULL;
                return(NULL);
                }
            if (theValue)
                {
                [theRow addObject:theValue];
                }
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

- (id)valueForKey:(NSString *)aKey
    {
    return([self objectForKey:aKey]);
    }

#pragma mark -

- (id)objectAtIndex:(NSUInteger)inIndex;
    {
    return([self.allValues objectAtIndex:inIndex]);
    }

- (id)objectForKey:(id)aKey
    {
    NSInteger theIndex = [self.statement.columnNames indexOfObject:aKey];
    id theValue = [self.allValues objectAtIndex:theIndex];
    if (theValue == [NSNull null])
        {
        theValue = NULL;
        }
    
    return(theValue);
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
