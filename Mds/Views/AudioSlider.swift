import UIKit

fileprivate let bundle = Bundle(for: AudioSlider.self)

class AudioSlider: UISlider {
    override func awakeFromNib() {
        super.awakeFromNib()
        minimumTrackTintColor = #colorLiteral(red: 0.5568060875, green: 0.5569030643, blue: 0.5739898086, alpha: 1)
        let thumbImage: UIImage
        if #available(iOS 13.0, *) {
            maximumTrackTintColor = UIColor { $0.userInterfaceStyle == .dark ? #colorLiteral(red: 0.2705021739, green: 0.2706485629, blue: 0.270482862, alpha: 1) : #colorLiteral(red: 0.8705021739, green: 0.8706485629, blue: 0.870482862, alpha: 1) }
            thumbImage = UIImage(named: "slider_thumb_ios13.png", in: bundle, with: nil)!
        } else {
            maximumTrackTintColor = #colorLiteral(red: 0.8705021739, green: 0.8706485629, blue: 0.870482862, alpha: 1)
            thumbImage = UIImage(named: "slider_thumb.png", in: bundle, compatibleWith: nil)!
        }
        setThumbImage(thumbImage, for: .normal)
    }
}
