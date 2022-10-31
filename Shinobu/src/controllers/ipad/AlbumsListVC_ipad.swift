import UIKit

final class AlbumsListVCIPAD: MusicalCollectionVCIPAD {
	// MARK: - Public properties
	// Selected artist
	let artist: Artist
	// Show artist or album artist ?
	let isAlbumArtist: Bool
	// Allowed display types
	override var allowedMusicalEntityTypes: [MusicalEntityType] {
		return [.albums]
	}

	// MARK: - Initializers
	init(artist: Artist, isAlbumArtist: Bool, mpdBridge: MPDBridge) {
		self.artist = artist
		self.isAlbumArtist = isAlbumArtist

		super.init(mpdBridge: mpdBridge)

		dataSource = MusicalCollectionDataSourceAndDelegate(type: .albums, delegate: self, mpdBridge: mpdBridge)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if artist.albums.count <= 0 {
			mpdBridge.getAlbumsForArtist(artist, isAlbumArtist: isAlbumArtist) { [weak self] (albums) in
				DispatchQueue.main.async {
					self?.setItems(albums, forMusicalEntityType: .albums)
					self?.updateNavigationTitle()
				}
			}
		} else {
			DispatchQueue.main.async {
				self.setItems(self.artist.albums, forMusicalEntityType: .albums)
				self.updateNavigationTitle()
			}
		}
	}

	override func updateNavigationTitle() {
		titleView.setMainText(artist.name, detailText: "\(dataSource.items.count) \(dataSource.items.count == 1 ? NYXLocalizedString("lbl_album").lowercased() : NYXLocalizedString("lbl_albums").lowercased())")
	}
}

// MARK: - MusicalCollectionViewDelegate
extension AlbumsListVCIPAD {
	override func didSelectEntity(_ entity: AnyObject) {
		let avc = AlbumDetailVCIPAD(album: entity as! Album, mpdBridge: mpdBridge)
		navigationController?.pushViewController(avc, animated: true)
	}
}
