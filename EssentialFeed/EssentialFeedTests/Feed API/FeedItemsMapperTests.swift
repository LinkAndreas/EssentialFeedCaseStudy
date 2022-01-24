//  Copyright © 2021 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

class FeedItemsMapperTests: XCTestCase {
    func test_map_throwsErrorOnNon200HttpResponse() throws {
        let validJsonData: Data = makeJSONData(items: [])
        let samples: [Int] = [199, 201, 300, 400, 500]

        try samples.forEach { statusCode in
            XCTAssertThrowsError(
                try FeedItemsMapper.map(data: validJsonData, response: HTTPURLResponse(statusCode: statusCode))
            )
        }
    }

    func test_map_throwsErrorOn200HttpResponseWithInvalidJson() throws {
        let invalidJsonData: Data = invalidJsonData()

        XCTAssertThrowsError(
            try FeedItemsMapper.map(data: invalidJsonData, response: HTTPURLResponse(statusCode: 200))
        )
    }

    func test_map_deliversNoItemsOn200HttpResponseWithEmptyJSONList() throws {
        let jsonWithEmptyListData: Data = makeJSONData(items: [])

        let result = try FeedItemsMapper.map(data: jsonWithEmptyListData, response: HTTPURLResponse(statusCode: 200))
        XCTAssertEqual(result, [])
    }

    func test_map_deliversItemsOn200HttpResponseWithJSONList() throws {
        let item1 = makeItem(
            id: .init(),
            description: "Description 1",
            location: "Location 1",
            imageURL: anyURL()
        )

        let item2 = makeItem(
            id: .init(),
            description: "Description 2",
            location: "Location 2",
            imageURL: anyURL()
        )

        let jsonWithListData: Data = makeJSONData(items: [item1.json, item2.json])

        let result = try FeedItemsMapper.map(data: jsonWithListData, response: HTTPURLResponse(statusCode: 200))
        XCTAssertEqual(result, [item1.model, item2.model])
    }

    // MARK: Helpers:
    func makeItem(id: UUID, description: String?, location: String?, imageURL: URL) -> (model: FeedImage, json: [String: Any]) {
        let item: FeedImage = .init(id: id, description: description, location: location, url: imageURL)
        let json: [String: Any] = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].compactMapValues { $0 }

        return (item, json)
    }

    func invalidJsonData() -> Data {
        return .init("Invalid JSON".utf8)
    }
}
