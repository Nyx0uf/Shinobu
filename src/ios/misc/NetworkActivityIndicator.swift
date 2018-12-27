// NetworkActivityIndicator.swift
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


import Foundation
import UIKit


final class NetworkActivityIndicator
{
	// Singletion instance
	static let shared = NetworkActivityIndicator()
	// Queue
	private let _queue: DispatchQueue
	// Number of "operations"
	private var count: Int
	{
		didSet
		{
			DispatchQueue.main.async { [weak self] in
				guard let strongSelf = self else { return }
				UIApplication.shared.isNetworkActivityIndicatorVisible = strongSelf.count > 0
			}
		}
	}

	private init()
	{
		self._queue = DispatchQueue(label: "fr.whine.mpdremote.queue.netact", qos: .default, attributes: [], autoreleaseFrequency: .inherit, target:  nil)
		self.count = 0
	}

	public func start()
	{
		_queue.sync { [weak self] in
			guard let strongSelf = self else { return }
			strongSelf.count += 1
		}
	}

	public func end()
	{
		_queue.sync { [weak self] in
			guard let strongSelf = self else { return }
			var c = strongSelf.count - 1
			if (c < 0)
			{
				c = 0
			}
			strongSelf.count = c
		}
	}

	public func reset()
	{
		_queue.sync { [weak self] in
			guard let strongSelf = self else { return }
			strongSelf.count = 0
		}
	}
}
