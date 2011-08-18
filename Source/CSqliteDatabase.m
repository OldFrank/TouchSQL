//
//  CSqliteDatabase.m
//  TouchCode
//
//  Created by Jonathan Wight on Tue Apr 27 2004.
//  Copyright 2004 toxicsoftware.com. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "CSqliteDatabase.h"

#include <sqlite3.h>

#import "CSqliteStatement.h"
#import "CSqliteEnumerator.h"
#import "CSqliteDatabase_Extensions.h"

NSString *TouchSQLErrorDomain = @"TouchSQLErrorDomain";

@interface CSqliteDatabase ()
@property (readwrite, nonatomic, strong) NSMutableSet *activeStatements;
@property (readwrite, nonatomic, strong) CSqliteStatement *beginTransactionStatement;
@property (readwrite, nonatomic, strong) CSqliteStatement *commitStatement;
@property (readwrite, nonatomic, strong) CSqliteStatement *rollbackStatement;
@end

@implementation CSqliteDatabase

@synthesize URL;
@synthesize sql;

@synthesize activeStatements;
@synthesize beginTransactionStatement;
@synthesize commitStatement;
@synthesize rollbackStatement;

- (id)initWithSqlite3:(sqlite3 *)inSqlite3
    {
    if ((self = [super init]) != NULL)
        {
        sql = inSqlite3;
        activeStatements = [[NSMutableSet alloc] init];
        }
    return self;
    }

- (id)initWithURL:(NSURL *)inURL flags:(int)inFlags error:(NSError **)outError;
    {
    NSString *thePath = NULL;
    
    #if SQLITE_VERSION_NUMBER >= 3007007
    if (sqlite3_libversion_number() >= 3007007)
        {
        thePath = [inURL absoluteString];
        inFlags |= SQLITE_OPEN_URI;
        }
    #endif

    if (thePath == NULL)
        {
        if ([inURL isFileURL] == NO)
            {
            if (outError)
                {
                *outError = [NSError errorWithDomain:TouchSQLErrorDomain code:-1 userInfo:NULL];
                }
            self = NULL;
            return(NULL);
            }
        
        thePath = [inURL path];
        }
    
    
    sqlite3 *theSql = NULL;
    int theResult = sqlite3_open_v2([thePath UTF8String], &theSql, inFlags, NULL);
    if (theSql == NULL || theResult != SQLITE_OK)
        {
        if (outError)
            {
            *outError = [NSError errorWithDomain:TouchSQLErrorDomain code:theResult userInfo:NULL];
            }
        self = NULL;
        return(NULL);
        }

    if (self = ([self initWithSqlite3:theSql]))
        {
        URL = inURL;
        }
    return(self);
    }

- (id)initWithURL:(NSURL *)inURL error:(NSError **)outError;
    {
    return([self initWithURL:inURL flags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE error:outError]);
    }

- (id)initInMemory:(NSError **)outError
    {
    sqlite3 *theSql = NULL;
    int theResult = sqlite3_open(":memory:", &theSql);
    if (theSql == NULL)
        {
        if (outError)
            {
            *outError = [NSError errorWithDomain:TouchSQLErrorDomain code:theResult userInfo:NULL];
            }
        self = NULL;
        return(NULL);
        }
    
    return([self initWithSqlite3:theSql]);
    }
    
- (id)initTemporary:(NSError **)outError;
    {
    NSString *theTemporaryDirectory = NSTemporaryDirectory();
    NSString *theTemplate = [theTemporaryDirectory stringByAppendingFormat:@"sqlite_XXXXXXXX"];
    
    char *theBuffer = alloca(strlen([theTemplate UTF8String]) + 1);
    strcpy(theBuffer, [theTemplate UTF8String]);
    
    char *S = mktemp(theBuffer);
    
    NSString *theTemporaryPath = [NSString stringWithUTF8String:S];
    
    return([self initWithURL:[NSURL fileURLWithPath:theTemporaryPath] error:outError]);
    }

- (void)dealloc
    {
    for (CSqliteStatement *theStatement in activeStatements)
        {
        [theStatement finalize:NULL];
        }
    
    if (sql)
        {
        if (sqlite3_close(sql) == SQLITE_BUSY)
            {
            NSLog(@"sqlite3_close() failed with SQLITE_BUSY!");
            }
        sql = NULL;
        }
    }

#pragma mark -

- (NSString *)description
    {
    return([NSString stringWithFormat:@"%@ (%s, %@)", [super description], sqlite3_libversion(), self.URL]);
    }

#pragma mark -

- (CSqliteStatement *)beginTransactionStatement
    {
    if (beginTransactionStatement == NULL)
        {
        beginTransactionStatement = [[CSqliteStatement alloc] initWithDatabase:self string:@"BEGIN TRANSACTION"];
        }
    return(beginTransactionStatement);
    }

- (CSqliteStatement *)commitStatement
    {
    if (commitStatement == NULL)
        {
        commitStatement = [[CSqliteStatement alloc] initWithDatabase:self string:@"COMMIT"];
        }
    return(commitStatement);
    }

- (CSqliteStatement *)rollbackStatement
    {
    if (rollbackStatement == NULL)
        {
        rollbackStatement = [[CSqliteStatement alloc] init];
        }
    return(rollbackStatement);
    }

#pragma mark -

- (BOOL)begin
    {
    return([self.beginTransactionStatement execute:NULL]);
    }

- (BOOL)commit
    {
    return([self.commitStatement execute:NULL]);
    }

- (BOOL)rollback
    {
    return([self.rollbackStatement execute:NULL]);
    }

- (NSInteger)lastInsertRowID
    {
    // TODO 64 bit!??!?!?!
    sqlite_int64 theLastRowID = sqlite3_last_insert_rowid(self.sql);
    return(theLastRowID);
    }

- (NSError *)currentError
    {
    NSString *theErrorString = [NSString stringWithUTF8String:sqlite3_errmsg(self.sql)];
    NSError *theError = [NSError errorWithDomain:TouchSQLErrorDomain code:sqlite3_errcode(self.sql) userInfo:[NSDictionary dictionaryWithObject:theErrorString forKey:NSLocalizedDescriptionKey]];
    return(theError);
    }
    
#pragma mark -

- (CSqliteStatement *)statementWithString:(NSString *)inString;
    {
    // BUG -- the ativeStatements keeps building up and up and never shrinks. Only cleaned up with DB dealloc-ed.
    CSqliteStatement *theStatement = [[CSqliteStatement alloc] initWithDatabase:self string:inString];
    [self.activeStatements addObject:theStatement];
    return(theStatement);
    }

@end
