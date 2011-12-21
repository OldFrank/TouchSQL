//
//  CSqliteDatabase_Extensions.m
//  TouchCode
//
//  Created by Jonathan Wight on Tue Apr 27 2004.
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

#import "CSqliteDatabase_Extensions.h"

#import "CSqliteStatement.h"
#import "CSqliteRow.h"

@implementation CSqliteDatabase (CSqliteDatabase_Extensions)

- (BOOL)executeExpression:(NSString *)inExpression error:(NSError **)outError
    {
    CSqliteStatement *theStatement = [self statementWithString:inExpression];
    return([theStatement execute:outError]);
    }

- (NSEnumerator *)enumeratorForExpression:(NSString *)inExpression error:(NSError **)outError
    {
    CSqliteStatement *theStatement = [self statementWithString:inExpression];
    return([theStatement enumerator]);
    }

- (NSArray *)rowsForExpression:(NSString *)inExpression error:(NSError **)outError
    {
    CSqliteStatement *theStatement = [self statementWithString:inExpression];
    return([theStatement fetchRowsCapturingValues:YES error:outError]);
    }

- (CSqliteRow *)rowForExpression:(NSString *)inExpression error:(NSError **)outError
    {
    CSqliteStatement *theStatement = [self statementWithString:inExpression];
    [theStatement step:outError];
    CSqliteRow *theRow = [theStatement fetchRowCapturingValues:NO error:outError];
    return(theRow);
    }

- (NSArray *)valuesForExpression:(NSString *)inExpression error:(NSError **)outError
    {
    CSqliteRow *theRow = [self rowForExpression:inExpression error:outError];
    return([theRow allValues]);
    }

- (id)valueForExpression:(NSString *)inExpression error:(NSError **)outError
    {
    NSArray *theValues = [self valuesForExpression:inExpression error:outError];
    // TODO -- check only 1 object is returned?
    return([theValues lastObject]);
    }

@end
