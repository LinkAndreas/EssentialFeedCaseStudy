//  Copyright © 2022 Andreas Link. All rights reserved.

import XCTest

func localized(
    _ key: String,
    table: String,
    bundle: Bundle,
    file: StaticString = #filePath,
    line: UInt = #line
) -> String {
    let value = bundle.localizedString(forKey: key, value: nil, table: table)

    if value == key {
        XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
    }

    return value
}

func assertLocalizedKeyAndValuesExist(
    in bundle: Bundle,
    and table: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let localizationBundles = allLocalizationBundles(in: bundle)
    let localizedStringKeys = allLocalizedStringKeys(in: localizationBundles, table: table)

    localizationBundles.forEach { (bundle, localization) in
        localizedStringKeys.forEach { key in
            let localizedString = bundle.localizedString(forKey: key, value: nil, table: table)
            if localizedString == key {
                let language = Locale.current.localizedString(forLanguageCode: localization) ?? ""

                XCTFail(
                    "Missing \(language) (\(localization)) localized string for key: \(key) in table: \(table)",
                    file: file,
                    line: line
                )
            }
        }
    }
}

private typealias LocalizedBundle = (bundle: Bundle, localization: String)

private func allLocalizationBundles(
    in bundle: Bundle,
    file: StaticString = #filePath,
    line: UInt = #line
) -> [LocalizedBundle] {
    return bundle.localizations.compactMap { localization in
        guard
            let path = bundle.path(forResource: localization, ofType: "lproj"),
            let localizationBundle = Bundle(path: path)
        else {
            XCTFail("Couldn't find bundle for localization \(localization)", file: file, line: line)
            return nil
        }

        return (localizationBundle, localization)
    }
}

private func allLocalizedStringKeys(
    in bundles: [LocalizedBundle],
    table: String,
    file: StaticString = #filePath,
    line: UInt = #line
) -> Set<String> {
    return bundles.reduce([]) { result, next in
        guard
            let path = next.bundle.path(forResource: table, ofType: "strings"),
            let strings = NSDictionary(contentsOfFile: path),
            let keys = strings.allKeys as? [String]
        else {
            XCTFail("Couldn't load localized strings for localication: \(next.localization)")
            return result
        }

        return result.union(Set(keys))
    }
}
