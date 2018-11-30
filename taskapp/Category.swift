//
//  Category.swift
//  taskapp
//
//  Created by 久保田慧 on 2018/11/14.
//  Copyright © 2018年 KeiKubota. All rights reserved.
//

import RealmSwift

class Category: Object{

@objc dynamic var id = 0
@objc dynamic var categoryName = ""
    
/**
id をプライマリーキーとして設定
*/
    override static func primaryKey() -> String? {
        return "id"
    }
}

