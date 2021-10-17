func <<T>(_ a: T?, _ b: T?) -> Bool where T: Comparable {
    guard let a = a else {
        return b != nil // if a == nil && b != nil { return true }
                        // if a == nil && b == nil { return false }
    }
    guard let b = b else {
        return false    // if a != nil && b == nil { return false }
    }
    return a < b        // if a != nil && b != nil { return a < b }
}

func ><T>(_ a: T?, _ b: T?) -> Bool where T: Comparable {
    guard let a = a else {
        return false     // if a == nil && b != nil { return false }
                         // if a == nil && b == nil { return false }
    }
    guard let b = b else {
        return true      // if a != nil && b == nil { return true }
    }
    return a > b         // if a != nil && b != nil { return a > b }
}
