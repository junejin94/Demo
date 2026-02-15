
import SwiftUI
import UniformTypeIdentifiers

/// A `Transferable` representation of test results in JSON format.
///
/// Enables drag-and-drop or sharing of test results as a JSON file.
struct JSONTestExport: Transferable {
    /// The test results to export.
    let result: TestSuiteResult
    
    /// The UTType for JSON content.
    static var exportedContentType: UTType { .json }
    
    /// The transfer representation for file export.
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .json) { export in
            SentTransferredFile(try ResultExporter.exportToTemp(result: export.result, format: .json))
        } importing: { _ in
            throw ExportError.importNotSupported
        }
    }
}
