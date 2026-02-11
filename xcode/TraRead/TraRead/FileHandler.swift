import Foundation
import PDFKit

class FileHandler {

    // MARK: - Text File Loading

    /// Loads text content from a given URL, assuming it's a plain text file.
    /// - Parameter fileURL: The URL of the text file.
    /// - Returns: The string content of the file, or nil if an error occurs.
    func loadTextFile(from fileURL: URL) throws -> String {
        do {
            let text = try String(contentsOf: fileURL, encoding: .utf8)
            return text
        } catch {
            throw FileHandlingError.textFileLoadFailed(error.localizedDescription)
        }
    }

    // MARK: - PDF File Loading

    /// Extracts all readable text from a PDF document at the given URL using PDFKit.
    /// - Parameter pdfURL: The URL of the PDF file.
    /// - Returns: The concatenated string content of all pages, or nil if an error occurs.
    func extractText(from pdfURL: URL) throws -> String {
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            throw FileHandlingError.pdfLoadFailed("Could not load PDF document from \(pdfURL.lastPathComponent)")
        }

        let fullText = NSMutableString()

        for i in 0..<pdfDocument.pageCount {
            if let pdfPage = pdfDocument.page(at: i) {
                if let pageText = pdfPage.string {
                    fullText.append(pageText)
                    fullText.append("\n") // Corrected: Add a newline between pages for better readability
                }
            }
        }
        return fullText as String
    }

    // MARK: - Unified File Loading

    /// Loads text from either a .txt or .pdf file.
    /// - Parameter fileURL: The URL of the file.
    /// - Returns: The extracted string content.
    /// - Throws: `FileHandlingError` if the file type is unsupported or loading fails.
    func loadFileContent(from fileURL: URL) throws -> String {
        let fileExtension = fileURL.pathExtension.lowercased()

        switch fileExtension {
        case "txt":
            return try loadTextFile(from: fileURL)
        case "pdf":
            return try extractText(from: fileURL)
        default:
            throw FileHandlingError.unsupportedFileType(fileExtension)
        }
    }
}

// MARK: - Custom Error Type
enum FileHandlingError: LocalizedError {
    case textFileLoadFailed(String)
    case pdfLoadFailed(String)
    case unsupportedFileType(String)

    var errorDescription: String? {
        switch self {
        case .textFileLoadFailed(let message):
            return "Failed to load text file: \(message)"
        case .pdfLoadFailed(let message):
            return "Failed to load PDF file: \(message)"
        case .unsupportedFileType(let fileExtension):
            return "Unsupported file type: .\(fileExtension). Only .txt and .pdf are supported."
        }
    }
}
