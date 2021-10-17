import Foundation

protocol AnyControllerDelegate: AnyObject {
    func controllerDidUpdateMigrationStatus(_ controller: AnyController)
    func controller(_ controller: AnyController, didReportError error: Error)
}

class AnyController: NSObject {
    weak var delegate: AnyControllerDelegate?
}
