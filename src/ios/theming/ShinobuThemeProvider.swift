import UIKit


final class ShinobuThemeProvider: ThemeProvider
{
	// MARK: - Singleton instance
	static let shared: ShinobuThemeProvider = .init()

	// MARK: - Private properties
	// Current theme
	private var theme: SubscribableValue<Theme>
	var currentTheme: Theme
	{
		get
		{
			return theme.value
		}
		set
		{
			setNewTheme(newValue)
		}
	}

	// MARK: - Initializers
	init()
	{
		let dark = Settings.shared.bool(forKey: .pref_themeDark)
		theme = SubscribableValue<Theme>(value: dark ? .dark : .light)
	}

	// MARK: - Public
	func subscribeToChanges(_ object: AnyObject, handler: @escaping (Theme) -> Void)
	{
		theme.subscribe(object, using: handler)
	}

	// MARK: - Private
	private func setNewTheme(_ newTheme: Theme)
	{
		self.theme.value = newTheme

		guard let window = UIApplication.shared.delegate?.window! else { return }

		UIView.transition(with: window, duration: 0.3, options: [.transitionCrossDissolve], animations: {
			self.theme.notify()
		}, completion: nil)
	}
}

extension Themed where Self: AnyObject
{
	var themeProvider: ShinobuThemeProvider
	{
		return ShinobuThemeProvider.shared
	}
}
