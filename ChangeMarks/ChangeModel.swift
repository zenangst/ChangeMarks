//
//  ChangeModel.swift
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 20/04/15.
//  Copyright (c) 2015 zenangst. All rights reserved.
//

import Foundation

class ChangeModel {

    var location: Int?
    var length: Int?
    var documentPath: String

    init(range: NSRange, documentPath path: String) {
        location = range.location
        length = range.length
        documentPath = path
    }

}
