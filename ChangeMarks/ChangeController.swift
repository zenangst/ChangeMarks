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
      if let intersectChange = intersect(change) {

        let newRangeLength = intersectChange.location! + intersectChange.length!
        let oldRangeLength = change.location! + change.length!

        if change.location < intersectChange.location {
          intersectChange.location = change.location
        }

        if newRangeLength > oldRangeLength {
          intersectChange.length = newRangeLength - intersectChange.location!
        } else {
          intersectChange.length = oldRangeLength - intersectChange.location!
        }

      } else {
        changes.append(change)
        self.changes[change.documentPath] = changes
      }
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
