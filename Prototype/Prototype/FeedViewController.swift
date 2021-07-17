//
//  FeedViewController.swift
//  Prototype
//
//  Created by Andreas Link on 17.07.21.
//

import UIKit

class FeedViewController: UITableViewController {
    private let feed = FeedImageViewModel.prototypeFeed

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feed.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedImageCell", for: indexPath) as! FeedImageCell
        let model: FeedImageViewModel = feed[indexPath.row]
        cell.configure(with: model)
        return cell
    }
}

extension FeedImageCell {
    func configure(with model: FeedImageViewModel) {
        locationLabel.text = model.location
        locationContainer.isHidden = model.location == nil
        fadeIn(UIImage(named: model.imageName))
        descriptionLabel.text = model.description
        descriptionLabel.isHidden = model.description == nil
    }
}
