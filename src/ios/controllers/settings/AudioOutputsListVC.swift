import UIKit


final class AudioOutputsListVC : NYXTableViewController
{
	// List of artists
	var outputs = [AudioOutput]()
	// Cell identifier
	private let cellIdentifier = "fr.whine.shinobu.cell.audiooutput"
	//
	private let mpdServer: MPDServer

	// MARK: - Initializers
	init(mpdServer: MPDServer)
	{
		self.mpdServer = mpdServer
		super.init(style: .plain)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		tableView.separatorColor = Colors.background
		tableView.backgroundColor = Colors.backgroundAlt
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		refreshOutputs()
	}

	// MARK: - Private
	private func refreshOutputs()
	{
		let cnn = MPDConnection(self.mpdServer)
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
						self.tableView.reloadData()
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
		cell.backgroundColor = Colors.backgroundAlt
		cell.contentView.backgroundColor = Colors.backgroundAlt

		let output = outputs[indexPath.row]

		cell.textLabel?.text = output.name
		cell.textLabel?.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
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

		let cnn = MPDConnection(self.mpdServer)
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
						self.refreshOutputs()
						NotificationCenter.default.postOnMainThreadAsync(name: .audioOutputConfigurationDidChange, object: nil)
				}
				cnn.disconnect()
		}
	}
}
