extension MdsTrack {
    func getRecords(_ server: ServerId) -> [MdsRecord] {
        allRecords.filter{$0.server == server}.sorted{$0.partNumber < $1.partNumber}
    }
    func getServersWithSizes() -> [(ServerId, Int64)] {
        var result = [ServerId:Int64]()
        for record in allRecords {
            result[record.server, default: 0] += record.fileSize
        }
        return result.sorted{$0.0.rawValue < $1.0.rawValue}
    }
}
