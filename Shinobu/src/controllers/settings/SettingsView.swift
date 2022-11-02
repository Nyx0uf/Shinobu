import SwiftUI
import Defaults

struct SettingsView: View {
	// MARK: - Private properties
	/// Show confirmation alert view
	@State private var showingAlert = false

	// MARK: - Public properties
	/// Number of columns
	@Default(.pref_numberOfColumns) var numberOfColumns
	/// Directory browsing
	@Default(.pref_browseByDirectory) var browseByDirectory
	/// Shake to play random
	@Default(.pref_shakeToPlayRandom) var shakeToPlayRandom
	/// Fuzzy search
	@Default(.pref_fuzzySearch) var fuzzySearch
	/// MPD server
	@ObservedObject var mpdServerModel: MPDServer
	/// Dismiss callback from UIKit
	var dismissAction: (() -> Void)

	// MARK: - Initializer
	init(dismissAction: @escaping (() -> Void)) {
		self.dismissAction = dismissAction
		self.mpdServerModel = ServerManager().getServer()
	}

	var body: some View {
		NavigationView {
			VStack {
				List {
					Section(header: Text("MPD")) {
						NavigationLink(destination: ServerView(mpdServerModel: mpdServerModel), label: {
							HStack(spacing: 8) {
								Image(systemName: "server.rack")
								Text(mpdServerModel.name)
							}
						})
					}

					Section(header: Text(NYXLocalizedString("lbl_pref_appearance").uppercased())) {
						HStack(spacing: 8) {
							Image(systemName: "number")
							Text(NYXLocalizedString("lbl_pref_columns"))
							Spacer()
							Picker(NYXLocalizedString("lbl_pref_columns"), selection: $numberOfColumns) {
								Text(UIDevice.current.isPad() ? "4" : "2").tag(UIDevice.current.isPad() ? 4 : 2)
								Text(UIDevice.current.isPad() ? "5" : "3").tag(UIDevice.current.isPad() ? 5 : 3)
							}
							.pickerStyle(.segmented)
							.frame(width: 88)
						}
					}

					Section(header: Text(NYXLocalizedString("lbl_behaviour").uppercased())) {
						HStack(spacing: 8) {
							Image(systemName: "folder")
							Toggle(NYXLocalizedString("lbl_pref_browse_by_dir"), isOn: $browseByDirectory)
						}

						HStack(spacing: 8) {
							Image(systemName: "shuffle")
							Toggle(NYXLocalizedString("lbl_pref_shaketoplayrandom"), isOn: $shakeToPlayRandom)
								.disabled(browseByDirectory == true)
						}
					}

					Section(header: Text(NYXLocalizedString("lbl_search").uppercased())) {
						HStack(spacing: 8) {
							Image(systemName: "magnifyingglass")
							Toggle(NYXLocalizedString("lbl_fuzzysearch"), isOn: $fuzzySearch)
						}
					}

					Section {
						HStack(spacing: 8) {
							Spacer()

							SwiftUI.Button {
								showingAlert = true
							} label: {
								Label(NYXLocalizedString("lbl_server_coverclearcache"), systemImage: "clear")
									.foregroundColor(.red)
							}
							.alert(NYXLocalizedString("lbl_alert_purge_cache_title"), isPresented: $showingAlert, actions: {
								SwiftUI.Button(NYXLocalizedString("lbl_cancel"), role: .cancel) { }
								SwiftUI.Button(NYXLocalizedString("lbl_ok"), role: .destructive) {
									ImageCache.shared.clear { (_) in }
								}
							}, message: {
								Text(NYXLocalizedString("lbl_alert_purge_cache_msg"))
							})

							Spacer()
						}
					}
				}
				.listStyle(.grouped)

				Spacer()

				HStack {
					Spacer()

					Text(version())
						.font(.system(size: 18))
						.fontWeight(.light)
						.foregroundColor(Color(UIColor.secondaryLabel))
						.multilineTextAlignment(.center)

					Spacer()
				}
			}
			.navigationTitle(NYXLocalizedString("lbl_section_settings"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					SwiftUI.Button(action: dismissAction) {
						Text(NYXLocalizedString("lbl_close"))
					}
				}
			}
		}
		.onDisappear {
			ServerManager().handleServer(mpdServerModel)
			NotificationCenter.default.postOnMainThreadAsync(name: .audioServerConfigurationDidChange, object: mpdServerModel)
		}
	}

	// MARK: - Private methods
	private func version() -> String {
		guard let dic = Bundle.main.infoDictionary else { return "v1.0.0" }

		return "v\(dic["CFBundleShortVersionString"] as! String)"
	}
}
