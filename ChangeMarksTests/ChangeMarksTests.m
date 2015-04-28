//
//  ChangeMarksTests.m
//  ChangeMarksTests
//
//  Created by Christoffer Winterkvist on 26/04/15.
//  Copyright (c) 2015 zenangst. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "ChangeController.h"
#import "ChangeModel.h"

@interface ChangeController ()

@property (nonatomic) NSMutableDictionary *changes;

@end

@interface ChangeMarksTests : XCTestCase

@end

@implementation ChangeMarksTests

- (void)testAddChange {
    ChangeController *controller = [ChangeController new];
    NSRange range1 = NSMakeRange(100, 20);
    NSRange range2 = NSMakeRange(95,10);

    [controller addChange:[ChangeModel withRange:range1 documentPath:@""]];
    [controller addChange:[ChangeModel withRange:range2 documentPath:@""]];

    XCTAssertEqual(controller.changes.count, 1);
}

- (void)testChangeIntersect {
    ChangeController *controller = [ChangeController new];

    NSRange range1 = NSMakeRange(100, 20);
    NSRange range2 = NSMakeRange(45,10);
    NSRange range3 = NSMakeRange(105,30);
    NSRange range4 = NSMakeRange(40,10);

    [controller addChange:[ChangeModel withRange:range1 documentPath:@""]];
    [controller addChange:[ChangeModel withRange:range2 documentPath:@""]];
    [controller addChange:[ChangeModel withRange:range3 documentPath:@""]];
    [controller addChange:[ChangeModel withRange:range4 documentPath:@""]];

    NSMutableArray *changes = controller.changes[@""];
    XCTAssertEqual(controller.changes.count, 2);

    ChangeModel *firstModel = changes.firstObject;
    XCTAssertEqual(firstModel.location, 100);
    XCTAssertEqual(firstModel.length, 35);
}

- (void)testAppendingChange {
    ChangeController *controller = [ChangeController new];

    NSRange range1 = NSMakeRange(1, 1);
    NSRange range2 = NSMakeRange(2, 1);
    NSRange range3 = NSMakeRange(2, 1);

    [controller addChange:[ChangeModel withRange:range1 documentPath:@""]];
    [controller addChange:[ChangeModel withRange:range2 documentPath:@""]];
    [controller addChange:[ChangeModel withRange:range3 documentPath:@""]];

	NSMutableArray *changes = controller.changes[@""];
    XCTAssertEqual(controller.changes.count, 1);
}

@end
