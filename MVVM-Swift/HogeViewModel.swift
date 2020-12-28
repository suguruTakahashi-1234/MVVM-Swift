//
//  HogeViewModel.swift
//  MVVM-Swift
//
//  Created by Suguru Takahashi on 2020/12/24.
//

import Foundation

protocol HogeViewModelDelegate: AnyObject {
    func didChange(status: Status)
}

/// データの取得状態
enum Status {
    case loading
    case loaded
    case error(String)
}

class HogeViewModel {
    struct ViewItem {
        let title: String
        let link: String
        let source: String
        let pubDate: String?
    }
    private(set) var viewItems = [ViewItem]()

    // 取得状態を扱うオブジェクト
    weak var delegate: HogeViewModelDelegate?
    private(set) var status: Status? {
        didSet {
            // 随所でdelegate.didChange(:status)を呼び出すとモレる可能性があるのでdidSetにて行う
            guard let status = status else {
                return
            }
            delegate?.didChange(status: status)
        }
    }

    // テストのためにModelクラスをDIする
    private let hogeModel: HogeModelProtocol
    init(hogeModel: HogeModelProtocol = HogeModel()) {
        self.hogeModel = hogeModel
    }

    /// データ取得
    func load() {
        status = .loading
        hogeModel.retrieveItems { [weak self] (result) in
            switch result {
            case .success(let items):
                self?.viewItems = items.map({ (article) -> ViewItem in
                    return ViewItem(title: article.title,
                                    link: article.link,
                                    source: article.source,
                                    pubDate: self?.format(for: article.pubDate))
                })
                self?.status = .loaded
            case .failure(let error):
                self?.status = .error("エラー: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - ユーティリティ関数
extension HogeViewModel {
    /// Dateから表示用文字列を編集する
    func format(for date: Date?) -> String? {
        guard let date = date else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
