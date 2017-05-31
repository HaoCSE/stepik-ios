//
//  CodeTemplate.swift
//  Stepic
//
//  Created by Ostrenkiy on 30.05.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

class CodeTemplate: NSManagedObject {
    
    convenience required init(json: JSON) {
        self.init()
        initialize(json)
    }
    
    func initialize(_ json: JSON) {
    }
    
    func update(json: JSON) {
        initialize(json)
    }
    
}
