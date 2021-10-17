import UIKit

class MigrationViewController {
    private var alert: UIViewController?

    func present(in parentViewController: UIViewController) {
        guard self.alert == nil else {
            return
        }
        let alert = UIAlertController(title: "Пожалуйста подождите", message: "Идет обновление настроек...", preferredStyle: .alert)
        parentViewController.present(alert, animated: true)
        self.alert = alert
    }

    func dismiss() {
        self.alert?.dismiss(animated: true)
        self.alert = nil
    }
}
