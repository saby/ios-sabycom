//
//  Weak.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 28.09.2021.
//

import Foundation

class Weak<T> {
    
    fileprivate weak var _value: AnyObject?
    
    init (value: T) {
       self._value = value as AnyObject
    }
    
    
    var value: T? {
        return _value as? T
    }
}


func ===<T>(lhs: Weak<T>, rhs: Weak<T>) -> Bool {
    return lhs._value === rhs._value
}


func ===<T>(lhs: Weak<T>, rhs: T) -> Bool {
    return lhs._value === rhs as AnyObject
}


func ===<T>(lhs: T, rhs: Weak<T>) -> Bool {
    return lhs as AnyObject === rhs._value
}


func !==<T>(lhs: Weak<T>, rhs: Weak<T>) -> Bool {
    return lhs._value !== rhs._value
}


func !==<T>(lhs: Weak<T>, rhs: T) -> Bool {
    return lhs._value !== rhs as AnyObject
}


func !==<T>(lhs: T, rhs: Weak<T>) -> Bool {
    return lhs as AnyObject !== rhs._value
}


extension Weak where T: Equatable {
    static func ==(lhs: Weak<T>, rhs: Weak<T>) -> Bool {
        return lhs.value == rhs.value
    }
    
    
    static func ==(lhs: Weak<T>, rhs: T) -> Bool {
        return lhs.value == rhs
    }
    
    
    static func ==(lhs: T, rhs: Weak<T>) -> Bool {
        return lhs == rhs.value
    }
}
