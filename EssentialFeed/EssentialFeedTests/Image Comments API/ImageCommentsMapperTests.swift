//  Copyright © 2022 Andreas Link. All rights reserved.

import EssentialFeed
import XCTest

final class ImageCommentsMapperTests: XCTestCase {
    func test_map_throwsErrorOnNon2xxHttpResponse() throws {
        let validJsonData: Data = makeJSONData(items: [])
        let samples: [Int] = [199, 150, 300, 400, 500]

        try samples.forEach { statusCode in
            XCTAssertThrowsError(
                try ImageCommentsMapper.map(data: validJsonData, response: HTTPURLResponse(statusCode: statusCode))
            )
        }
    }

    func test_map_throwsErrorOn2xxHttpResponseWithInvalidJson() throws {
        let invalidJsonData: Data = invalidJsonData()
        let samples: [Int] = [200, 201, 250, 280, 299]

        try samples.forEach { statusCode in
            XCTAssertThrowsError(
                try ImageCommentsMapper.map(data: invalidJsonData, response: HTTPURLResponse(statusCode: statusCode))
            )
        }
    }

    func test_map_deliversNoItemsOn2xxHttpResponseWithEmptyJSONList() throws {
        let jsonWithEmptyListData: Data = makeJSONData(items: [])

        let samples: [Int] = [200, 201, 250, 280, 299]
        try samples.forEach { statusCode in
            let result = try ImageCommentsMapper.map(data: jsonWithEmptyListData, response: HTTPURLResponse(statusCode: statusCode))
            XCTAssertEqual(result, [])
        }
    }

    func test_map_deliversItemsOn2xxHttpResponseWithJSONList() throws {
        let comment1 = makeComment(
            id: UUID(),
            message: "message",
            createdAt: (Date(timeIntervalSince1970: 1598627222), "2020-08-28T15:07:02+00:00"),
            username: "a username"
        )

        let comment2 = makeComment(
            id: UUID(),
            message: "another message",
            createdAt: (Date(timeIntervalSince1970: 1577881882), "2020-01-01T12:31:22+00:00"),
            username: "another username"
        )

        let jsonWithListData: Data = makeJSONData(items: [comment1.json, comment2.json])

        let samples: [Int] = [200, 201, 250, 280, 299]
        try samples.forEach { statusCode in
            let result = try ImageCommentsMapper.map(data: jsonWithListData, response: HTTPURLResponse(statusCode: statusCode))
            XCTAssertEqual(result, [comment1.model, comment2.model])
        }
    }

    // MARK: Helpers:
    func makeComment(id: UUID, message: String, createdAt: (Date, String), username: String) -> (model: ImageComment, json: [String: Any]) {
        let item: ImageComment = .init(id: id, message: message, createdAt: createdAt.0, username: username)
        let json: [String: Any] = [
            "id": id.uuidString,
            "message": message,
            "created_at": createdAt.1,
            "author": [
                "username": username
            ]
        ].compactMapValues { $0 }

        return (item, json)
    }

    func invalidJsonData() -> Data {
        return .init("Invalid JSON".utf8)
    }
}
