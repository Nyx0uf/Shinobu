import Foundation

protocol ThemeProvider {
	associatedtype Theme

	var currentTheme: Theme { get }

	func subscribeToChanges(_ object: AnyObject, handler: @escaping (Theme) -> Void)
}

protocol Themed {
	associatedtype TProvider: ThemeProvider

	var themeProvider: TProvider { get }

	func applyTheme(_ theme: TProvider.Theme)
}

extension Themed where Self: AnyObject {
	func initializeTheming() {
		applyTheme(themeProvider.currentTheme)
		themeProvider.subscribeToChanges(self) { [weak self] (newTheme) in
			self?.applyTheme(newTheme)
		}
	}
}
