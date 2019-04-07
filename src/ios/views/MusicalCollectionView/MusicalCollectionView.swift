import UIKit


final class MusicalCollectionViewFlowLayout : UICollectionViewFlowLayout
{
	private static let margin = CGFloat(12)

	override init()
	{
		super.init()
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	override func prepare()
	{
		super.prepare()

		self.scrollDirection = .vertical
		self.sectionInset = UIEdgeInsets(top: MusicalCollectionViewFlowLayout.margin, left: MusicalCollectionViewFlowLayout.margin, bottom: MusicalCollectionViewFlowLayout.margin, right: MusicalCollectionViewFlowLayout.margin)

		let columns = Settings.shared.integer(forKey: .pref_numberOfColumns)
		guard let collectionView = collectionView else { return }
		let marginsAndInsets = sectionInset.left + sectionInset.right + collectionView.safeAreaInsets.left + collectionView.safeAreaInsets.right + minimumInteritemSpacing * CGFloat(columns - 1)
		let itemWidth = ((collectionView.bounds.size.width - marginsAndInsets) / CGFloat(columns)).rounded(.down)
		self.itemSize = CGSize(width: itemWidth, height: itemWidth + 20)

		let size = try! NSKeyedArchiver.archivedData(withRootObject: NSValue(cgSize: CGSize(itemWidth, itemWidth)), requiringSecureCoding: false)
		Settings.shared.set(size, forKey: .coversSize)
	}

	override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint
	{
		return collectionView?.contentOffset ?? .zero
	}
}

final class MusicalCollectionView : UIView
{
	// MARK: - Public roperties
	// Collection view
	var collectionView = UICollectionView(frame: .zero, collectionViewLayout: MusicalCollectionViewFlowLayout())
	//
	var indexView = TitlesIndexView(frame: .zero)
	// Type of entities displayed
	var musicalEntityType = MusicalEntityType.albums
	{
		didSet
		{
			self.collectionView.register(MusicalEntityBaseCell.self, forCellWithReuseIdentifier: musicalEntityType.cellIdentifier())
			//self.register(MusicalEntityBaseCell.self, forCellWithReuseIdentifier: musicalEntityType.cellIdentifier())
		}
	}

	// MARK: - Initializers
	init(frame: CGRect, musicalEntityType: MusicalEntityType)
	{
		super.init(frame: frame)
		self.backgroundColor = Colors.background

		let widthIndexView = CGFloat(20)
		self.collectionView.frame = CGRect(0, 0, frame.width - widthIndexView, frame.height)
		self.collectionView.backgroundColor = self.backgroundColor
		self.collectionView.isPrefetchingEnabled = false
		self.collectionView.showsVerticalScrollIndicator = false
		self.addSubview(collectionView)

		self.indexView.frame = CGRect(self.collectionView.frame.width, 64, widthIndexView, frame.height - 64)
		self.indexView.backgroundColor = self.backgroundColor
		self.indexView.delegate = self
		self.addSubview(indexView)

		self.musicalEntityType = musicalEntityType
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	func reloadData()
	{
		collectionView.reloadData()
	}

	func setIndexTitles(_ titles: [String], selectedIndex: Int = 0)
	{
		indexView.setTitles(titles, selectedIndex: selectedIndex)
	}

	func setCurrentIndex(_ index: Int)
	{
		indexView.setCurrentIndex(index)
	}

	func updateLayout()
	{
		self.collectionView.collectionViewLayout.invalidateLayout()
		self.collectionView.collectionViewLayout = MusicalCollectionViewFlowLayout()
	}
}

extension MusicalCollectionView : TitlesIndexViewDelegate
{
	func didSelectIndex(_ index: Int)
	{
		collectionView.scrollToItem(at: IndexPath(row: 0, section: index), at: .top, animated: false)
	}

	func didScrollToIndex(_ index: Int)
	{
		collectionView.scrollToItem(at: IndexPath(row: 0, section: index), at: .top, animated: false)
	}
}
