//
//  ChangeController.swift
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 20/04/15.
//  Copyright (c) 2015 zenangst. All rights reserved.
//

import Foundation

public class ChangeController {

    public lazy var changes: Dictionary<String, [ChangeModel]> = {
        return [:]
    }()

    func addChange(change: ChangeModel) {
        if var changes = changes[change.documentPath] {
            let intersectRange = intersect(change)

            if (intersectRange.location > 0 && intersectRange.location > 0) {
                
            }

//            oldChanges.append(change)
//            changes[change.documentPath] = oldChanges
        } else {
            changes[change.documentPath] = [change]
        }
    }

    func intersect(change: ChangeModel) -> NSRange {
        var changes: [ChangeModel] = self.changes[change.documentPath]!
        for oldChange in changes {
            let a = NSMakeRange(change.location!, change.length!);
            let b = NSMakeRange(oldChange.location!, oldChange.length!);
            let intersection = NSIntersectionRange(a, b);

            if intersection.location > 0 && intersection.length > 0 {
                return intersection
            }
        }

        return NSMakeRange(0,0)
    }

}
