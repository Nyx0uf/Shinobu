import UIKit


final class InteractableImageView : UIImageView
{
	// MARK: - Public properties
	// Delegate
	weak var delegate: InteractableImageViewDelegate? = nil

	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)

		// Single tap
		let singleTap = UITapGestureRecognizer()
		singleTap.numberOfTapsRequired = 1
		singleTap.numberOfTouchesRequired = 1
		singleTap.addTarget(self, action: #selector(singleTap(_:)))
		self.addGestureRecognizer(singleTap)

		// Swipe left
		/*let leftSwipe = UISwipeGestureRecognizer()
		leftSwipe.direction = .left
		leftSwipe.addTarget(self, action: #selector(swipeLeft(_:)))
		self.addGestureRecognizer(leftSwipe)

		// Swipe right
		let rightSwipe = UISwipeGestureRecognizer()
		rightSwipe.direction = .right
		rightSwipe.addTarget(self, action: #selector(swipeRight(_:)))
		self.addGestureRecognizer(rightSwipe)*/
	}

	// MARK: - Gestures
	@objc func singleTap(_ gesture: UITapGestureRecognizer)
	{
		if gesture.state == .ended
		{
			self.delegate?.didTap()
		}
	}

	/*@objc func swipeLeft(_ gesture: UISwipeGestureRecognizer)
	{
		if gesture.state == .ended
		{
			self.delegate?.didSwipeLeft()
		}
	}

	@objc func swipeRight(_ gesture: UISwipeGestureRecognizer)
	{
		if gesture.state == .ended
		{
			self.delegate?.didSwipeRight()
		}
	}*/
}

protocol InteractableImageViewDelegate : class
{
	func didTap()
	//func didSwipeLeft()
	//func didSwipeRight()
}
