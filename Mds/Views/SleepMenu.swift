import UIKit

fileprivate extension TimeInterval {
    var asTime: String {
        return Int(self).asTime
    }
}

struct SleepMenu {
    private static let options = [1, 5, 10, 15, 30, 45, 60]
    private let viewController: UIViewController

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func display(near view: UIView) {
        let audioPlayer = RealAudioPlayer.shared
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.title = "Таймер сна: \(audioPlayer.sleepTimer?.asTime ?? "Отключен")"
        alert.popoverPresentationController?.sourceView = view
        alert.popoverPresentationController?.sourceRect = view.bounds

        let observationToken = NotificationCenter.default.addObserver(forName: .audioPlayerDidUpdateSleepTimer, object: nil, queue: .main) { _ in
            alert.title = "Таймер сна: \(audioPlayer.sleepTimer?.asTime ?? "Отключен")"
        }

        alert.addAction(UIAlertAction(title: "Отключен", style: .default) { _ in
            NotificationCenter.default.removeObserver(observationToken)
            audioPlayer.sleepTimer = nil
        })

        let remaining = Int((audioPlayer.duration - audioPlayer.position)/60)
        for option in Self.options.filter({$0 <= remaining}).suffix(5) {
            let action = UIAlertAction(title: "Через " + getRussianString(forNumber: option, andNounForms: ("минуту", "минуты", "минут")), style: .default) { _ in
                NotificationCenter.default.removeObserver(observationToken)
                audioPlayer.sleepTimer = TimeInterval(option * 60)
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel) { _ in
            NotificationCenter.default.removeObserver(observationToken)
        })
        viewController.present(alert, animated: true)
    }
}
