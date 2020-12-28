//
//  HogeModel.swift
//  MVVM-Swift
//
//  Created by Suguru Takahashi on 2020/12/24.
//

import Foundation

protocol HogeModelProtocol {
    func retrieveItems(completion: @escaping (Result<[HogeModel.Article], Error>) -> Void)
    func createItems(with data: Data) -> Result<[HogeModel.Article], Error>
}

class HogeModel: NSObject, HogeModelProtocol {
    class Article {
        var title = ""
        var link = ""
        var pubDateStr = ""
        var pubDate: Date? {
            return createDate(from: pubDateStr)
        }
        var description = ""
        var source = ""
    }

    enum Element: String {
        case item = "item"
        case title = "title"
        case link = "link"
        case pubDate = "pubDate"
        case description = "description"
        case source = "source"

        var name: String {
            return self.rawValue
        }
    }

    private var articles = [Article]()
    private var currentElementName : String?

    private var parseError: Error?

    func retrieveItems(completion: @escaping (Result<[Article], Error>) -> Void) {
        guard let url = URL(string:  "https://news.google.com/rss?hl=ja&gl=JP&ceid=JP:ja") else {
            return
        }
        URLSession.shared.dataTask(with: url, completionHandler: { [weak self] (data, response, error) in
            guard let self = self else {
                return
            }
            sleep(1) // 擬似的なレスポンス遅延
            if let error = error {
                completion(Result.failure(error))
                return
            }
            guard let data = data else {
                completion(Result.success([Article]()))
                return
            }
            print("\(String(data: data, encoding: .utf8) ?? "decode error.")")    // DEBUG
            completion(self.createItems(with: data))
        }).resume()
    }

    func createItems(with data: Data) -> Result<[Article], Error> {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        if let parseError = parseError {
            return Result.failure(parseError)
        } else {
            return Result.success(articles)
        }
    }
}

extension HogeModel: XMLParserDelegate {
    // 解析_開始時
    func parserDidStartDocument(_ parser: XMLParser) {
        articles.removeAll()
    }

    /// 解析_要素の開始時
    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String]) {

        currentElementName = nil
        if elementName == Element.item.name {
            // 次のニュース記事が現れた場合、新規の記事classをデフォルトで生成
            articles.append(Article())
        } else {
            // 各要素の場合
            currentElementName = elementName
        }
    }

    /// 解析_要素内の値取得
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // 末尾の記事classを上書き更新
        guard let lastItem = articles.last else {
            return
        }
        switch currentElementName {
        case Element.title.name:
            lastItem.title = string
        case Element.link.name:
            lastItem.link = string
        case Element.pubDate.name:
            lastItem.pubDateStr = string
        case Element.description.name:
            lastItem.description = string
        case Element.source.name:
            lastItem.source = string
        default:
            break
        }
    }

    /// 解析_要素の終了時
    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {

        currentElementName = nil
    }

    /// 解析_終了時
    func parserDidEndDocument(_ parser: XMLParser) {
        self.parseError = nil
    }

    /// 解析_エラー発生時
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }
}

// MARK: - ユーティリティ関数
extension HogeModel {
    /// GoogleNEWSの日付StringからDateを生成する
    static func createDate(from dateString: String) -> Date? {
        let formatter: DateFormatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "E, d M y HH:mm:ss z"
        return formatter.date(from: dateString)
   }
}
