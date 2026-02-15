
import SwiftUI
import UniformTypeIdentifiers

/// A `Transferable` representation of test results in JUnit XML format.
///
/// Enables drag-and-drop or sharing of test results as an XML file.
struct XMLTestExport: Transferable {
    /// The test results to export.
    let result: TestSuiteResult
    
    /// The UTType for XML content.
    static var exportedContentType: UTType { .xml }
    
    /// The transfer representation for file export.
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .xml) { export in
            SentTransferredFile(try ResultExporter.exportToTemp(result: export.result, format: .xml))
        } importing: { _ in
            throw ExportError.importNotSupported
        }
    }
}
