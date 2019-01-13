// MessageView.swift
// Copyright (c) 2017 Nyx0uf
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import UIKit
import AVFoundation


final class MessageView : UIView
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
	private var _timer: DispatchSourceTimer! = nil

	// MARK: - Initializers
	override init(frame f: CGRect)
	{
		let statusHeight: CGFloat
		if #available(iOS 11, *)
		{
			if let top = UIApplication.shared.keyWindow?.safeAreaInsets.top
			{
				statusHeight = top < 20 ? 20 : top
			}
			else
			{
				statusHeight = 20.0
			}
		}
		else
		{
			statusHeight = 20.0
		}
		let height = statusHeight + 44.0;
		let frame = CGRect(0.0, -height, (UIApplication.shared.keyWindow?.frame.width)!, height)

		super.init(frame: frame)
		self.isUserInteractionEnabled = true
		self.isAccessibilityElement = false

		// Bottom shadow
		self.layer.shadowPath = UIBezierPath(rect: CGRect(-2.0, frame.height - 3.0, frame.width + 4.0, 4.0)).cgPath
		self.layer.shadowRadius = 3.0
		self.layer.shadowOpacity = 0.0
		self.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
		self.layer.masksToBounds = false

		self.imageView = UIImageView(frame: CGRect(8.0, statusHeight + (40 - 24.0) / 2.0, 24.0, 24.0))
		self.imageView.isAccessibilityElement = false
		self.addSubview(self.imageView)

		self.label = UILabel(frame: CGRect(self.imageView.right + 8.0, statusHeight + 2.0, frame.width - self.imageView.right - 8.0, frame.height - statusHeight - 4.0))
		self.label.textAlignment = .left
		self.label.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		self.label.font = UIFont.boldSystemFont(ofSize: 15.0)
		self.label.numberOfLines = 2
		self.label.isAccessibilityElement = false
		self.addSubview(self.label)

		APP_DELEGATE().window?.addSubview(self)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

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

		if self.visible == true
		{
			stopTimer()
		}

		UIView.animate(withDuration: animated ? 0.35 : 0.0, delay: 0.0, options: UIView.AnimationOptions(), animations: {
			self.y = 0.0
			self.layer.shadowOpacity = 1.0
			self.label.text = message.content
			switch message.type
			{
			case .error:
				self.backgroundColor = #colorLiteral(red: 0.5807225108, green: 0.066734083, blue: 0, alpha: 1)
				self.imageView.image = #imageLiteral(resourceName: "icon_error").tinted(withColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
			case .warning:
				self.backgroundColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
				self.imageView.image = #imageLiteral(resourceName: "icon_warning").tinted(withColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
			case .information:
				self.backgroundColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
				self.imageView.image = #imageLiteral(resourceName: "icon_infos").tinted(withColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
			case .success:
				self.backgroundColor = #colorLiteral(red: 0, green: 0.5603182912, blue: 0, alpha: 1)
				self.imageView.image = #imageLiteral(resourceName: "icon_success").tinted(withColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
			}
			self.label.backgroundColor = self.backgroundColor
		}, completion: { finished in
			self.visible = true
			self.startTimer(4)
		})
	}

	func hide(_ animated: Bool = true)
	{
		UIView.animate(withDuration: animated ? 0.35 : 0.0, delay: 0.0, options: UIView.AnimationOptions(), animations: {
			self.y = -self.height
			self.layer.shadowOpacity = 0.0
		}, completion: { finished in
			self.visible = false
		})
	}

	// MARK: - Private
	private func startTimer(_ interval: Int)
	{
		_timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: UInt(0)), queue: DispatchQueue.main)
		_timer.schedule(deadline: .now() + .seconds(interval))
		_timer.setEventHandler {
			self.hide()
		}
		_timer.resume()
	}

	private func stopTimer()
	{
		if _timer != nil
		{
			_timer.cancel()
			_timer = nil
		}
	}
}
