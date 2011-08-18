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
@property (readwrite, nonatomic, strong) NSString *path;
@property (readwrite, nonatomic, assign) sqlite3 *sql;
@property (readwrite, nonatomic, strong) NSMutableDictionary *userDictionary;
@end

@implementation CSqliteDatabase

@synthesize path;
@synthesize sql;
@synthesize userDictionary;

- (id)initWithPath:(NSString *)inPath
{
if (self = ([self init]))
    {
    path = inPath;
    }
return(self);
}

- (id)initInMemory;
{
return([self initWithPath:@":memory:"]);
}

- (void)dealloc
{
[self close];
}

#pragma mark -

- (BOOL)open:(NSError **)outError
{
if (sql == NULL)
    {
    sqlite3 *theSql = NULL;
    int theResult = sqlite3_open([self.path UTF8String], &theSql);
    if (theResult != SQLITE_OK)
        {
        if (outError)
            *outError = [NSError errorWithDomain:TouchSQLErrorDomain code:theResult userInfo:NULL];
        return(NO);
        }
    self.sql = theSql;
    }
return(YES);
}

- (void)close
{
if (self.sql)
    {
    if (sqlite3_close(self.sql) == SQLITE_BUSY)
        {
        NSLog(@"sqlite3_close() failed with SQLITE_BUSY!");
        }
    self.sql = NULL;
    }
}

- (void)setSql:(sqlite3 *)inSql
{
if (sql != inSql)
    {
    if (sql != NULL)
        {
        if (sqlite3_close(sql) == SQLITE_BUSY)
            NSLog(@"sqlite3_close() failed with SQLITE_BUSY!");
        sql = NULL;
        }
    sql = inSql;
    }
}


- (NSMutableDictionary *)userDictionary
{
if (userDictionary == NULL)
    {
    userDictionary = [[NSMutableDictionary alloc] init];
    }
return(userDictionary);
}

#pragma mark -

- (BOOL)begin
{
CSqliteStatement *theStatement = [self.userDictionary objectForKey:@"BEGIN TRANSACTION"];
if (theStatement == NULL)
	{
	theStatement = [[CSqliteStatement alloc] initWithDatabase:self string:@"BEGIN TRANSACTION"];
	[self.userDictionary setObject:theStatement forKey:@"BEGIN TRANSACTION"];
	}
return([theStatement execute:NULL]);
}

- (BOOL)commit
{
CSqliteStatement *theStatement = [self.userDictionary objectForKey:@"COMMIT"];
if (theStatement == NULL)
	{
	theStatement = [[CSqliteStatement alloc] initWithDatabase:self string:@"COMMIT"];
	[self.userDictionary setObject:theStatement forKey:@"COMMIT"];
	}
return([theStatement execute:NULL]);
}

- (BOOL)rollback
{
CSqliteStatement *theStatement = [self.userDictionary objectForKey:@"ROLLBACK"];
if (theStatement == NULL)
	{
	theStatement = [[CSqliteStatement alloc] initWithDatabase:self string:@"ROLLBACK"];
	[self.userDictionary setObject:theStatement forKey:@"ROLLBACK"];
	}
return([theStatement execute:NULL]);
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

@end
