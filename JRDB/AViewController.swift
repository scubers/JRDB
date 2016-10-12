//
//  AViewController.swift
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

import UIKit

enum Sex : Int {
    case man
    case woman
}

class AAA: NSObject {
    var type: String?
    deinit {
        print("\(self) deinit")
    }
}

class PPP: AAA {
    
    var sss : Sex = .man
    
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
    
    var g_nsData: Data = Data()
    var h_nsDate: Date = Date()
    
    var ccc: CCC?
    var ccc1: CCC?
    
    var ppp: PPP?
    
//    override static func jr_singleLinkedPropertyNames() -> [String : AnyObject.Type]? {
//        return [
//            "ccc" : CCC.self,
//            "ccc1" : CCC.self,
//            "ppp" : PPP.self,
//        ]
//    }
}

class CCC: NSObject {
    var serialNumber: String = ""
    weak var ppp: PPP?
    
//    override static func jr_singleLinkedPropertyNames() -> [String : AnyObject.Type]? {
//        return [
//            "ppp" : PPP.self,
//        ]
//    }
    
    deinit {
        print("\(self) deinit")
    }
}

class AViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let db = JRDBMgr.shareInstance().createDB(withPath: "/Users/mac/Desktop/test.sqlite")
        JRDBMgr.shareInstance().defaultDB = db
        
//        test1Cycle()
//        testFindByID()
//        testThreeNodeCycle()
//        test2Node1Cycle()
//        truncateTable()
    }
    
    func test2Node1Cycle() {
        let p = PPP()
        let p1 = PPP()
        let c = CCC()
        
        p.ppp = p1
        p1.ccc = c
        c.ppp = p1
        
        p.jr_save()
    }
    
    func testThreeNodeCycle() {
        let p1 = PPP()
        let p2 = PPP()
        let p3 = PPP()
        
        p1.ppp = p2
        p2.ppp = p3
        p3.ppp = p1
        
        p1.jr_save()
    }
  
    func test1Cycle() {
        let p = PPP()
        let c = CCC()
        p.ccc = c
        c.ppp = p

        p.jr_save()
        
    }
    
    func testFindByID() {
        let p = PPP.jr_find(byID: "FBE5701E-ECBB-494A-BE62-7C7114C780A1")
        p?.isEqual(nil);
    }

    
    func truncateTable() {
        PPP.jr_truncateTable()
        CCC.jr_truncateTable()
    }
    
}
