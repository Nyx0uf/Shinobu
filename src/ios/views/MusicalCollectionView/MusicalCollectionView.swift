import UIKit

final class MusicalCollectionViewFlowLayout: UICollectionViewFlowLayout {
	private static let margin = CGFloat(12)

	override init() {
		super.init()
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	override func prepare() {
		super.prepare()

		scrollDirection = .vertical
		sectionInset = UIEdgeInsets(top: MusicalCollectionViewFlowLayout.margin, left: MusicalCollectionViewFlowLayout.margin, bottom: MusicalCollectionViewFlowLayout.margin, right: MusicalCollectionViewFlowLayout.margin)

		let columns = Settings.shared.integer(forKey: .pref_numberOfColumns)
		guard let collectionView = collectionView else { return }
		let marginsAndInsets = sectionInset.left + sectionInset.right + collectionView.safeAreaInsets.left + collectionView.safeAreaInsets.right + minimumInteritemSpacing * CGFloat(columns - 1)
		let itemWidth = ((collectionView.bounds.size.width - marginsAndInsets) / CGFloat(columns)).rounded(.down)
		itemSize = CGSize(width: itemWidth, height: itemWidth + 20)

		Settings.shared.set(Int(itemWidth), forKey: .coversSize)
	}

	override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
		return collectionView?.contentOffset ?? .zero
	}
}

final class MusicalCollectionView: UIView {
	// MARK: - Public roperties
	// Collection view
	var collectionView = UICollectionView(frame: .zero, collectionViewLayout: MusicalCollectionViewFlowLayout())
	//
	var indexView = TitlesIndexView(frame: .zero)
	// Type of entities displayed
	var musicalEntityType = MusicalEntityType.albums {
		didSet {
			self.collectionView.register(MusicalEntityCollectionViewCell.self, forCellWithReuseIdentifier: musicalEntityType.cellIdentifier())
		}
	}

	// MARK: - Initializers
	init(frame: CGRect, musicalEntityType: MusicalEntityType) {
		super.init(frame: frame)

		self.backgroundColor = .systemGroupedBackground

		let widthIndexView = CGFloat(20)
		self.collectionView.frame = CGRect(0, 0, frame.width - widthIndexView, frame.height)
		self.collectionView.isPrefetchingEnabled = false
		self.collectionView.showsVerticalScrollIndicator = false
		self.collectionView.backgroundColor = self.backgroundColor
		self.addSubview(collectionView)

		self.indexView.frame = CGRect(self.collectionView.frame.width, 64, widthIndexView, frame.height - 64)
		self.indexView.backgroundColor = self.backgroundColor
		self.indexView.delegate = self
		self.addSubview(indexView)

		self.musicalEntityType = musicalEntityType

		initializeTheming()
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	func reloadData() {
		collectionView.reloadData()
	}

	func setIndexTitles(_ titles: [String], selectedIndex: Int = 0) {
		indexView.setTitles(titles, selectedIndex: selectedIndex)
	}

	func setCurrentIndex(_ index: Int) {
		indexView.setCurrentIndex(index)
	}

	func updateLayout() {
		collectionView.collectionViewLayout.invalidateLayout()
		collectionView.collectionViewLayout = MusicalCollectionViewFlowLayout()
	}
}

extension MusicalCollectionView: TitlesIndexViewDelegate {
	func didSelectIndex(_ index: Int) {
		collectionView.scrollToItem(at: IndexPath(row: 0, section: index), at: .top, animated: false)
	}

	func didScrollToIndex(_ index: Int) {
		collectionView.scrollToItem(at: IndexPath(row: 0, section: index), at: .top, animated: false)
	}
}

extension MusicalCollectionView: Themed {
	func applyTheme(_ theme: Theme) {
		collectionView.reloadData()
	}
}
