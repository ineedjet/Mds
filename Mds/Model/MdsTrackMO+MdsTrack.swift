extension MdsTrackMO: MdsTrack {
    var trackAuthor: String { author! }
    var trackTitle: String { title! }
    var allRecords: [MdsRecord] {
        guard let records = records else {
            return []
        }
        return records.map{$0 as! MdsRecordMO}
    }
}
