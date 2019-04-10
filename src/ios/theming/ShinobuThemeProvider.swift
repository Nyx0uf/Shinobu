import UIKit


final class ShinobuThemeProvider: ThemeProvider
{
	// MARK: - Singleton instance
	static let shared: ShinobuThemeProvider = .init()

	// MARK: - Private properties
	// Current theme
	private var theme: SubscribableValue<ShinobuTheme>

	var currentTheme: ShinobuTheme
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

	init()
	{
		let dark = Settings.shared.bool(forKey: .pref_themeDark)
		theme = SubscribableValue<ShinobuTheme>(value: dark ? .dark : .light)
	}

	private func setNewTheme(_ newTheme: ShinobuTheme)
	{
		self.theme.value = newTheme

		guard let window = UIApplication.shared.delegate?.window! else { return }

		UIView.transition(with: window, duration: 0.3, options: [.transitionCrossDissolve], animations: {
			self.theme.notify()
		}, completion: nil)
	}

	func subscribeToChanges(_ object: AnyObject, handler: @escaping (ShinobuTheme) -> Void)
	{
		theme.subscribe(object, using: handler)
	}
}

extension Themed where Self: AnyObject
{
	var themeProvider: ShinobuThemeProvider
	{
		return ShinobuThemeProvider.shared
	}
}
