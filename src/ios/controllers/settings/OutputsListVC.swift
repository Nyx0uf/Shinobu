import UIKit

final class OutputsListVC: NYXTableViewController {
	// MARK: - Private properties
	// List of outputs available
	private var outputs = [MPDOutput]()
	// Cell identifier
	private let cellIdentifier = "fr.whine.shinobu.cell.audiooutput"
	// MPD server
	private let mpdServer: MPDServer

	// MARK: - Initializers
	init(mpdServer: MPDServer) {
		self.mpdServer = mpdServer

		super.init(style: .plain)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.tintColor = themeProvider.currentTheme.tintColor
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		tableView.tableFooterView = UIView()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		refreshOutputs()
	}

	// MARK: - Private
	private func refreshOutputs() {
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
				self.outputs = outputs
				tableView.reloadData()
			}
			cnn.disconnect()
		}
	}

	private func handleEmptyView(tableView: UITableView, isEmpty: Bool) {
		if isEmpty {
			let emptyView = UIView(frame: tableView.bounds)
			emptyView.translatesAutoresizingMaskIntoConstraints = false
			emptyView.backgroundColor = tableView.backgroundColor

			let lbl = UILabel(frame: .zero)
			lbl.text = NYXLocalizedString("lbl_no_outputs")
			lbl.font = UIFont.systemFont(ofSize: 16, weight: .ultraLight)
			lbl.translatesAutoresizingMaskIntoConstraints = false
			lbl.tintColor = .label
			lbl.sizeToFit()
			emptyView.addSubview(lbl)
			lbl.x = ceil((emptyView.width - lbl.width) / 2)
			lbl.y = ceil((emptyView.height - lbl.height) / 2)

			tableView.backgroundView = emptyView
			tableView.separatorStyle = .none
		} else {
			tableView.backgroundView = nil
			tableView.separatorStyle = .singleLine
		}
	}
}

// MARK: - UITableViewDataSource
extension OutputsListVC {
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		handleEmptyView(tableView: tableView, isEmpty: outputs.isEmpty)
		return outputs.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)

		let output = outputs[indexPath.row]

		cell.textLabel?.text = output.name
		cell.textLabel?.textColor = .label
		cell.textLabel?.highlightedTextColor = themeProvider.currentTheme.tintColor
		cell.accessoryType = output.isEnabled ? .checkmark : .none
		cell.textLabel?.isAccessibilityElement = false
		cell.accessibilityLabel = "\(output.name) \(NYXLocalizedString("lbl_is")) \(NYXLocalizedString(output.isEnabled ? "lbl_enabled" : "lbl_disabled"))"

		let view = UIView()
		view.backgroundColor = themeProvider.currentTheme.tintColor.withAlphaComponent(0.2)
		cell.selectedBackgroundView = view

		return cell
	}
}

// MARK: - UITableViewDelegate
extension OutputsListVC {
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		var output = outputs[indexPath.row]

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
				output.isEnabled.toggle()
				outputs[indexPath.row] = output
				tableView.reloadRows(at: [indexPath], with: .fade)
				NotificationCenter.default.postOnMainThreadAsync(name: .audioOutputConfigurationDidChange, object: nil)
			}
			cnn.disconnect()
		}
	}
}

extension OutputsListVC: Themed {
	func applyTheme(_ theme: Theme) {
	}
}
