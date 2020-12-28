//
//  HogeViewController.swift
//  MVVM-Swift
//
//  Created by Suguru Takahashi on 2020/12/25.
//

import UIKit
import SafariServices

class HogeViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    private let hogeViewModel = HogeViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.dataSource = self
        tableView.delegate = self
        // 引っ張って更新
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)

        hogeViewModel.delegate = self
        hogeViewModel.load()
    }
}

// MARK: - UITableViewの処理群
extension HogeViewController: UITableViewDataSource, UITableViewDelegate {
    ///　行数を返す
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hogeViewModel.viewItems.count
    }

    ///　cellを返す
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "TableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        let item = hogeViewModel.viewItems[indexPath.row]
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = "[\(item.source)] \(item.pubDate ?? "")"
        return cell
    }

    ///　cellの選択時
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let url = URL(string: hogeViewModel.viewItems[indexPath.row].link) else {
            return
        }
        let safariVC = SFSafariViewController.init(url: url)
        safariVC.dismissButtonStyle = .close
        self.present(safariVC, animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - ViewModelDelegate
extension HogeViewController: HogeViewModelDelegate {
    /// ViewModelのステータスが変化した時の処理
    func didChange(status: Status) {
        switch status {
        case .loading:
            tableView.refreshControl?.beginRefreshing()
            tableView.reloadData()
        case .loaded:
            DispatchQueue.main.async { [weak self] in
                self?.tableView.refreshControl?.endRefreshing()
                self?.tableView.reloadData()
            }
        case .error(let message):
            DispatchQueue.main.async { [weak self] in
                self?.tableView.refreshControl?.endRefreshing()
            }
            print("\(message)")
        }
    }
}

// MARK: - Action
extension HogeViewController {
    /// UITableViewを引っ張って更新
    @objc func refresh(sender: UIRefreshControl) {
        hogeViewModel.load()
    }
}
