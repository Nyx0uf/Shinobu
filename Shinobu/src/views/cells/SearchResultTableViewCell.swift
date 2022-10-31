import UIKit

private let marginFromCell = CGFloat(8)
private let marginFromRounded = CGFloat(7)
private let btnSize = CGFloat(24)
private let cellHeight = CGFloat(54)
private let imageViewSize = CGFloat(40)

final class SearchResultTableViewCell: UITableViewCell, ReuseIdentifying {
	// MARK: - Public properties
	// Image
	private(set) var imgView = UIImageView()
	// Disclosure indicator
	private(set) var imgDisclosure = UIImageView()
	// Track title
	private(set) var lblTitle = UILabel()
	// Play button callback
	var buttonAction: (() -> Void) = {}
	// Match background to even/odd cell index
	var isEvenCell = false {
		didSet {
			if traitCollection.userInterfaceStyle == .dark {
				roundedView.backgroundColor = isEvenCell ? UIColor(rgb: 0x121212) : .black
			} else {
				roundedView.backgroundColor = isEvenCell ? .secondarySystemGroupedBackground : .systemGroupedBackground
			}
		}
	}
	// MARK: - Private properties
	// Rounded view
	private var roundedView = UIView()
	// Selected bg color
	private var overlayView = UIView()
	// Play button
	private var btnPlay = CellButtonPlay(type: .custom)

	// MARK: - Initializers
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)

		self.backgroundColor = .clear
		self.contentView.backgroundColor = .clear
		self.selectionStyle = .none

		self.roundedView.frame = CGRect(marginFromCell, 0, UIScreen.main.bounds.width - 2 * marginFromCell, cellHeight)
		self.roundedView.layer.cornerRadius = 10
		self.roundedView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		self.roundedView.clipsToBounds = true
		self.contentView.addSubview(self.roundedView)

		self.imgView.frame = CGRect(marginFromRounded, marginFromRounded, imageViewSize, imageViewSize)
		self.imgView.contentMode = .center
		self.imgView.layer.cornerRadius = 4
		self.imgView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		self.imgView.clipsToBounds = true
		self.roundedView.addSubview(self.imgView)

		self.imgDisclosure = UIImageView(image: #imageLiteral(resourceName: "cell-disclosure").withTintColor(.secondaryLabel), highlightedImage: #imageLiteral(resourceName: "cell-disclosure").withTintColor(UIColor.shinobuTintColor))
		self.roundedView.addSubview(self.imgDisclosure)

		self.btnPlay.frame = CGRect(.zero, btnSize, btnSize)
		self.btnPlay.bgColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.1)
		self.btnPlay.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.1)
		self.btnPlay.selectedBackgroundColor = UIColor.shinobuTintColor.withAlphaComponent(0.2)
		self.btnPlay.circleize()
		self.btnPlay.setImage(#imageLiteral(resourceName: "search-cell-play").withTintColor(.secondaryLabel), for: .normal)
		self.btnPlay.setImage(#imageLiteral(resourceName: "search-cell-play").withTintColor(UIColor.shinobuTintColor), for: .selected)
		self.btnPlay.setImage(#imageLiteral(resourceName: "search-cell-play").withTintColor(UIColor.shinobuTintColor), for: .highlighted)
		self.btnPlay.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
		self.roundedView.addSubview(self.btnPlay)

		self.lblTitle.frame = CGRect(imgView.maxX + 8, 0, (roundedView.width - 16 - imgView.maxX), cellHeight)
		self.lblTitle.font = UIFont.systemFont(ofSize: 14, weight: .regular)
		self.lblTitle.textAlignment = .left
		self.lblTitle.textColor = .label
		self.lblTitle.highlightedTextColor = UIColor.shinobuTintColor
		self.roundedView.addSubview(self.lblTitle)

		self.overlayView.frame = self.roundedView.frame
		self.overlayView.layer.cornerRadius = 10
		self.overlayView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		self.overlayView.clipsToBounds = true
		self.overlayView.backgroundColor = UIColor.shinobuTintColor.withAlphaComponent(0.2)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIView overrides
	override func layoutSubviews() {
		super.layoutSubviews()

		roundedView.frame = CGRect(marginFromCell, 0, width - 2 * marginFromCell, cellHeight)
		overlayView.frame = roundedView.bounds

		let marginLbl = CGFloat(10)
		imgView.frame = CGRect(marginFromRounded, marginFromRounded, imageViewSize, imageViewSize)
		imgDisclosure.frame = CGRect((roundedView.width - imgDisclosure.width - marginFromRounded), (cellHeight - imgDisclosure.height) / 2, imgDisclosure.size).ceilled()
		btnPlay.frame = CGRect((imgDisclosure.x - btnSize - marginLbl), (cellHeight - btnSize) / 2, btnSize, btnSize).ceilled()
		lblTitle.frame = CGRect(imgView.maxX + marginLbl, 0, (btnPlay.x - imgView.maxX - 2 * marginLbl), cellHeight).ceilled()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)

		lblTitle.isHighlighted = selected
		imgDisclosure.isHighlighted = selected
		imgView.isHighlighted = selected

		if selected && overlayView.superview == nil {
			roundedView.insertSubview(overlayView, belowSubview: imgView)
		} else {
			overlayView.removeFromSuperview()
		}
	}

	override func setHighlighted(_ highlighted: Bool, animated: Bool) {
		super.setHighlighted(highlighted, animated: animated)

		lblTitle.isHighlighted = highlighted
		imgDisclosure.isHighlighted = highlighted
		imgView.isHighlighted = highlighted

		if highlighted && overlayView.superview == nil {
			roundedView.insertSubview(overlayView, belowSubview: imgView)
		} else {
			overlayView.removeFromSuperview()
		}
	}

	// MARK: - Private
	@objc private func buttonPressed(_ sender: UIButton) {
		buttonAction()
	}
}

fileprivate final class CellButtonPlay: UIButton {
	// MARK: - Public properties
	// Selected & Highlighted color
	var selectedBackgroundColor = UIColor.clear
	// Background color
	var bgColor: UIColor?

	override var isSelected: Bool {
		willSet {
			if self.isSelected {
				self.backgroundColor = self.selectedBackgroundColor
			} else {
				self.backgroundColor = self.bgColor
			}
		}

		didSet {
			if self.isSelected {
				self.backgroundColor = self.selectedBackgroundColor
			} else {
				self.backgroundColor = self.bgColor
			}
		}
	}

	override var isHighlighted: Bool {
		willSet {
			if self.isHighlighted {
				self.backgroundColor = self.selectedBackgroundColor
			} else {
				self.backgroundColor = self.bgColor
			}
		}

		didSet {
			if self.isHighlighted {
				self.backgroundColor = self.selectedBackgroundColor
			} else {
				self.backgroundColor = self.bgColor
			}
		}
	}
}
