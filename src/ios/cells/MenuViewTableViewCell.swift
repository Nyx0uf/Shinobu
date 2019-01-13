// MenuViewTableViewCell.swift
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


final class MenuViewTableViewCell : UITableViewCell
{
	// MARK: - Public properties
	// Section image
	private(set) var ivLogo: UIImageView!
	// Section label
	private(set) var lblSection: UILabel!

	// MARK: - Initializers
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?)
	{
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.backgroundColor = #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 0)
		self.isAccessibilityElement = true
		self.selectionStyle = .none
		self.layoutMargins = .zero

		let logoSize = CGSize(96.0, 96.0)
		self.ivLogo = UIImageView(frame: CGRect(48.0, (128.0 - logoSize.height) * 0.5, logoSize))
		self.contentView.addSubview(self.ivLogo)

		self.lblSection = UILabel(frame: CGRect(0.0, 0.0, logoSize.width + 32.0, 32.0))
		self.lblSection.font = UIFont.systemFont(ofSize: 14.0)
		self.contentView.addSubview(self.lblSection)
	}

	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder:aDecoder)
		self.backgroundColor = #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 0)
		self.isAccessibilityElement = true
		self.selectionStyle = .none
		self.layoutMargins = .zero

		let logoSize = CGSize(96.0, 96.0)
		self.ivLogo = UIImageView(frame: CGRect(48.0, (128.0 - logoSize.height) * 0.5, logoSize))
		self.contentView.addSubview(self.ivLogo)

		self.lblSection = UILabel(frame: CGRect(0.0, 0.0, logoSize.width + 32.0, 32.0))
		self.lblSection.font = UIFont.systemFont(ofSize: 14.0)
		self.contentView.addSubview(self.lblSection)
	}
}
