// AudioOutputsTVC.swift
// Copyright (c) 2017 Nyx0uf
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import UIKit


final class AudioOutputsTVC : UITableViewController
{
	// List of artists
	var outputs = [AudioOutput]()

	// MARK: - Initializers
	init()
	{
		super.init(style: .plain)
	}

	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "fr.whine.mpdremote.cell.audiooutput")
		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		refreshOutputs()
	}

	// MARK: - Private
	private func refreshOutputs()
	{
		PlayerController.shared.getAvailableOutputs {
			self.outputs = PlayerController.shared.outputs
			DispatchQueue.main.async {
				self.tableView.reloadData()
			}
		}
	}
}

// MARK: - UITableViewDataSource
extension AudioOutputsTVC
{
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return outputs.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "fr.whine.mpdremote.cell.audiooutput", for: indexPath)

		let output = outputs[indexPath.row]

		cell.textLabel?.text = output.name
		cell.accessoryType = output.enabled ? .checkmark : .none
		cell.textLabel?.isAccessibilityElement = false
		cell.accessibilityLabel = "\(output.name) \(NYXLocalizedString("lbl_is")) \(NYXLocalizedString(output.enabled ? "lbl_enabled" : "lbl_disabled"))"

		return cell
	}
}

// MARK: - UITableViewDelegate
extension AudioOutputsTVC
{
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		let output = outputs[indexPath.row]

		PlayerController.shared.toggleOutput(output: output, callback: { (success: Bool) in
			if success == true
			{
				self.refreshOutputs()
				NotificationCenter.default.postOnMainThreadAsync(name: .audioOutputConfigurationDidChange, object: nil)
			}
		})
	}
}
