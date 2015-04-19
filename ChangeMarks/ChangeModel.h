//
//  Change.h
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 19/04/15.
//  Copyright (c) 2015 zenangst. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChangeModel : NSObject

@property (nonatomic) NSUInteger location;
@property (nonatomic) NSUInteger length;

- (instancetype)initWithRange:(NSRange)range;

@end
