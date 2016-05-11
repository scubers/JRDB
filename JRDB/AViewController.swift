//
//  AViewController.swift
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

import UIKit

class PPP: NSObject, JRPersistent {
    var a_int: Int = 0
    var b_string: String = "1"
    var b_string1: String! = "2"
    var b_string2: String? = "3"
    var c_nsstring: NSString = "4"
    var c_nsstring1: NSString! = "5"
    var c_nsstring2: NSString? = "6"
    
    var d_double: Double = 7
    var e_float: Float = 8
    var f_cgfloat: CGFloat = 9
    
    var _ID: String! = ""
    
    
    func setID(ID: String!) {
        _ID = ID
    }
    func ID() -> String! {
        return _ID
    }
    
}

class AViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let p = PPP()
//        FMDatabase *db = [[JRDBMgr shareInstance] createDBWithPath:@"/Users/jmacmini/Desktop/aaa.sqlite"];
        let db = JRDBMgr.shareInstance().DBWithPath("/Users/jmacmini/Desktop/aaa.sqlite");
        db .saveObj(p)
        
        
    }
}
