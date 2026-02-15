
import Foundation
import CoreSwift // For TestResult
import UniformTypeIdentifiers

/// Utilities for exporting test results to file formats.
struct ResultExporter {
    
    /// Exports test results to a temporary file in the specified format.
    ///
    /// - Parameters:
    ///   - result: The test suite result to export.
    ///   - format: The uniform type identifier for the output format (JSON or XML).
    /// - Returns: A URL to the temporary file containing the exported data.
    /// - Throws: ``ExportError/writeFailed(_:)`` if writing to disk fails.
    static func exportToTemp(result: TestSuiteResult, format: UTType) throws -> URL {
        let ext = format == .json ? "json" : "xml"
        let filename = "test_results.\(ext)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        let content: String
        if format == .json {
            content = generateJSON(result)
        } else {
            content = generateJUnitXML(result)
        }
        
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            throw ExportError.writeFailed(error)
        }
    }
    
    private static func generateJUnitXML(_ result: TestSuiteResult) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <testsuites name="\(xmlEscape(result.suiteName))" tests="\(result.totalCount)" failures="\(result.failureCount)">
        """
        
        for category in result.categories {
            let catFailures = category.tests.filter { $0.result.isFailed }.count
            xml += "\n  <testsuite name=\"\(xmlEscape(category.name))\" tests=\"\(category.tests.count)\" failures=\"\(catFailures)\">\n"
            
            for test in category.tests {
                xml += "    <testcase name=\"\(xmlEscape(test.name))\" classname=\"\(xmlEscape(category.name))\""
                
                switch test.result {
                case .failed(let reason):
                    xml += ">\n      <failure message=\"\(xmlEscape(reason))\"/>\n    </testcase>\n"
                case .error(let msg):
                    xml += ">\n      <error message=\"\(xmlEscape(msg))\"/>\n    </testcase>\n"
                case .notRun, .running:
                    xml += ">\n      <skipped />\n    </testcase>\n"
                case .passed:
                    xml += " />\n"
                }
            }
            xml += "  </testsuite>"
        }
        
        xml += "\n</testsuites>"
        return xml
    }
    
    private static func xmlEscape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
    
    private static func generateJSON(_ result: TestSuiteResult) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        struct JSONResult: Encodable {
            let suite: String
            let passed: Int
            let failed: Int
            let total: Int
            let categories: [JSONCategory]
        }
        
        struct JSONCategory: Encodable {
            let name: String
            let tests: [JSONTest]
        }
        
        struct JSONTest: Encodable {
            let id: String
            let name: String
            let status: String
            let reason: String?
        }
        
        let jsonResult = JSONResult(
            suite: result.suiteName,
            passed: result.passedCount,
            failed: result.failureCount,
            total: result.totalCount,
            categories: result.categories.map { category in
                JSONCategory(
                    name: category.name,
                    tests: category.tests.map { test in
                        JSONTest(
                            id: test.id,
                            name: test.name,
                            status: statusString(test.result),
                            reason: failureReason(test.result)
                        )
                    }
                )
            }
        )
        
        if let data = try? encoder.encode(jsonResult),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return "{}"
    }
    
    private static func statusString(_ result: TestResult) -> String {
        switch result {
        case .passed: return "passed"
        case .failed: return "failed"
        case .error: return "error"
        case .notRun: return "not_run"
        case .running: return "running"
        }
    }
    
    private static func failureReason(_ result: TestResult) -> String? {
        switch result {
        case .failed(let reason): return reason
        case .error(let msg): return msg
        default: return nil
        }
    }
}
