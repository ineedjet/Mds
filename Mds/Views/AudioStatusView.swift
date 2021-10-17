import UIKit

fileprivate let nibName = "AudioStatusView"
fileprivate let bundle = Bundle(for: AudioStatusView.self)

enum AudioStatusViewAction {
    case play
    case pause
    case sleepMenu(near: UIView)
    case scrollToPosition(TimeInterval)
    case highlightTrack(MdsTrack)
}

protocol AudioStatusViewDelegate: AnyObject {
    func audioStatusView(didRequest action: AudioStatusViewAction)
}

@IBDesignable
class AudioStatusView: UIView, UIGestureRecognizerDelegate {
    private var view: UIView!
    @IBOutlet var slider: UISlider!
    @IBOutlet var label: UILabel!
    @IBOutlet var centerLabel: UILabel!
    @IBOutlet var button: UIButton!
    @IBOutlet var sleepButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var elapsedTimeLabel: UILabel!
    @IBOutlet var remainingTimeLabel: UILabel!

    weak var delegate: AudioStatusViewDelegate?

    var playerState: AudioPlayerState = .idle {
        willSet {
            switch newValue {
            case .idle, .error:
                label.text = " "
                centerLabel.textColor = #colorLiteral(red: 0.4901509881, green: 0.4902249575, blue: 0.4901347756, alpha: 1)
                centerLabel.text = "Не исполняется"
                button.isEnabled = false
                button.isHidden = false
                sleepButton.isHidden = true
                slider.isHidden = true
                activityIndicator.stopAnimating()
                elapsedTimeLabel.isHidden = true
                remainingTimeLabel.isHidden = true
            case let .selected(track, _):
                label.text = " "
                centerLabel.textColor = .safeLabel
                centerLabel.text = track.trackTitle
                setButtonImage(.play)
                button.isEnabled = true
                button.isHidden = false
                sleepButton.isHidden = true
                slider.isHidden = true
                activityIndicator.stopAnimating()
                elapsedTimeLabel.isHidden = true
                remainingTimeLabel.isHidden = true
            case let .playing(track):
                label.text = track.trackTitle
                centerLabel.text = nil
                setButtonImage(.pause)
                button.isEnabled = true
                button.isHidden = false
                sleepButton.isEnabled = true
                sleepButton.isHidden = false
                slider.isHidden = false
                activityIndicator.stopAnimating()
                elapsedTimeLabel.isHidden = false
                remainingTimeLabel.isHidden = false
            case let .paused(track):
                label.text = track.trackTitle
                centerLabel.text = nil
                setButtonImage(.play)
                button.isEnabled = true
                button.isHidden = false
                sleepButton.isEnabled = true
                sleepButton.isHidden = false
                slider.isHidden = false
                activityIndicator.stopAnimating()
                elapsedTimeLabel.isHidden = false
                remainingTimeLabel.isHidden = false
            case let .preparing(track):
                label.text = " "
                centerLabel.textColor = .safeLabel
                centerLabel.text = track.trackTitle
                button.isHidden = true
                sleepButton.isHidden = true
                slider.isHidden = true
                activityIndicator.startAnimating()
                elapsedTimeLabel.isHidden = true
                remainingTimeLabel.isHidden = true
            case let .loading(track):
                label.text = " "
                centerLabel.textColor = .safeLabel
                centerLabel.text = track.trackTitle
                button.isHidden = true
                sleepButton.isHidden = true
                slider.isHidden = true
                activityIndicator.startAnimating()
                elapsedTimeLabel.isHidden = true
                remainingTimeLabel.isHidden = true
            }
        }
    }

    private var isDragging: Bool = false

    var playerPosition: TimeInterval = 0 {
        didSet {
            if !isDragging {
                slider.value = Float(playerPosition)
                sliderValueChanged()
            }
        }
    }

    var playerDuration: TimeInterval = 0 {
        didSet {
            slider.maximumValue = Float(playerDuration)
            sliderValueChanged()
        }
    }

    var sleepTimerEnabled: Bool = false {
        didSet {
            if sleepTimerEnabled != oldValue {
                sleepButton.tintColor = sleepTimerEnabled ? .safeLink : .safeLabel
                sleepButton.accessibilityValue = sleepTimerEnabled ? "Включен" : "Отключен"
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }

    private func xibSetup() {
        let nib = UINib(nibName: nibName, bundle: bundle)
        view = (nib.instantiate(withOwner: self, options: nil).first as! UIView)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)

        backgroundColor = .clear

        setButtonImage(.playpause, for: .disabled)
        setSleepButtonImage()
        sleepTimerEnabled = false
        activityIndicator.style = .safeMedium
        playerState = .idle
    }

    private enum ButtonImage {
        case play
        case pause
        case playpause
    }

    private func setButtonImage(_ image: ButtonImage, for state: UIControl.State = .normal) {
        let img: UIImage?
        let accessibilityText: String
        switch image {
        case .play:
            accessibilityText = "Играть"
        case .pause:
            accessibilityText = "Пауза"
        case .playpause:
            accessibilityText = "Играть/Пауза"
        }
        if #available(iOS 13.0, *) {
            let symbolName: String
            switch image {
            case .play:
                symbolName = "play.fill"
            case .pause:
                symbolName = "pause.fill"
            case .playpause:
                symbolName = "playpause.fill"
            }
            img = UIImage(systemName: symbolName, withConfiguration: UIImage.SymbolConfiguration(scale: .large))
        }
        else {
            let imageName: String
            switch image {
            case .play:
                imageName = "play_button"
            case .pause:
                imageName = "pause_button"
            case .playpause:
                imageName = "play-pause_button"
            }
            img = UIImage(named: imageName, in: bundle, compatibleWith: nil)
        }
        button.setImage(img, for: state)
        button.accessibilityLabel = accessibilityText
    }

    private func setSleepButtonImage() {
        let img: UIImage?
        if #available(iOS 13.0, *) {
            img = UIImage(systemName: "moon.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .medium))
        }
        else {
            img = UIImage(named: "sleep_button", in: bundle, compatibleWith: nil)
        }
        sleepButton.setImage(img, for: .normal)
    }

    override func prepareForInterfaceBuilder() {
        label.text = "Открытка"
        setButtonImage(.pause)
        button.isHidden = false
        sleepButton.isHidden = true
        slider.isHidden = false
        centerLabel.text = nil
        elapsedTimeLabel.text = "3:41"
        elapsedTimeLabel.isHidden = false
        remainingTimeLabel.text = "-36:15"
        remainingTimeLabel.isHidden = false
    }

    @IBAction func buttonTapped() {
        switch playerState {
        case .paused, .selected:
            delegate?.audioStatusView(didRequest: .play)
        case .playing:
            delegate?.audioStatusView(didRequest: .pause)
        default:
            break
        }
    }

    @IBAction func sleepButtonTapped() {
        switch playerState {
        case .paused, .playing:
            delegate?.audioStatusView(didRequest: .sleepMenu(near: sleepButton))
        default:
            break
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let p = touch.location(in: self)
        if !slider.isHidden && slider.frame.insetBy(dx: -10, dy: -10).contains(p) {
            return false
        }
        return true
    }

    @IBAction func viewTapped() {
        switch playerState {
        case .preparing(let t), .loading(let t), .playing(let t), .paused(let t), .selected(let t, _):
            delegate?.audioStatusView(didRequest: .highlightTrack(t))
        case .error, .idle:
            break
        }
    }

    @IBAction func sliderValueChanged() {
        let elapsedTime = Int(slider.value)
        let remainingTime = Int(playerDuration - Double(slider.value))
        elapsedTimeLabel.text = elapsedTime.asTime
        remainingTimeLabel.text = "-" + remainingTime.asTime
    }

    @IBAction func startDraggingSlider() {
        isDragging = true
    }

    @IBAction func stopDraggingSlider() {
        isDragging = false
        delegate?.audioStatusView(didRequest: .scrollToPosition(Double(slider.value)))
    }
}
