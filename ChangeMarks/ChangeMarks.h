//
//  ChangeMarks.h
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 31/10/14.
//  Copyright (c) 2014 zenangst. All rights reserved.
//

@interface ChangeMarks : NSObject

+ (instancetype)sharedPlugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;

@end
