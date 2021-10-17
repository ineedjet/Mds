extension Collection {
    subscript(optional i: Index) -> Iterator.Element? {
        return self.indices.contains(i) ? self[i] : nil
    }
}

import Foundation

extension RandomAccessCollection where Index == Int {
    /// Returns the difference between two sorted collections.
    /// - Parameters:
    ///   - subtrahend: second collection
    ///   - areEqual: function to determine element equality
    /// - Returns: `nil` if second collection is not a subset of the first one; otherwise the set of indexes of all elements from the first array, not present in the second one.
    /// - Complexity: O(N)
    func subtract<C>(_ subtrahend: C, comparingBy areEqual: (Element, Element) -> Bool) -> IndexSet?
        where C: RandomAccessCollection, C.Element == Element {
        guard self.count >= subtrahend.count else {
            return nil
        }
        var minuendIdx = self.startIndex
        var subtrahendIdx = subtrahend.startIndex
        var difference = IndexSet()
        while minuendIdx < self.endIndex {
            let m = self[minuendIdx]
            if let s = subtrahend[optional: subtrahendIdx], areEqual(m, s) {
                self.formIndex(after: &minuendIdx)
                subtrahend.formIndex(after: &subtrahendIdx)
            }
            else {
                difference.insert(minuendIdx)
                self.formIndex(after: &minuendIdx)
            }
        }
        guard subtrahendIdx == subtrahend.endIndex else {
            return nil
        }
        return difference
    }
}

extension RandomAccessCollection where Element: Equatable, Index == Int {
    /// Returns the difference between two sorted collections.
    /// - Parameters:
    ///   - subtrahend: second collection
    /// - Returns: `nil` if second collection is not a subset of the first one; otherwise the set of indexes of all elements from the first array, not present in the second one.
    /// - Complexity: O(N)
    func subtract<C>(_ subtrahend: C) -> IndexSet?
        where C: RandomAccessCollection, C.Element == Element  {
            return self.subtract(subtrahend) { $0 == $1 }
    }
}


