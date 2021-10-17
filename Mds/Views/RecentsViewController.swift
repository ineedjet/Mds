import Foundation

extension Date {
    var mnemonicIntervalString: String {
        let cal = Calendar.current
        let now = Date()
        if cal.isDateInToday(self as Date) {
            return "Сегодня"
        }
        else if cal.isDateInYesterday(self as Date) {
            return "Вчера"
        }
        let daysSince = Calendar.current.dateComponents([.day], from: self as Date, to: now).day!
        if daysSince < 7 {
            return "В последние 7 дней"
        }
        else if daysSince < 30 {
            return "В последние 30 дней"
        }
        else if daysSince < 365 {
            return "В последние 365 дней"
        }
        return "Ранее"
    }
}

class RecentsViewController: TrackListViewController {
    override func viewDidLoad() {
        controller = RecentsController()
        super.viewDidLoad()
    }
}
