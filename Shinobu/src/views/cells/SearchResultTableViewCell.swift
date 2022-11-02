import UIKit

final class SearchResultTableViewCell: UITableViewCell, ReuseIdentifying {
	// MARK: - Public properties
	/// Image
	private(set) var imgView = UIImageView()
	/// Track title
	private(set) var lblTitle = UILabel()
	/// Play button callback
	var buttonAction: (() -> Void) = {}
	/// Match background to even/odd cell index
	var isEvenCell = false {
		didSet {
			self.contentView.backgroundColor = isEvenCell ? UIColor(rgb: 0x121212) : .black
		}
	}
	// MARK: - Private properties
	/// Selected bg color
	private var overlayView = UIView()
	/// Play button
	private var btnPlay = UIButton(type: .custom)

	// MARK: - Initializers
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)

		self.backgroundColor = .black
		self.contentView.backgroundColor = .black
		self.selectionStyle = .none

		self.contentView.addSubview(self.imgView)
		self.imgView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate(
			[
				self.imgView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
				self.imgView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
				self.imgView.widthAnchor.constraint(equalToConstant: 38),
				self.imgView.heightAnchor.constraint(equalToConstant: 38)
			]
		)
		self.imgView.isAccessibilityElement = false
		self.imgView.contentMode = .scaleAspectFit
		self.imgView.layer.cornerRadius = 4
		self.imgView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		self.imgView.clipsToBounds = true

		self.contentView.addSubview(self.btnPlay)
		self.btnPlay.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate(
			[
				self.btnPlay.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
				self.btnPlay.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8),
				self.btnPlay.widthAnchor.constraint(equalToConstant: 38),
				self.btnPlay.heightAnchor.constraint(equalToConstant: 38)
			]
		)
		let imgPlay = UIImage(systemName: "play.circle")!
		self.btnPlay.setImage(imgPlay.withTintColor(.white).withRenderingMode(.alwaysOriginal), for: .normal)
		self.btnPlay.setImage(imgPlay.withTintColor(UIColor.shinobuTintColor).withRenderingMode(.alwaysOriginal), for: .selected)
		self.btnPlay.setImage(imgPlay.withTintColor(UIColor.shinobuTintColor).withRenderingMode(.alwaysOriginal), for: .highlighted)
		self.btnPlay.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)

		self.contentView.addSubview(self.lblTitle)
		self.lblTitle.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate(
			[
				self.lblTitle.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
				self.lblTitle.leadingAnchor.constraint(equalTo: self.imgView.trailingAnchor, constant: 8),
				self.lblTitle.trailingAnchor.constraint(equalTo: self.btnPlay.leadingAnchor, constant: -8)
			]
		)
		self.lblTitle.font = UIFont.systemFont(ofSize: 14, weight: .regular)
		self.lblTitle.textAlignment = .left
		self.lblTitle.textColor = .label
		self.lblTitle.numberOfLines = 2
		self.lblTitle.highlightedTextColor = UIColor.shinobuTintColor

		self.overlayView.translatesAutoresizingMaskIntoConstraints = false
		self.overlayView.backgroundColor = UIColor.shinobuTintColor.withAlphaComponent(0.2)
		self.overlayView.isAccessibilityElement = false
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)

		lblTitle.isHighlighted = selected
		imgView.isHighlighted = selected

		if selected {
			if overlayView.superview == nil {
				contentView.addSubview(overlayView)
				NSLayoutConstraint.activate(
					[
						overlayView.topAnchor.constraint(equalTo: contentView.topAnchor),
						overlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
						overlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
						overlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
					]
				)
			}
		} else {
			overlayView.removeFromSuperview()
		}
	}

	override func setHighlighted(_ highlighted: Bool, animated: Bool) {
		super.setHighlighted(highlighted, animated: animated)

		lblTitle.isHighlighted = highlighted
		imgView.isHighlighted = highlighted

		if highlighted {
			if overlayView.superview == nil {
				contentView.addSubview(overlayView)
				NSLayoutConstraint.activate(
					[
						overlayView.topAnchor.constraint(equalTo: contentView.topAnchor),
						overlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
						overlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
						overlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
					]
				)
			}
		} else {
			overlayView.removeFromSuperview()
		}
	}

	// MARK: - Private
	@objc private func buttonPressed(_ sender: UIButton) {
		buttonAction()
	}
}
