import UIKit
import Defaults

final class GenreDetailVCIPAD: MusicalCollectionVCIPAD {
	// MARK: - Public properties
	// Selected genre
	let genre: Genre
	// Allowed display types
	override var allowedMusicalEntityTypes: [MusicalEntityType] {
		return [.albums, .artists, .albumsartists]
	}

	// MARK: - Initializers
	init(genre: Genre, mpdBridge: MPDBridge) {
		self.genre = genre

		super.init(mpdBridge: mpdBridge)

		dataSource = MusicalCollectionDataSourceAndDelegate(type: Defaults[.lastTypeGenre], delegate: self, mpdBridge: mpdBridge)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		switch dataSource.musicalEntityType {
		case .albums:
			mpdBridge.getAlbumsForGenre(genre, firstOnly: false) { [weak self] (albums) in
				DispatchQueue.main.async {
					self?.setItems(albums, forMusicalEntityType: self?.dataSource.musicalEntityType ?? .albums)
					self?.updateNavigationTitle()
				}
			}
		case .artists, .albumsartists:
			mpdBridge.getArtistsForGenre(genre, isAlbumArtist: dataSource.musicalEntityType == .albumsartists) { [weak self] (artists) in
				DispatchQueue.main.async {
					self?.setItems(artists, forMusicalEntityType: self?.dataSource.musicalEntityType ?? .artists)
					self?.updateNavigationTitle()
				}
			}
		default:
			break
		}
	}

	override func updateNavigationTitle() {
		var detailText: String?
		let count = dataSource.items.count
		switch dataSource.musicalEntityType {
		case .albums:
			detailText = "\(count) \(count == 1 ? NYXLocalizedString("lbl_album").lowercased() : NYXLocalizedString("lbl_albums").lowercased())"
		case .artists:
			detailText = "\(count) \(count == 1 ? NYXLocalizedString("lbl_artist").lowercased() : NYXLocalizedString("lbl_artists").lowercased())"
		case .albumsartists:
			detailText = "\(count) \(count == 1 ? NYXLocalizedString("lbl_albumartist").lowercased() : NYXLocalizedString("lbl_albumartists").lowercased())"
		default:
			break
		}
		titleView.setMainText(genre.name, detailText: detailText)
	}

	// MARK: - TypeChoiceVCDelegate
	override func didSelectDisplayType(_ type: MusicalEntityType) {
		// Ignore if type did not change
		if dataSource.musicalEntityType == type {
			return
		}

		Defaults[.lastTypeGenre] = type
		switch type {
		case .albums:
			mpdBridge.getAlbumsForGenre(genre, firstOnly: false) { [weak self] (albums) in
				DispatchQueue.main.async {
					self?.setItems(albums, forMusicalEntityType: type)
					self?.updateNavigationTitle()
				}
			}
		case .artists, .albumsartists:
			mpdBridge.getArtistsForGenre(genre, isAlbumArtist: type == .albumsartists) { [weak self] (artists) in
				DispatchQueue.main.async {
					self?.setItems(artists, forMusicalEntityType: type)
					self?.updateNavigationTitle()
				}
			}
		default:
			break
		}
	}
}

// MARK: - MusicalCollectionViewDelegate
extension GenreDetailVCIPAD {
	override func didSelectEntity(_ entity: AnyObject) {
		switch dataSource.musicalEntityType {
		case .albums:
			let avc = AlbumDetailVCIPAD(album: entity as! Album, mpdBridge: mpdBridge)
			navigationController?.pushViewController(avc, animated: true)
		case .artists, .albumsartists:
			let avc = AlbumsListVCIPAD(artist: entity as! Artist, isAlbumArtist: dataSource.musicalEntityType == .albumsartists, mpdBridge: mpdBridge)
				navigationController?.pushViewController(avc, animated: true)
		default:
			break
		}
	}
}
