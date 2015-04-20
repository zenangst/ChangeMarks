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

}
