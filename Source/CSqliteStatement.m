//
//  CSqliteStatement.m
//  TouchCode
//
//  Created by Jonathan Wight on 9/12/08.
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

#import "CSqliteStatement.h"

#import "CSqliteDatabase.h"
#import "CSqliteDatabase_Extensions.h"
#import "CSqliteEnumerator.h"
#import "CSqliteRow.h"

@interface CSqliteStatement ()
@property (readwrite, nonatomic, strong) NSArray *columnNames;
@property (readwrite, nonatomic, assign) BOOL done;
@end

@implementation CSqliteStatement

@synthesize database;
@synthesize statementString;
@synthesize statement;
@synthesize columnNames;
@synthesize done;

- (id)initWithDatabase:(CSqliteDatabase *)inDatabase string:(NSString *)inString;
    {
    if ((self = [self init]) != NULL)
        {
        database = inDatabase;
        statementString = inString;
        }
    return(self);
    }

- (id)initWithDatabase:(CSqliteDatabase *)inDatabase format:(NSString *)inFormat, ...;
    {
    va_list theArgs;
    va_start(theArgs, inFormat);

    NSString *theString = [[NSString alloc] initWithFormat:inFormat arguments:theArgs];

    va_end(theArgs);

    if ((self = [self initWithDatabase:inDatabase string:theString]) != NULL)
        {
        }
    return(self);
    }

- (void)dealloc
    {
    if (statement != NULL)
        {
        sqlite3_finalize(statement);
        statement = NULL;
        }
    }

#pragma mark -

- (sqlite3_stmt *)statement
    {
    if (statement == NULL && self.statementString != NULL)
        {
        [self prepare:NULL];
        }
    return(statement);
    }

- (void)setStatement:(sqlite3_stmt *)inStatement
    {
    if (statement != inStatement)
        {
        if (statement != NULL)
            {
            sqlite3_finalize(statement);
            statement = NULL;
            }

        statement = inStatement;
        }
    }

- (NSArray *)columnNames
    {
    if (columnNames == NULL)
        {
        columnNames = [self columnNames:NULL];
        }
    return(columnNames);
    }

#pragma mark -

- (BOOL)finalize:(NSError **)outError;
    {
    if (statement != NULL)
        {
        sqlite3_finalize(statement);
        statement = NULL;
        }
    return(YES);
    }

- (BOOL)prepare:(NSError **)outError;
    {
    if (statement != NULL)
        {
        if (outError)
            {
            NSString *theErrorString = @"Cannot compile a statement that has already been compiled.";
            *outError = [NSError errorWithDomain:NSGenericException code:-1 userInfo:[NSDictionary dictionaryWithObject:theErrorString forKey:NSLocalizedDescriptionKey]];
            }

        return(NO);
        }

    sqlite3_stmt *theStatement = NULL;
    const char *theTail = NULL;

    int theResult = sqlite3_prepare_v2(self.database.sql, [self.statementString UTF8String], (int)[self.statementString length], &theStatement, &theTail);
    if (theResult != SQLITE_OK)
        {
        if (outError)
            {
            *outError = [self.database currentError];
            }

        if (theStatement != NULL)
            sqlite3_finalize(theStatement);

        return(NO);
        }

    self.statement = theStatement;

    return(YES);
    }

- (BOOL)step:(NSError **)outError
    {
    if (self.done)
        {
        return(NO);
        }
    
    int theResult = sqlite3_step(self.statement);
    if (theResult == SQLITE_ROW)
        {
        self.done = NO;
        return(YES);
        }
    else if (theResult == SQLITE_DONE)
        {
        self.done = YES;
        return(NO);
        }
    else
        {
        if (outError)
            {
            *outError = [self.database currentError];
            }
        return(NO);
        }
    return(YES);
    }

- (BOOL)execute:(NSError **)outError;
    {
    return([self step:outError]);
    }

- (BOOL)reset:(NSError **)outError
    {
    self.columnNames = NULL;
    self.done = NO;
    
    int theResult = sqlite3_reset(self.statement);
    if (theResult != SQLITE_OK)
        {
        if (outError)
            *outError = [self.database currentError];
        return(NO);
        }
    return(YES);
    }

#pragma mark -

- (NSInteger)columnCount:(NSError **)outError
    {
    #pragma unused (outError)

    NSInteger theColumnCount = sqlite3_column_count(self.statement);
    return(theColumnCount);
    }

- (NSString *)columnNameAtIndex:(NSInteger)inIndex error:(NSError **)outError
    {
    const char *theName = sqlite3_column_name(self.statement, (int)inIndex);
    if (theName == NULL)
        {
        if (outError)
            *outError = [self.database currentError];
        return(NULL);
        }
    return([NSString stringWithUTF8String:theName]);
    }

- (NSArray *)columnNames:(NSError **)outError;
    {
    NSInteger theColumnCount = [self columnCount:outError];
    if (theColumnCount < 0)
        return(NULL);
    NSMutableArray *theColumnNames = [NSMutableArray arrayWithCapacity:theColumnCount];
    for (int N = 0; N != theColumnCount; ++N)
        {
        NSString *theColumnName = [self columnNameAtIndex:N error:outError];
        [theColumnNames addObject:theColumnName];
        }
    return(theColumnNames);
    }

- (id)columnValueAtIndex:(NSInteger)inIndex error:(NSError **)outError
    {
    int theColumnType = sqlite3_column_type(self.statement, (int)inIndex);
    id theValue = NULL;
    switch (theColumnType)
        {
        case SQLITE_INTEGER:
            {
            sqlite_int64 theInt64 = sqlite3_column_int64(self.statement, (int)inIndex);
            theValue = [NSNumber numberWithLongLong:theInt64];
            }
            break;
        case SQLITE_FLOAT:
            {
            double theDouble = sqlite3_column_double(self.statement, (int)inIndex);
            theValue = [NSNumber numberWithDouble:theDouble];
            }
            break;
        case SQLITE_BLOB:
            {
            const void *theBytes = sqlite3_column_blob(self.statement, (int)inIndex);
            int theLength = sqlite3_column_bytes(self.statement, (int)inIndex);
            theValue = [NSData dataWithBytes:theBytes length:theLength];
            }
            break;
        case SQLITE_NULL:
            {
            theValue = [NSNull null];
            }
            break;
        case SQLITE_TEXT:
            {
            const unsigned char *theText = sqlite3_column_text(self.statement, (int)inIndex);
            theValue = [NSString stringWithUTF8String:(const char *)theText];
            }
            break;
        default:
            break;
        }
    return(theValue);
    }

#pragma mark -

- (BOOL)clearBindings:(NSError **)outError
    {
    int theResult = sqlite3_clear_bindings(self.statement);
    if (theResult != SQLITE_OK)
        {
        if (outError)
            *outError = [self.database currentError];
        return(NO);
        }
    return(YES);
    }

- (BOOL)bindValue:(id)inValue toBinding:(NSString *)inBinding transientValue:(BOOL)inTransientValues error:(NSError **)outError
    {
    sqlite3_destructor_type theDestructorType = inTransientValues ? SQLITE_TRANSIENT : SQLITE_STATIC;

    int theParameterIndex = sqlite3_bind_parameter_index(self.statement, [inBinding UTF8String]);
    int theResult;

    if ([inValue isKindOfClass:[NSData class]])
        {
        NSData *theData = (NSData *)inValue;
        theResult = sqlite3_bind_blob(self.statement, theParameterIndex, theData.bytes, (int)theData.length, theDestructorType);
        }
    else if ([inValue isKindOfClass:[NSNumber class]])
        {
        CFNumberType theType = CFNumberGetType((__bridge CFNumberRef)inValue);
        switch (theType)
            {
            case kCFNumberFloat32Type:
            case kCFNumberFloat64Type:
            case kCFNumberFloatType:
            case kCFNumberDoubleType:
                {
                const double theDouble = [inValue doubleValue];
                theResult = sqlite3_bind_double(self.statement, theParameterIndex, theDouble);
                }
                break;
            case kCFNumberSInt64Type:
                {
                sqlite_int64 theInt64;
                CFNumberGetValue((__bridge CFNumberRef)inValue, kCFNumberSInt64Type, &theInt64);
                theResult = sqlite3_bind_int64(self.statement, theParameterIndex, theInt64);
                }
                break;
            default:
                {
                int theInteger = [inValue intValue];
                theResult = sqlite3_bind_int(self.statement, theParameterIndex, theInteger);
                }
            }
        }
    else if (inValue == [NSNull null])
        {
        theResult = sqlite3_bind_null(self.statement, theParameterIndex);
        }
    else if ([inValue isKindOfClass:[NSString class]])
        {
        NSString *theString = (NSString *)inValue;
        theResult = sqlite3_bind_text(self.statement, theParameterIndex, [theString UTF8String], (int)theString.length, theDestructorType);
        }
    else
        {
        if (outError)
            {
            *outError = [NSError errorWithDomain:TouchSQLErrorDomain code:-1 userInfo:[NSDictionary dictionaryWithObject:@"Cannot convert object of that type." forKey:NSLocalizedDescriptionKey]];
            }
        return(NO);
        }

    if (theResult != SQLITE_OK)
        {
        if (outError)
            *outError = [self.database currentError];
        return(NO);
        }

    return(YES);
    }

- (BOOL)bindValues:(NSDictionary *)inValues transientValues:(BOOL)inTransientValues error:(NSError **)outError
    {
    for (NSString *theKey in inValues)
        {
        id theValue = [inValues objectForKey:theKey];

        if ([self bindValue:theValue toBinding:theKey transientValue:inTransientValues error:outError] == NO)
            return(NO);
        }

    return(YES);
    }

#pragma mark -

- (CSqliteRow *)fetchRowCapturingValues:(BOOL)inCaptureValues error:(NSError **)outError;
    {
    CSqliteRow *theRow = [[CSqliteRow alloc] initWithStatement:self];
    if (inCaptureValues)
        {
        if ([theRow captureValues:outError] == NO)
            {
            return(NULL);
            }
        }
    return(theRow);
    }

#pragma mark -

- (NSArray *)fetchRowsCapturingValues:(BOOL)inCaptureValues error:(NSError **)outError;
    {
    NSMutableArray *theRows = [NSMutableArray array];
    for (CSqliteRow *theRow in self)
        {
        [theRows addObject:theRow];
        }
    return(theRows);
    }

- (NSEnumerator *)enumerator
    {
    return([[CSqliteEnumerator alloc] initWithStatement:self]);
    }


#pragma mark -

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)len
    {
    if (state->state == 0)
        {
        state->state = 1;
        state->mutationsPtr = &state->state;
        }

    NSUInteger theObjectCount = 0;

    NSError *theError = NULL;

    while (theObjectCount < len && [self step:&theError] == YES)
        {
        id theRow = [self fetchRowCapturingValues:YES error:&theError];
        stackbuf[theObjectCount++] = theRow;
        }

    state->itemsPtr = stackbuf;

    return(theObjectCount);
    }
    
#pragma mark -

- (void)enumerateObjectsUsingBlock:(void (^)(CSqliteRow *row, NSUInteger idx, BOOL *stop))block
    {
    [self enumerateObjectsWithOptions:0 usingBlock:block];
    }

- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (^)(CSqliteRow *row, NSUInteger idx, BOOL *stop))block
    {
    NSParameterAssert(block != NULL);
    NSParameterAssert((opts & NSEnumerationReverse) == 0);

    NSError *theError = NULL;

    if (opts & NSEnumerationConcurrent)
        {
        dispatch_group_t theGroup = dispatch_group_create();
        dispatch_queue_t theQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        __block BOOL theStopFlag = NO;
        for (NSUInteger N = 0; theStopFlag == NO && [self step:&theError] == YES; N++)
            {
            CSqliteRow *theRow = [self fetchRowCapturingValues:NO error:&theError];
            
            dispatch_group_async(theGroup, theQueue, ^{
                block(theRow, N, &theStopFlag);
                });
            }
        
        dispatch_group_wait(theGroup, DISPATCH_TIME_FOREVER);
        
        dispatch_release(theGroup);
        }
    else
        {
        BOOL theStopFlag = NO;
        for (NSUInteger N = 0; theStopFlag == NO && [self step:&theError] == YES; N++)
            {
            CSqliteRow *theRow = [self fetchRowCapturingValues:NO error:&theError];
            block(theRow, N, &theStopFlag);
            }
        }
    }

@end

