import Foundation


extension Array
{
	func randomItem() -> Element
	{
		return self[Int(arc4random_uniform(UInt32(count)))]
	}
}

extension Array where Element: Equatable
{
	mutating func removeObject(object: Element)
	{
		if let index = index(of: object)
		{
			self.remove(at: index)
		}
	}
}
