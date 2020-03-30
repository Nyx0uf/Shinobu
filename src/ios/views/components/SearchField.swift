import UIKit

protocol SearchFieldDelegate: class {
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
		}
	}
	// MARK: - Private properties
	// Text field
	private let textField = UITextField()

	// MARK: - Initializers
	override init(frame: CGRect) {
		let f = CGRect(frame.origin, frame.width, 44)
		super.init(frame: f)

		let xMargin = CGFloat(8)
		textField.frame = CGRect(xMargin, 0, f.width - xMargin * 2 - f.height, f.height)
		textField.delegate = self
		textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
		self.addSubview(textField)

		cancelButton.frame = CGRect(f.width - f.height, 0, f.height, f.height)
		cancelButton.setImage(#imageLiteral(resourceName: "btn-close").withTintColor(themeProvider.currentTheme.tintColor), for: .normal)
		self.addSubview(cancelButton)

		initializeTheming()
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

extension SearchField: UITextFieldDelegate {
	func textFieldDidBeginEditing(_ textField: UITextField) {
		delegate?.searchFieldTextDidBeginEditing()
	}

	func textFieldDidEndEditing(_ textField: UITextField) {
		delegate?.searchFieldTextDidEndEditing()
	}
}

extension SearchField: Themed {
	func applyTheme(_ theme: Theme) {
		cancelButton.setImage(#imageLiteral(resourceName: "btn-close").withTintColor(theme.tintColor), for: .normal)
		textField.tintColor = theme.tintColor
	}
}
