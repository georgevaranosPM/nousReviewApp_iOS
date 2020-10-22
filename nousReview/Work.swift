//
//  Work.swift
//  nous Review
//
//  Created by Γιώργος Βαράνος on 1/2/20.
//  Copyright © 2020 Γιώργος Βαράνος. All rights reserved.
//

import Foundation

class Work: Encodable, Decodable{
    var name:String = ""
    var production:String = ""
    var upload_Date:String = ""
    var fileName:String = ""
    var description:String = ""
    
    init(name: String, production: String, upload_Date: String, fileName: String, description: String) {
            self.name = name
            self.production = production
            self.upload_Date = upload_Date
            self.fileName = fileName
            self.description = description
        }
}
