//
//  JRDB.swift
//  JRDB
//
//  Created by JMacMini on 16/7/29.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

import Foundation

func J_Insert(objs: JRPersistent...) -> JRDBChain {
    return JRDBChain().Insert(objs)
}

func J_Update(objs: JRPersistent...) -> JRDBChain {
    return JRDBChain().Update(objs)
}

func J_Delete(objs: JRPersistent...) -> JRDBChain {
    return JRDBChain().Delete(objs)
}

func J_Select(clazz: AnyClass) -> JRDBChain {
    return JRDBChain().Select([clazz])
}

func J_Select(cols: String...) -> JRDBChain {
    return JRDBChain().Select(cols)
}

func J_SelectCount(clazz: AnyClass) -> JRDBChain {
    return JRDBChain().Select([JRCount]).From(clazz)
}

extension JRDBChain {
    
    var ParamJ: (String...) -> JRDBChain {
        return {[weak self] col in
            self?.Params(col)
            return self!;
        };
    }
    
    var ColumnsJ: (String...) -> JRDBChain {
        return {[weak self] col in
            self?.Columns(col)
            return self!;
        };
    }
    
    var IgnoreJ: (String...) -> JRDBChain {
        return {[weak self] col in
            self?.Ignore(col)
            return self!;
        };
    }
}



