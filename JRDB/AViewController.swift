//
//  AViewController.swift
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

import UIKit

enum Sex : Int {
    case Man
    case Woman
}

class PPP: NSObject {
    
    var sss : Sex = .Man
    
    var a_int: Int = 0
    var a_int1: Int? = nil
    var b_string: String = "1"
    var b_string1: String! = "2"
    var b_string2: String? = "3"
    var c_nsstring: NSString = "4"
    var c_nsstring1: NSString! = "5"
    var c_nsstring2: NSString? = nil
    
    var d_double: Double = 7
    var e_float: Float = 8
    var f_cgfloat: CGFloat = 9
    
    var g_nsData: NSData = NSData()
    var h_nsDate: NSDate = NSDate()
}

class AViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
//        test()
//        test2()
//        test3()
        
//        JRDBMgr.shareInstance().registerClazzForUpdateTable(PPP)
        let dict = JRReflectUtil.ivarAndEncode4Clazz(PPP)
        
        NSLog("%@", dict)
        
    }
    
    func test3() {
        let p = PPP()
        p.a_int = 1
        print(p.jr_changedArray())
        PPP.jr_findAll()
    }
}
