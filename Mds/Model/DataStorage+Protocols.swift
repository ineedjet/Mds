extension DataStorage: DataReader {
    static var reader: DataReader { instance }
}

extension DataStorage: DataWriter {
    static var writer: DataWriter { instance }
}
