import UIKit

extension UIColor {
    static var safeLabel: UIColor {
        if #available(iOS 13.0, *) {
            return .label
        }
        else {
            return .black
        }
    }
    static var safeSecondaryLabel: UIColor {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        }
        else {
            return .gray
        }
    }
    static var safeLink: UIColor {
        if #available(iOS 13.0, *) {
            return .link
        }
        else {
            return #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        }
    }
}

extension UIActivityIndicatorView.Style {
    static var safeMedium: UIActivityIndicatorView.Style {
        if #available(iOS 13.0, *) {
            return .medium
        }
        else {
            return .gray
        }
    }
}
