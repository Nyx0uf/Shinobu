import SwiftUI

struct ServerView: View {
	// MARK: - Private properties
	/// All outputs
	@State private var availableOutputs = [MPDOutput]()
	/// Selected MPD output
	@State private var selectedOutputName = ""
	/// Zeroconf explorer
	@StateObject private var bonjourExplorer = BonjourExplorer()

	// MARK: - Public properties
	/// Current MPD server
	@ObservedObject var mpdServer: MPDServer

	var body: some View {
		VStack {
			List {
				Section {
					HStack(spacing: 8) {
						Text(NYXLocalizedString("lbl_server_name"))
						Spacer()
						TextField(NYXLocalizedString("lbl_server_name"), text: $mpdServer.name)
							.multilineTextAlignment(.trailing)
							.keyboardType(.default)
							.font(.system(size: 17, weight: .semibold))
					}

					HStack(spacing: 8) {
						Text(NYXLocalizedString("lbl_server_host"))
						Spacer()
						TextField(NYXLocalizedString("lbl_server_host"), text: $mpdServer.hostname, onCommit: {
							updateOutputsLabel()
						})
						.multilineTextAlignment(.trailing)
						.keyboardType(.URL)
						.font(.system(size: 17, weight: .semibold))
					}

					HStack(spacing: 8) {
						Text(NYXLocalizedString("lbl_server_port"))
						Spacer()
						TextField(NYXLocalizedString("lbl_server_port"), value: $mpdServer.port, formatter: NumberFormatter(), onCommit: {
							updateOutputsLabel()
						})
						.multilineTextAlignment(.trailing)
						.keyboardType(.numberPad)
						.font(.system(size: 17, weight: .semibold))
					}

					HStack(spacing: 8) {
						Text(NYXLocalizedString("lbl_server_password"))
						Spacer()
						SecureField(NYXLocalizedString("lbl_server_password"), text: $mpdServer.password)
							.multilineTextAlignment(.trailing)
							.keyboardType(.default)
							.font(.system(size: 17, weight: .semibold))
					}

					HStack(spacing: 8) {
						Text(NYXLocalizedString("lbl_server_output"))
						Spacer()
						Menu {
							ForEach(availableOutputs) { output in
								Button {
									toggleOutput(output)
								} label: {
									Text(output.name)
									if output.isEnabled {
										Image(systemName: "checkmark")
											.foregroundColor(Color(UIColor.shinobuTintColor))
									}
								}
							}
						} label: {
							Text(selectedOutputName)
								.multilineTextAlignment(.trailing)
								.font(.system(size: 17, weight: .semibold))
								.foregroundColor(Color(UIColor.label))
						}
					}
				}
			}
			.listStyle(.grouped)

			Spacer()

			List(Array(bonjourExplorer.services.values)) { server in
				Section(NYXLocalizedString("lbl_nearby_servers")) {
					Button {
						bonjourExplorer.resolve(mpdServerModel: server) { model in
							withAnimation {
								mpdServer.name = model.name
								mpdServer.hostname = model.hostname
								mpdServer.port = model.port
								mpdServer.password = model.password
								mpdServer.id = model.id
								updateOutputsLabel()
							}
						}
					} label: {
						HStack {
							VStack {
								Text(server.name)
									.font(.system(size: 16.0))
									.fontWeight(.semibold)
									.foregroundColor(Color(UIColor.label))

								if String.isNullOrWhiteSpace(server.hostname) == false {
									Text("\(server.hostname):\(String(server.port))")
										.font(.system(size: 14.0))
										.fontWeight(.regular)
										.foregroundColor(Color(UIColor.secondaryLabel))
										.padding(.top, 1)
								}
							}

							if bonjourExplorer.isResolving {
								Spacer()
								Text(NYXLocalizedString("lbl_resolving"))
									.font(.system(size: 14.0))
									.fontWeight(.regular)
									.foregroundColor(Color(UIColor.secondaryLabel))
									.padding(.trailing, 10)
								ProgressView()
							}
						}
					}
				}
			}

		}
		.navigationTitle(NYXLocalizedString("lbl_header_server_cfg"))
		.navigationBarTitleDisplayMode(.inline)
		.onAppear {
			bonjourExplorer.search()

			updateOutputsLabel()
		}
	}

	private func updateOutputsLabel() {
		let cnn = MPDConnection(mpdServer)
		let result = cnn.connect()
		switch result {
		case .failure:
			break
		case .success:
			let res = cnn.getAvailableOutputs()
			switch res {
			case .failure:
				break
			case .success(let outputs):
				if outputs.isEmpty {
					selectedOutputName = NYXLocalizedString("lbl_server_no_output_available")
					return
				}

				self.availableOutputs = outputs

				let enabledOutputs = outputs.filter(\.isEnabled)
				if enabledOutputs.isEmpty {
					selectedOutputName = NYXLocalizedString("lbl_server_no_output_enabled")
					return
				}
				let text = enabledOutputs.reduce("", { $0 + $1.name + ", " })
				let x = text[..<text.index(text.endIndex, offsetBy: -2)]
				selectedOutputName = String(x)
			}
			cnn.disconnect()
		}
	}

	private func toggleOutput(_ output: MPDOutput) {
		guard var o = availableOutputs.first(where: { $0.id == output.id }) else { return }

		let cnn = MPDConnection(mpdServer)
		let result = cnn.connect()
		switch result {
		case .failure:
			break
		case .success:
			let res = cnn.toggleOutput(output)
			switch res {
			case .failure:
				break
			case .success:
				o.isEnabled.toggle()
				updateOutputsLabel()
			}
			cnn.disconnect()
		}
	}
}
