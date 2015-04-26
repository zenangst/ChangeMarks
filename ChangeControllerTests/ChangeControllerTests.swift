//
//  ChangeControllerTests.swift
//  ChangeControllerTests
//
//  Created by Christoffer Winterkvist on 20/04/15.
//  Copyright (c) 2015 zenangst. All rights reserved.
//

import Cocoa
import XCTest

class ChangeControllerTests: XCTestCase {

    func testAddChange() {
        let controller = ChangeController()
        let range1 = NSMakeRange(100,20)
        let range2 = NSMakeRange(95,10)

        controller.addChange(ChangeModel(range: range1, documentPath: "testDocument"))
        controller.addChange(ChangeModel(range: range2, documentPath: "testDocument"))

        XCTAssertTrue(controller.changes["testDocument"]?.count == 1)
    }

    func testChangeIntersect() {
        let controller = ChangeController()
        let range1 = NSMakeRange(100,20)
        let range2 = NSMakeRange(45,10)
        let range3 = NSMakeRange(105,30)
        let range4 = NSMakeRange(40,10)

        controller.addChange(ChangeModel(range: range1, documentPath: "testDocument"))
        controller.addChange(ChangeModel(range: range2, documentPath: "testDocument"))
        controller.addChange(ChangeModel(range: range3, documentPath: "testDocument"))
        controller.addChange(ChangeModel(range: range4, documentPath: "testDocument"))

        XCTAssertTrue(controller.changes["testDocument"]?.count == 2)

        let changes = controller.changes["testDocument"]
        XCTAssertTrue(changes!.first!.location == 100)
        XCTAssertTrue(changes!.first!.length == 35)

        XCTAssertTrue(changes!.last!.location == 40)
        XCTAssertTrue(changes!.last!.length == 15)

    }

}
