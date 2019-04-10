import UIKit


final class AudioOutputsListVC: NYXTableViewController
{
	// MARK - Public properties
	// List of artists
	var outputs = [AudioOutput]()

	// MARK - Private properties
	// Cell identifier
	private let cellIdentifier = "fr.whine.shinobu.cell.audiooutput"
	// MPD server
	private let mpdServer: MPDServer

	// MARK: - Initializers
	init(mpdServer: MPDServer)
	{
		self.mpdServer = mpdServer

		super.init(style: .plain)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

		initializeTheming()
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		refreshOutputs()
	}

	// MARK: - Private
	private func refreshOutputs()
	{
		let cnn = MPDConnection(mpdServer)
		let result = cnn.connect()
		switch result
		{
			case .failure( _):
				break
			case .success( _):
				let r = cnn.getAvailableOutputs()
				switch r
				{
					case .failure( _):
						break
					case .success(let outputs):
						self.outputs = outputs
						tableView.reloadData()
				}
				cnn.disconnect()
		}
	}
}

// MARK: - UITableViewDataSource
extension AudioOutputsListVC
{
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return outputs.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
		cell.backgroundColor = themeProvider.currentTheme.backgroundColorAlt
		cell.contentView.backgroundColor = themeProvider.currentTheme.backgroundColorAlt

		let output = outputs[indexPath.row]

		cell.textLabel?.text = output.name
		cell.textLabel?.textColor = themeProvider.currentTheme.tableCellMainLabelTextColor
		cell.accessoryType = output.enabled ? .checkmark : .none
		cell.textLabel?.isAccessibilityElement = false
		cell.accessibilityLabel = "\(output.name) \(NYXLocalizedString("lbl_is")) \(NYXLocalizedString(output.enabled ? "lbl_enabled" : "lbl_disabled"))"

		return cell
	}
}

// MARK: - UITableViewDelegate
extension AudioOutputsListVC
{
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		let output = outputs[indexPath.row]

		let cnn = MPDConnection(mpdServer)
		let result = cnn.connect()
		switch result
		{
			case .failure( _):
				break
			case .success( _):
				let r = cnn.toggleOutput(output)
				switch r
				{
					case .failure( _):
						break
					case .success( _):
						refreshOutputs()
						NotificationCenter.default.postOnMainThreadAsync(name: .audioOutputConfigurationDidChange, object: nil)
				}
				cnn.disconnect()
		}
	}
}

extension AudioOutputsListVC: Themed
{
	func applyTheme(_ theme: ShinobuTheme)
	{
		tableView.separatorColor = theme.backgroundColor
		tableView.backgroundColor = theme.backgroundColorAlt
		tableView.tintColor = theme.tintColor
	}
}
