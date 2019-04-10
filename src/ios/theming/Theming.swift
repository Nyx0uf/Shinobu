import Foundation


protocol ThemeProvider
{
	associatedtype Theme

	var currentTheme: Theme { get }

	func subscribeToChanges(_ object: AnyObject, handler: @escaping (Theme) -> Void)
}

protocol Themed
{
	associatedtype _ThemeProvider: ThemeProvider

	var themeProvider: _ThemeProvider { get }

	func applyTheme(_ theme: _ThemeProvider.Theme)
}

extension Themed where Self: AnyObject
{
	func initializeTheming()
	{
		applyTheme(themeProvider.currentTheme)
		themeProvider.subscribeToChanges(self) { [weak self] (newTheme) in
			self?.applyTheme(newTheme)
		}
	}
}
