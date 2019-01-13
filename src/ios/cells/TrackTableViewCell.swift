// TrackTableViewCell.swift
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


final class TrackTableViewCell : UITableViewCell
{
	// MARK: - Public properties
	// Track number
	@IBOutlet private(set) var lblTrack: UILabel!
	// Track title
	@IBOutlet private(set) var lblTitle: UILabel!
	// Track duration
	@IBOutlet private(set) var lblDuration: UILabel!
	// Separator
	@IBOutlet private(set) var separator: UIView!

	// MARK: - Initializers
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?)
	{
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		self.contentView.backgroundColor = self.backgroundColor

		self.lblTrack = UILabel()
		self.lblTrack.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		self.lblTrack.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		self.lblTrack.font = UIFont(name: "HelveticaNeue-Bold", size: 10.0)
		self.lblTrack.textAlignment = .center
		self.contentView.addSubview(self.lblTrack)
		self.lblTrack.translatesAutoresizingMaskIntoConstraints = false
		self.lblTrack.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8.0).isActive = true
		self.lblTrack.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 15.0).isActive = true
		self.lblTrack.heightAnchor.constraint(equalToConstant: 14.0).isActive = true
		self.lblTrack.widthAnchor.constraint(equalToConstant: 18.0).isActive = true

		self.lblDuration = UILabel()
		self.lblDuration.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		self.lblDuration.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		self.lblDuration.font = UIFont(name: "HelveticaNeue-Light", size: 10.0)
		self.lblDuration.textAlignment = .right
		self.contentView.addSubview(self.lblDuration)
		self.lblDuration.translatesAutoresizingMaskIntoConstraints = false
		self.lblDuration.heightAnchor.constraint(equalToConstant: 14.0).isActive = true
		self.lblDuration.widthAnchor.constraint(equalToConstant: 32.0).isActive = true
		self.lblDuration.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 15.0).isActive = true
		self.lblDuration.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8.0).isActive = true

		self.lblTitle = UILabel()
		self.lblTitle.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		self.lblTitle.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		self.lblTitle.font = UIFont(name: "HelveticaNeue-Medium", size: 14.0)
		self.lblTitle.textAlignment = .left
		self.contentView.addSubview(self.lblTitle)
		self.lblTitle.translatesAutoresizingMaskIntoConstraints = false
		self.lblTitle.leadingAnchor.constraint(equalTo: self.lblTrack.trailingAnchor, constant: 8.0).isActive = true
		self.lblTitle.trailingAnchor.constraint(equalTo: self.lblDuration.leadingAnchor, constant: 8.0).isActive = true
		self.lblTitle.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 13.0).isActive = true
		self.lblTitle.heightAnchor.constraint(equalToConstant: 18.0).isActive = true

		self.separator = UIView()
		self.separator.backgroundColor = UIColor(rgb: 0xE4E4E4)
		self.contentView.addSubview(self.separator)
		self.separator.translatesAutoresizingMaskIntoConstraints = false
		self.separator.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8.0).isActive = true
		self.separator.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8.0).isActive = true
		self.separator.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 0.0).isActive = true
		self.separator.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
	}

	override func setSelected(_ selected: Bool, animated: Bool)
	{
		super.setSelected(selected, animated: animated)

		if selected
		{
			backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		}
		else
		{
			backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		}
		contentView.backgroundColor = backgroundColor
		lblTitle.backgroundColor = backgroundColor
		lblDuration.backgroundColor = backgroundColor
		lblTrack.backgroundColor = backgroundColor
	}

	override func setHighlighted(_ highlighted: Bool, animated: Bool)
	{
		super.setHighlighted(highlighted, animated: animated)

		if highlighted
		{
			backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		}
		else
		{
			backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		}
		contentView.backgroundColor = backgroundColor
		lblTitle.backgroundColor = backgroundColor
		lblDuration.backgroundColor = backgroundColor
		lblTrack.backgroundColor = backgroundColor
	}
}
