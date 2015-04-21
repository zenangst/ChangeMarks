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
            let intersectChange = intersect(change)

            println(intersectChange?.location)
            println(intersectChange?.length)
            println(change.location);
            println(change.length);

            if intersectChange?.location < change.location {
                change.location = intersectChange?.location
            }

            println(change.location)

//            oldChanges.append(change)
//            changes[change.documentPath] = oldChanges
        } else {
            changes[change.documentPath] = [change]
        }
    }

    func intersect(change: ChangeModel) -> ChangeModel? {
        var changes: [ChangeModel] = self.changes[change.documentPath]!
        for oldChange in changes {
            let a = NSMakeRange(change.location!, change.length!);
            let b = NSMakeRange(oldChange.location!, oldChange.length!);
            let intersection = NSIntersectionRange(a, b);

            if intersection.location > 0 && intersection.length > 0 {
                return oldChange
            }
        }

        return nil
    }

}
