//
//  FeedViewController.swift
//  Prototype
//
//  Created by Andreas Link on 17.07.21.
//

import UIKit

class FeedViewController: UITableViewController {
    private var feed: [FeedImageViewModel] = []

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refresh()
        tableView.setContentOffset(.init(x: 0, y: tableView.contentInset.top), animated: false)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feed.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedImageCell", for: indexPath) as! FeedImageCell
        let model: FeedImageViewModel = feed[indexPath.row]
        cell.configure(with: model)
        return cell
    }

    @IBAction
    func refresh() {
        refreshControl?.beginRefreshing()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if self.feed.isEmpty {
                self.feed = FeedImageViewModel.prototypeFeed
                self.tableView.reloadData()
            }
            self.refreshControl?.endRefreshing()
        }
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
