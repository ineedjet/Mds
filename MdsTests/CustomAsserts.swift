import XCTest
@testable import Mds

fileprivate func prependIfNotEmpty(_ s: String, with prefix: String) -> String {
    if s == "" {
        return s
    }
    return prefix + s
}

fileprivate extension Collection where Element: Hashable {
    func mergeRepeating() -> [Element] {
        var answer = [Element]()
        for item in self {
            if answer.last != item {
                answer.append(item)
            }
        }
        return answer
    }
}

func XCTAssertDownloadState(_ left: DownloadState, _ right: DownloadState, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    let message = "states are not equal: \(left) and \(right)" + prependIfNotEmpty(message(), with: " - ")
    switch right {
    case .notDownloaded:
        guard case .notDownloaded = left else {
            XCTFail(message, file: file, line: line)
            return
        }
        break
    case let .corrupted(rightSize):
        guard case let .corrupted(leftSize) = left else {
            XCTFail(message, file: file, line: line)
            return
        }
        XCTAssertEqual(leftSize, rightSize, message, file: file, line: line)
        break
    case .preparing:
        guard case .preparing = left else {
            XCTFail(message, file: file, line: line)
            return
        }
        break
    case let .incomplete(rightServer, rightProgress):
        guard case let .incomplete(leftServer, leftProgress) = left else {
            XCTFail(message, file: file, line: line)
            return
        }
        XCTAssertEqual(leftServer, rightServer, message, file: file, line: line)
        XCTAssertEqual(leftProgress.fractionCompleted, rightProgress.fractionCompleted, message, file: file, line: line)
        break
    case let .downloading(rightServer, rightProgress):
        guard case let .downloading(leftServer, leftProgress) = left else {
            XCTFail("states are not equal: \(left) and \(right)" + prependIfNotEmpty(message, with: " - "), file: file, line: line)
            return
        }
        XCTAssertEqual(leftServer, rightServer, message, file: file, line: line)
        XCTAssertEqual(leftProgress.fractionCompleted, rightProgress.fractionCompleted, message, file: file, line: line)
        break
    case let .downloaded(rightServer, rightSize):
        guard case let .downloaded(leftServer, leftSize) = left else {
            XCTFail(message, file: file, line: line)
            return
        }
        XCTAssertEqual(leftServer, rightServer, message, file: file, line: line)
        XCTAssertEqual(leftSize, rightSize, message, file: file, line: line)
        break
    }
}

func XCTAssertDownloadItems(_ left: [DownloadItem], _ right: [DownloadItem], file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(left.count, right.count, "[DownloadItem] length", file: file, line: line)
    guard left.count == right.count else {
        return
    }
    for i in 0..<left.count {
        XCTAssertEqual(left[i].trackId, right[i].trackId, "TrackId of DownloadItem [\(i)]", file: file, line: line)
        XCTAssertDownloadState(left[i].state, right[i].state, "State of DownloadItem [\(i)]", file: file, line: line)
    }
}

func XCTAssertSet<T>(_ left: Set<T>,
                     _ right: Set<T>,
                     _ fieldName: StaticString? = nil,
                     file: StaticString = #file,
                     line: UInt = #line) {
    XCTAssertEqual(left.count, right.count, "\(fieldName?.description ?? "Set<\(T.self)>") count", file: file, line: line)
    for item in right {
        func getErrorText() -> String {
            if let fieldName = fieldName {
                return "\"\(item)\" is missing from \(fieldName)"
            }
            else {
                return "\(T.self) \"\(item)\" is missing"
            }
        }
        XCTAssert(left.contains(item), getErrorText(), file: file, line: line)
    }
}

func XCTAssertEqual(_ left: [(sections: IndexSet, rows: [IndexPath])],
                    _ right: [(sections: [Int], rows: [IndexPath])],
                    _ fieldName: StaticString,
                    file: StaticString = #file,
                    line: UInt = #line) {
    XCTAssertEqual(left.count, right.count, "Item count of \(fieldName)", file: file, line: line)
    guard left.count == right.count else {
        return
    }
    for i in 0..<left.count {
        let (leftSections, leftRows) = left[i]
        let (rightSections, rightRows) = right[i]
        XCTAssertEqual(leftSections, IndexSet(rightSections), "Sections of \(fieldName)[\(i)]", file: file, line: line)
        XCTAssertEqual(leftRows, rightRows, "Rows of \(fieldName)[\(i)]", file: file, line: line)
    }
}

func XCTAssertEqual(_ left: [(at: IndexPath, to: IndexPath)],
                    _ right: [(at: IndexPath, to: IndexPath)],
                    _ fieldName: StaticString,
                    file: StaticString = #file,
                    line: UInt = #line) {
    XCTAssertEqual(left.count, right.count, "Item count of \(fieldName)", file: file, line: line)
    guard left.count == right.count else {
        return
    }
    for i in 0..<left.count {
        let (leftAt, leftTo) = left[i]
        let (rightAt, rightTo) = right[i]
        XCTAssertEqual(leftAt, rightAt, "at of \(fieldName)[\(i)]", file: file, line: line)
        XCTAssertEqual(leftTo, rightTo, "to of \(fieldName)[\(i)]", file: file, line: line)
    }
}

func XCTAssert(_ target: TrackListControllerBase,
               headerField: HeaderField,
               visibleCount: Int,
               data: [String? : [MdsTrack]],
               orderedKeys: [String?],
               extractTitle: (String?) -> String,
               extractIndex: ((String?) -> String)?,
               titleMatchesIndex: (String?, String) -> Bool,
               file: StaticString = #file,
               line: UInt = #line) {
    XCTAssertEqual(orderedKeys.count, data.keys.count, "`orderedKeys` is inconsistent with `data`", file: file, line: line)
    XCTAssertEqual(target.headerField, headerField, "`headerField`", file: file, line: line)
    XCTAssertEqual(target.visibleTracks, visibleCount, "`visibleCount`", file: file, line: line)

    XCTAssertEqual(target.numberOfSections(), data.keys.count, "`numberOfsections()`", file: file, line: line)
    for i in 0..<data.keys.count {
        let tracksInSection = data[orderedKeys[i]]!
        XCTAssertEqual(target.titleForHeader(inSection: i), extractTitle(orderedKeys[i]), "`titleForHeader(inSection: \(i))`", file: file, line: line)
        XCTAssertEqual(target.numberOfRows(inSection: i), tracksInSection.count, "`numberOfRows(inSection: \(i))`", file: file, line: line)
        for j in 0..<tracksInSection.count {
            XCTAssertEqual(target[IndexPath(row: j, section: i)]?.trackId, tracksInSection[j].trackId, "Track at indexpath (row: \(j), section: \(i))", file: file, line: line)
        }
    }

    guard let extractIndex = extractIndex else {
        XCTAssertNil(target.sectionIndexTitles(), "`sectionIndexTitles()`", file: file, line: line)
        return
    }

    guard let targetIndexTitles = target.sectionIndexTitles() else {
        XCTAssertNotNil(nil, "`sectionIndexTitles()`", file: file, line: line)
        return
    }
    XCTAssertEqual(targetIndexTitles, orderedKeys.map(extractIndex).mergeRepeating(), "`sectionIndexTitles()`", file: file, line: line)
    var nextSection = 0
    for (i,indexTitle) in targetIndexTitles.enumerated() {
        XCTAssertEqual(target.section(forSectionIndexTitle: indexTitle, at: i), nextSection,
                       "`section(forSectionIndexTitle: \"\(indexTitle)\", at: \(i))`", file: file, line: line)
        nextSection += orderedKeys.dropFirst(nextSection).prefix{titleMatchesIndex($0, indexTitle)}.count
    }
}
