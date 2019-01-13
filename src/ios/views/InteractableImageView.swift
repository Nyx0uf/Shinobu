// InteractableImageView.swift
// Copyright (c) 2017 Nyx0uf
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


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
