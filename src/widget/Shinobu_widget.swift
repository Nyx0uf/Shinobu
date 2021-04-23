import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
	private var mpdBridge: MPDBridge

	init(mpdBridge: MPDBridge) {
		self.mpdBridge = mpdBridge
	}

	func placeholder(in context: Context) -> SimpleEntry {
		SimpleEntry(date: Date(), track: Track(name: "—", artist: "—", duration: Duration(seconds: 128), trackNumber: 1, uri: "/"), album: Album(name: "—", path: "/", artist: "—", genre: "Rock", year: "2020"))
	}

	func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
		let entry = SimpleEntry(date: Date(), track: Track(name: NYXLocalizedString("widget_track_title"), artist: NYXLocalizedString("lbl_artist"), duration: Duration(seconds: 128), trackNumber: 1, uri: "/"), album: Album(name: NYXLocalizedString("lbl_album"), path: "/", artist: NYXLocalizedString("lbl_artist"), genre: "Rock", year: "2020"))
		completion(entry)
	}

	func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {

		let currentDate = Date()
		let nextDate = Calendar.current.date(byAdding: .second, value: 20, to: currentDate)!

		let track = mpdBridge.getCurrentTrack()
		let album = mpdBridge.getCurrentAlbum()

		let entry1 = SimpleEntry(date: currentDate, track: track, album: album)
		let entry2 = SimpleEntry(date: nextDate, track: track, album: album)

		let timeline = Timeline(entries: [entry1, entry2], policy: .atEnd)

		completion(timeline)
	}
}

struct SimpleEntry: TimelineEntry {
	let date: Date
	let track: Track?
	let album: Album?
}

struct ShinobuWidgetEntryView: View {
	@Environment(\.widgetFamily) private var widgetFamily
	var entry: Provider.Entry
	var mpdBridge: MPDBridge

	var body: some View {
		if widgetFamily == .systemSmall {
			VStack {
				Image(uiImage: getAlbumCover())
					.resizable()
					.scaledToFit()
					.overlay(ImageOverlay(s: getTrackTitle()), alignment: .bottom)
			}
		} else if widgetFamily == .systemMedium {
			HStack(alignment: .center) {
				VStack {
					Image(uiImage: getAlbumCover())
						.resizable()
						.scaledToFit()
				}
				VStack(alignment: .leading) {
					HStack {
						Image(systemName: "music.note")
							.resizable()
							.frame(width: 18, height: 20)
							.foregroundColor(.white)
						Text(getTrackTitle()).font(.system(size: 16)).fontWeight(.light)
							.lineLimit(1)
					}.padding(.bottom, 6)
					HStack {
						Image(systemName: "music.mic")
							.resizable()
							.frame(width: 20, height: 20)
							.foregroundColor(.white)
						Text(getTrackArtist()).font(.system(size: 16)).fontWeight(.medium)
							.lineLimit(1)
					}.padding(.bottom, 6)
					HStack {
						Image(systemName: "music.note.list")
							.resizable()
							.frame(width: 20, height: 20)
							.foregroundColor(.white)
						Text(getAlbumName()).font(.system(size: 16)).fontWeight(.heavy)
							.lineLimit(1)
					}
				}
				Spacer()
			}
		}
	}

	private func getTrackTitle() -> String {
		entry.track?.name ?? "—"
	}

	private func getTrackArtist() -> String {
		entry.track?.artist ?? "—"
	}

	private func getAlbumName() -> String {
		entry.album?.name ?? "—"
	}

	private func getAlbumCover() -> UIImage {
		guard let album = entry.album else { return #imageLiteral(resourceName: "placeholder") }
		guard album.name != "—" && album.path != "/" else { return #imageLiteral(resourceName: "placeholder") }
		if let cover = album.asset(ofSize: .large) {
			return cover
		} else {
			mpdBridge.getPathForAlbum(album) {
				self.downloadCoverForAlbum(album) { (_, _, _) in

				}
			}
			return #imageLiteral(resourceName: "placeholder")
		}
	}

	private func downloadCoverForAlbum(_ album: Album, callback: ((_ large: UIImage?, _ medium: UIImage?, _ small: UIImage?) -> Void)?) {
		var cop = CoverOperations(album: album)
		cop.processCallback = { (large: UIImage?, medium: UIImage?, small: UIImage?) in
			if let block = callback {
				block(large, medium, small)
			}
		}

		cop.submit()
	}
}

struct ImageOverlay: View {
	let s: String
	var body: some View {
		ZStack {
			Text(s)
				.font(.system(size: 14)).bold()
				.padding(4)
				.foregroundColor(.white)
				.lineLimit(1)
				.frame(maxWidth: .infinity)
		}.background(Color.black)
		.opacity(0.9)
	}
}

@main
struct ShinobuWidget: Widget {
	private let kind: String = "ShinobuWidget"
	private var mpdBridge = MPDBridge(usePrettyDB: true, isDirectoryBased: false)

	init() {
		Logger.shared.initialize()

		if let server = ServerManager().getServer() {
			// Data source
			mpdBridge.server = server.mpd
			let resultDataSource = mpdBridge.initialize()
			switch resultDataSource {
			case .failure:
				return
			case .success:
				mpdBridge.entitiesForType(.albums) { (_) in }
			}
		}
	}

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider(mpdBridge: mpdBridge)) { entry in
			ShinobuWidgetEntryView(entry: entry, mpdBridge: mpdBridge)
		}
		.configurationDisplayName("Shinobu")
		.description("Displays the currently playing song")
		.supportedFamilies([.systemSmall, .systemMedium])
	}
}

// struct ShinobuWidgetPreviews: PreviewProvider {
//	static var previews: some View {
//		ShinobuWidgetEntryView(entry: SimpleEntry(date: Date(), trackTitle: "Becoming Insane", albumCover: UIImage(named: "placeholder")))
//			.previewContext(WidgetPreviewContext(family: .systemSmall))
//			.previewDisplayName("Small widget")
//			.environment(\.colorScheme, .dark)
//	}
// }
