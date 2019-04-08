import UIKit


final class InteractableImageView: UIImageView
{
	// MARK: - Public properties
	// Delegate
	weak var delegate: InteractableImageViewDelegate? = nil

	override init(frame: CGRect)
	{
		super.init(frame: frame)
		self.isUserInteractionEnabled = true

		let singleTap = UITapGestureRecognizer()
		singleTap.numberOfTapsRequired = 1
		singleTap.numberOfTouchesRequired = 1
		singleTap.addTarget(self, action: #selector(singleTap(_:)))
		self.addGestureRecognizer(singleTap)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - Gestures
	@objc func singleTap(_ gesture: UITapGestureRecognizer)
	{
		if gesture.state == .ended
		{
			delegate?.didTap()
		}
	}
}

protocol InteractableImageViewDelegate: class
{
	func didTap()
}
