//
//  AViewController.swift
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

import UIKit

class PPP: NSObject {
    var a_int: Int = 0
    var a_intq: Int! = 1
    var a_int2: Int? = 2
    var b_string: String = ""
    var b_string1: String! = ""
    var b_string2: String? = ""
    var c_nsstring: NSString = ""
    var c_nsstring1: NSString! = ""
    var c_nsstring2: NSString? = ""
    
    var d_double: Double = 0
    var d_double1: Double! = 0
    var d_double2: Double? = 0
    
}

class AViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let p = PPP()
        p.a_int = 1
        
        p.setValue(10, forKey: "a_int")
        print(p.valueForKey("a_int"))
        
        
        let arr = JRReflectUtil.ivarAndEncode4Clazz(PPP.self)
        print(arr)
    }
}
