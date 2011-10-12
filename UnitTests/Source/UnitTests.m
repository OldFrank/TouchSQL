//
//  UnitTests.m
//  TouchCode
//
//  Created by Jonathan Wight on 06/07/2005.
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

#import "UnitTests.h"

#import <TouchSQL/TouchSQL.h>

@implementation UnitTests

#pragma warning TODO implement fixtures/setup/teardown

- (void)testDatabaseCreate;
{
	CSqliteDatabase *db = [[CSqliteDatabase alloc] initInMemory];
	
	BOOL result;
	
	result = [db open:NULL];
	STAssertTrue(result, @"Databases should be openable");
	
	result = [db executeExpression:@"create table foo (name varchar(100))" error:NULL];
	STAssertTrue(result, @"Databases should be createable");
	
//	[db close];
}

- (void)testInsert;
{
	CSqliteDatabase *db = [[CSqliteDatabase alloc] initInMemory];
	[db open:NULL];
	
	BOOL result;
	result = [db executeExpression:@"create table foo (name varchar(100))" error:NULL];
	
	result = [db executeExpression:@"INSERT INTO foo VALUES ('testname')" error:NULL];
	STAssertTrue(result, @"Inserts should work");
	
	NSError *err = NULL;
	NSArray *rows = [db rowsForExpression:@"SELECT * FROM foo WHERE 1" error:&err];
	STAssertNil(err, @"Should be able to select from database");
	
	CSqliteRow *row = [rows objectAtIndex:0];
	STAssertNotNil(row, @"Should be able to get a row from the database");
	STAssertEqualObjects([row objectForKey:@"name"], @"testname", @"Should be able to select inserted data");
	
//	[db close];
}

- (void)testEnumerate;
{
	CSqliteDatabase *db = [[CSqliteDatabase alloc] initInMemory];
	[db open:NULL];
	
	[db executeExpression:@"create table foo (name varchar(100))" error:NULL];

	NSMutableSet *names = [NSMutableSet set];
	NSString *name;
	NSString *expression;
	int i;
	for (i = 0; i < 10; i++) {
		name = [NSString stringWithFormat:@"name%d", i];
		[names addObject:name];
		expression = [NSString stringWithFormat:@"INSERT INTO foo VALUES('%@')", name];
		[db executeExpression:expression error:NULL];
	}
	
	NSMutableSet *selectedNames = [NSMutableSet set];
	NSEnumerator *rowEnumerator = [db enumeratorForExpression:@"SELECT * FROM foo WHERE 1" error:NULL];
	for (NSDictionary *row in rowEnumerator) {
		[selectedNames addObject:[row objectForKey:@"name"]];
	}
	STAssertEqualObjects(selectedNames, names, @"Enumeration should get all rows");
	
//	[db close];
}

@end
