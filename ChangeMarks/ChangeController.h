//
//  ChangeController.h
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 26/04/15.
//  Copyright (c) 2015 zenangst. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChangeModel.h"

@interface ChangeController : NSObject

- (void)addChange:(ChangeModel *)change;
- (void)removeChange:(ChangeModel *)change;
- (void)clearChangeMarks:(NSString *)path;
- (void)adjustChangeMarksWithRange:(NSRange)range
                         withDelta:(NSInteger)delta
                  withDocumentPath:(NSString *)path;

- (NSRange)nextChange:(NSRange)range documentPath:(NSString *)string;
- (NSRange)previousChange:(NSRange)range  documentPath:(NSString *)string;

- (NSArray *)changesForDocument:(NSString *)path;

@end
