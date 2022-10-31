import UIKit

protocol SearchFieldDelegate: AnyObject {
	func searchFieldTextDidBeginEditing()
	func searchFieldTextDidEndEditing()
	func textDidChange(text: String?)
}

final class SearchField: UIView {
	// MARK: - Public properties
	// Action button
	let cancelButton = UIButton(type: .custom)
	// Delegate
	weak var delegate: SearchFieldDelegate?
	// Textfield empty flag
	private(set) var hasText = false
	// Placeholder wrapper
	public var placeholder: String? {
		get {
			self.textField.placeholder
		}
		set {
			self.textField.placeholder = newValue
			if let s = newValue {
				self.textField.attributedPlaceholder = NSAttributedString(string: s, attributes: [
					.foregroundColor: UIColor.tertiaryLabel,
					.font: UIFont.systemFont(ofSize: 14, weight: .semibold)
				])
			}
		}
	}
	// MARK: - Private properties
	// Text field
	private let textField = UITextField()
	// Glass image
	private let imageView = UIImageView()

	// MARK: - Initializers
	override init(frame: CGRect) {
		let f = CGRect(frame.origin, frame.width, 44)
		super.init(frame: f)

		self.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .systemGroupedBackground

		self.imageView.frame = CGRect(0, 0, f.height, f.height)
		self.imageView.image = #imageLiteral(resourceName: "search-icon").withTintColor(.tertiaryLabel)
		self.imageView.contentMode = .center
		self.addSubview(self.imageView)

		self.textField.frame = CGRect(self.imageView.frame.width, 0, f.width - (2 * f.height), f.height)
		self.textField.delegate = self
		self.textField.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
		self.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
		self.addSubview(self.textField)

		self.cancelButton.frame = CGRect(f.width - f.height, 0, f.height, f.height)
		self.cancelButton.setImage(#imageLiteral(resourceName: "search-clear").withTintColor(UIColor.shinobuTintColor), for: .normal)
		self.addSubview(self.cancelButton)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - Public
	func clearText() {
		textField.text = ""
		textField.sendActions(for: .editingChanged)
	}

	override func becomeFirstResponder() -> Bool {
		textField.becomeFirstResponder()
		return super.becomeFirstResponder()
	}

	// MARK: - Private
	@objc private func textFieldDidChange(textField: UITextField) {
		if let text = textField.text {
			hasText = text.count > 0
		} else {
			hasText = false
		}
		delegate?.textDidChange(text: textField.text)
	}
}

// MARK: - UITextFieldDelegate
extension SearchField: UITextFieldDelegate {
	func textFieldDidBeginEditing(_ textField: UITextField) {
		delegate?.searchFieldTextDidBeginEditing()
	}

	func textFieldDidEndEditing(_ textField: UITextField) {
		delegate?.searchFieldTextDidEndEditing()
	}
}
