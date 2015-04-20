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
        let range1 = NSMakeRange(1,1)
        controller.addChange(ChangeModel(range: range1, documentPath: "testDocument"))


    }

}
