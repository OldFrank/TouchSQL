//
//  CSqliteStatement.h
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

#import <Foundation/Foundation.h>

#include <sqlite3.h>

@class CSqliteDatabase;
@class CSqliteRow;

@interface CSqliteStatement : NSObject <NSFastEnumeration> {
}

@property (readonly, nonatomic, weak) CSqliteDatabase *database;
@property (readonly, nonatomic, copy) NSString *statementString;
@property (readonly, nonatomic, assign) sqlite3_stmt *statement;
@property (readonly, nonatomic, strong) NSArray *columnNames;
@property (readonly, nonatomic, assign) BOOL done;

- (id)initWithDatabase:(CSqliteDatabase *)inDatabase string:(NSString *)inString;
- (id)initWithDatabase:(CSqliteDatabase *)inDatabase format:(NSString *)inFormat, ...;

- (BOOL)prepare:(NSError **)outError;
- (BOOL)finalize:(NSError **)outError;
- (BOOL)step:(NSError **)outError;
- (BOOL)execute:(NSError **)outError;
- (BOOL)reset:(NSError **)outError;

- (NSInteger)columnCount:(NSError **)outError;
- (NSString *)columnNameAtIndex:(NSInteger)inIndex error:(NSError **)outError;
- (NSArray *)columnNames:(NSError **)outError;
- (id)columnValueAtIndex:(NSInteger)inIndex error:(NSError **)outError;

- (BOOL)clearBindings:(NSError **)outError;
- (BOOL)bindValue:(id)inValue toBinding:(NSString *)inBinding transientValue:(BOOL)inTransientValues error:(NSError **)outError;
- (BOOL)bindValues:(NSDictionary *)inValues transientValues:(BOOL)inTransientValues error:(NSError **)outError;

- (CSqliteRow *)row:(NSError **)outError;
- (NSArray *)rows:(NSError **)outError;

- (NSEnumerator *)enumerator;

- (void)enumerateObjectsUsingBlock:(void (^)(CSqliteRow *row, NSUInteger idx, BOOL *stop))block;
- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (^)(CSqliteRow *row, NSUInteger idx, BOOL *stop))block;

@end
