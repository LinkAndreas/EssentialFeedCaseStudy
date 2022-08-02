//  Copyright © 2022 Andreas Link. All rights reserved.

import XCTest

extension XCTestCase {
    func record(snapshot: UIImage, named name: String, file: StaticString = #filePath, line: UInt = #line) {
        let snapshotDirectoryURL = makeSnapshotDirectoryURL(name: name, file: file)
        let referenceData = makeSnapshotData(for: snapshot, file: file)
        let referenceURL = makeReferenceURL(name: name, file: file)

        createDirectoryIfNeeded(at: snapshotDirectoryURL)

        do {
            try referenceData?.write(to: referenceURL)
            return XCTFail(
                """
                Record succeeded: Use `assert` to compare the snapshot.

                • Snapshot: \(referenceURL)
                """,
                file: file,
                line: line
            )
        } catch {
            return XCTFail("Failed to record snapshot with error: \(error)", file: file, line: line)
        }
    }
}

extension XCTestCase {
    func assert(
        snapshot: UIImage,
        named name: String,
        perPixelTolerance: CGFloat = 0.001,
        tolerance: CGFloat = 0.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let referenceURL = makeReferenceURL(name: name, file: file)
        let failedURL = makeFailedURL(name: name, file: file)
        let differenceURL = makeDifferenceURL(name: name, file: file)

        guard
            let snapshotData = snapshot.pngData(),
            let snapshot = UIImage(data: snapshotData)
        else {
            return XCTFail(
                "Failed to generate PNG representation from snapshot",
                file: file,
                line: line
            )
        }

        guard
            let referenceData = try? Data(contentsOf: referenceURL),
            let reference = UIImage(data: referenceData)
        else {
            return XCTFail(
                "Failed loading reference at: \(referenceURL). Use `record` before asserting.",
                file: file,
                line: line
            )
        }

        if !snapshot.matches(
            reference: reference,
            perPixelTolerance: perPixelTolerance,
            tolerance: tolerance
        ) {
            removeItemIfNeeded(at: failedURL)
            removeItemIfNeeded(at: differenceURL)

            let difference = snapshot.diff(with: reference)
            let differenceData = difference.pngData()

            do {
                try snapshotData.write(to: failedURL)
            } catch {
                XCTFail("Failed storing failed snapshots: \(error)", file: file, line: line)
            }

            do {
                try differenceData?.write(to: differenceURL)
            } catch {
                XCTFail("Failed storing snapshot difference: \(error)", file: file, line: line)
            }

            XCTFail(
                """
                Snapshot does not match Reference:

                • Snapshot: \(failedURL)

                • Reference: \(referenceURL)

                • Difference: \(differenceURL)
                """,
                file: file,
                line: line
            )
        }
    }
}

private extension XCTestCase {
    private func removeItemIfNeeded(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private func createDirectoryIfNeeded(at url: URL) {
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func makeSnapshotData(for snapshot: UIImage, file: StaticString = #filePath, line: UInt = #line) -> Data? {
        guard let snapshotData = snapshot.pngData() else {
            XCTFail("Failed to generate PNG representation from snapshot", file: file, line: line)
            return nil
        }

        return snapshotData
    }

    func makeSnapshotDirectoryURL(name: String, file: StaticString = #filePath) -> URL {
        let fileURL = URL(fileURLWithPath: String(describing: file))
        let fileName = (fileURL.lastPathComponent as NSString).deletingPathExtension

        return fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("snapshots/\(fileName)/", isDirectory: true)
    }

    func makeReferenceURL(name: String, file: StaticString = #filePath) -> URL {
        makeSnapshotDirectoryURL(name: name, file: file)
            .appendingPathComponent("\(name).png", isDirectory: false)
    }

    func makeFailedURL(name: String, file: StaticString = #filePath) -> URL {
        makeSnapshotDirectoryURL(name: name, file: file)
            .appendingPathComponent("\(name)_failed.png", isDirectory: false)
    }

    func makeDifferenceURL(name: String, file: StaticString = #filePath) -> URL {
        makeSnapshotDirectoryURL(name: name, file: file)
            .appendingPathComponent("\(name)_diff.png", isDirectory: false)
    }
}
