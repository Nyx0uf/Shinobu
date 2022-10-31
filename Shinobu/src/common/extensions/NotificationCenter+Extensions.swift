import Foundation

extension NotificationCenter {
	func postOnMainThreadAsync(name aName: NSNotification.Name, object anObject: Any?) {
		DispatchQueue.main.async { [weak self] in
			self?.post(name: aName, object: anObject)
		}
	}

	func postOnMainThreadAsync(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable: Any]? = nil) {
		DispatchQueue.main.async { [weak self] in
			self?.post(name: aName, object: anObject, userInfo: aUserInfo)
		}
	}
}
