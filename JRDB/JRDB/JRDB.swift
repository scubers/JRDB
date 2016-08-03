//
//  JRDB.swift
//  JRDB
//
//  Created by JMacMini on 16/7/29.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

import Foundation

public func J_Insert(objs: JRPersistent...) -> JRDBChain {
    return JRDBChain().Insert(objs)
}

public func J_Update(objs: JRPersistent...) -> JRDBChain {
    return JRDBChain().Update(objs)
}

public func J_Delete(objs: JRPersistent...) -> JRDBChain {
    return JRDBChain().Delete(objs)
}

public func J_Select(clazz: AnyClass) -> JRDBChain {
    return JRDBChain().Select([clazz])
}

public func J_Select(cols: String...) -> JRDBChain {
    return JRDBChain().Select(cols)
}

public func J_SelectCount(clazz: AnyClass) -> JRDBChain {
    return JRDBChain().Select([JRCount]).From(clazz)
}

public extension JRDBChain {
    
    public var ParamJ: (String...) -> JRDBChain {
        return {[weak self] col in
            self?.Params(col)
            return self!;
        };
    }
    
    public var ColumnsJ: (String...) -> JRDBChain {
        return {[weak self] col in
            self?.Columns(col)
            return self!;
        };
    }
    
    public var IgnoreJ: (String...) -> JRDBChain {
        return {[weak self] col in
            self?.Ignore(col)
            return self!;
        };
    }
}



