import UIKit
import AVFoundation


final class MessageView: UIView
{
	// MARK: - Public properties
	// Singletion instance
	static let shared = MessageView(frame: .zero)
	// Message label
	var label: UILabel!
	// Image
	var imageView: UIImageView!
	// Visible flag
	private(set) var visible = false
	// Timer (4sec)
	private var timer: DispatchSourceTimer! = nil

	// MARK: - Initializers
	override init(frame f: CGRect)
	{
		let statusHeight: CGFloat
		if let top = UIApplication.shared.keyWindow?.safeAreaInsets.top
		{
			statusHeight = top < 20 ? 20 : top
		}
		else
		{
			statusHeight = 20
		}

		let height = statusHeight + 44
		let frame = CGRect(0, -height, (UIApplication.shared.keyWindow?.frame.width)!, height)

		super.init(frame: frame)
		self.isUserInteractionEnabled = true
		self.isAccessibilityElement = false

		self.imageView = UIImageView(frame: CGRect(8, statusHeight + (40 - 24) / 2, 24, 24))
		self.imageView.isAccessibilityElement = false
		self.addSubview(self.imageView)

		self.label = UILabel(frame: CGRect(self.imageView.maxX + 8, statusHeight + 2, frame.width - self.imageView.maxX - 8, frame.height - statusHeight - 4))
		self.label.textAlignment = .left
		self.label.textColor = .white
		self.label.font = UIFont.boldSystemFont(ofSize: 15)
		self.label.numberOfLines = 2
		self.label.isAccessibilityElement = false
		self.addSubview(self.label)

		APP_DELEGATE().window?.addSubview(self)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - Public
	func showWithMessage(message: Message, animated: Bool = true)
	{
		// Voice over case, speak error
		if UIAccessibility.isVoiceOverRunning
		{
			let utterance = AVSpeechUtterance(string: message.content)
			let synth = AVSpeechSynthesizer()
			synth.speak(utterance)
			return
		}

		if visible
		{
			stopTimer()
		}

		UIView.animate(withDuration: animated ? 0.35 : 0, delay: 0, options: UIView.AnimationOptions(), animations: {
			self.y = 0
			self.label.text = message.content
			switch message.type
			{
				case .error:
					self.backgroundColor = UIColor(red: 0.5807225108, green: 0.066734083, blue: 0, alpha: 1)
					self.imageView.image = #imageLiteral(resourceName: "icon_error").tinted(withColor: .white)
				case .warning:
					self.backgroundColor = UIColor(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
					self.imageView.image = #imageLiteral(resourceName: "icon_warning").tinted(withColor: .white)
				case .information:
					self.backgroundColor = UIColor(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
					self.imageView.image = #imageLiteral(resourceName: "icon_infos").tinted(withColor: .white)
				case .success:
					self.backgroundColor = UIColor(red: 0, green: 0.5603182912, blue: 0, alpha: 1)
					self.imageView.image = #imageLiteral(resourceName: "icon_success").tinted(withColor: .white)
			}
			self.label.backgroundColor = self.backgroundColor
		}, completion: { finished in
			self.visible = true
			self.startTimer(4)
		})
	}

	func hide(_ animated: Bool = true)
	{
		UIView.animate(withDuration: animated ? 0.35 : 0, delay: 0, options: UIView.AnimationOptions(), animations: {
			self.y = -self.height
		}, completion: { finished in
			self.visible = false
		})
	}

	// MARK: - Private
	private func startTimer(_ interval: Int)
	{
		timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: UInt(0)), queue: DispatchQueue.main)
		timer.schedule(deadline: .now() + .seconds(interval))
		timer.setEventHandler {
			self.hide()
		}
		timer.resume()
	}

	private func stopTimer()
	{
		if timer != nil
		{
			timer.cancel()
			timer = nil
		}
	}
}
