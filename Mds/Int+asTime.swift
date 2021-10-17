extension Int {
    var asTime: String {
        let h = self/3600
        let m = (self%3600)/60
        let s = self%60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}
