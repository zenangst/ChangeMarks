//
//  ChangeModelTests.m
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 27/04/15.
//  Copyright (c) 2015 zenangst. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "ChangeModel.h"

@interface ChangeModelTests : XCTestCase

@end

@implementation ChangeModelTests

- (void)testChangeModelValidInRangeValidRanges {

    NSRange documentRange = NSMakeRange(0, 200);

    ChangeModel *model1 = [ChangeModel withRange:NSMakeRange(2, 10) documentPath:@""];
    ChangeModel *model2 = [ChangeModel withRange:NSMakeRange(199, 1) documentPath:@""];

    XCTAssertTrue([model1 isValidInRange:documentRange]);
    XCTAssertTrue([model2 isValidInRange:documentRange]);
}

- (void)testChangeModelValidInRangeInvalidRanges {
    NSRange documentRange = NSMakeRange(0, 200);

    ChangeModel *model3 = [ChangeModel withRange:NSMakeRange(199, 20) documentPath:@""];
    ChangeModel *model4 = [ChangeModel withRange:NSMakeRange(100, 200) documentPath:@""];

    XCTAssertFalse([model3 isValidInRange:documentRange]);
    XCTAssertFalse([model4 isValidInRange:documentRange]);
}

@end
