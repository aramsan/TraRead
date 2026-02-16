import XCTest
import PDFKit
@testable import TraRead

class FileHandlerTests: XCTestCase {

    var fileHandler: FileHandler!
    var tempDirectory: URL!
    var testPDFURL: URL? // Optional: may not be found in all environments

    override func setUpWithError() throws {
        fileHandler = FileHandler()
        // Create a temporary directory for test files
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)

        // Resource loading: try multiple strategies to find sample.pdf
        var bundle = Bundle(for: type(of: self))
        let bundleName = "TraRead_TraReadTests"
        let bundleDir = bundle.bundleURL.deletingLastPathComponent()

        // Strategy 1: Look for SwiftPM resource bundle inside test bundle
        if let resourceBundleURL = bundle.resourceURL?.appendingPathComponent(bundleName + ".bundle"),
           let resourceBundle = Bundle(url: resourceBundleURL) {
            bundle = resourceBundle
        }
        // Strategy 2: Look for resource bundle in sibling directory
        else if let manualBundle = Bundle(url: bundleDir.appendingPathComponent(bundleName + ".bundle")) {
            bundle = manualBundle
        }

        testPDFURL = bundle.url(forResource: "sample", withExtension: "pdf")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        fileHandler = nil
        tempDirectory = nil
        testPDFURL = nil
    }

    // MARK: - Test loadTextFile(from:)

    func testLoadTextFile_success() throws {
        let testContent = "Hello, world!\nThis is a test."
        let testFileURL = tempDirectory.appendingPathComponent("test.txt")
        try testContent.write(to: testFileURL, atomically: true, encoding: .utf8)

        let loadedContent = try fileHandler.loadTextFile(from: testFileURL)
        XCTAssertEqual(loadedContent, testContent, "読み込んだ内容が書き込んだ内容と一致すること")
    }

    func testLoadTextFile_fileNotFound() {
        let nonExistentURL = tempDirectory.appendingPathComponent("non_existent.txt")
        do {
            _ = try fileHandler.loadTextFile(from: nonExistentURL)
            XCTFail("textFileLoadFailed エラーが期待されたが、成功した")
        } catch let error as FileHandlingError {
            if case .textFileLoadFailed = error {
                // 成功：正しいエラータイプ
            } else {
                XCTFail(".textFileLoadFailed が期待されたが、\(error) が返された")
            }
        } catch {
            XCTFail("FileHandlingError が期待されたが、別のエラーが返された: \(error)")
        }
    }

    // MARK: - Test extractText(from:) for PDF

    func testExtractText_pdfSuccess() throws {
        guard let validPDFURL = self.testPDFURL else {
            throw XCTSkip("sample.pdf がテストバンドルに見つからないためスキップ")
        }
        let extractedContent = try fileHandler.extractText(from: validPDFURL)
        XCTAssertFalse(extractedContent.isEmpty, "PDFから抽出されたテキストが空でないこと")
        XCTAssertTrue(extractedContent.contains("This is sample."), "PDFの内容に期待されるテキストが含まれること。実際の内容: \(extractedContent)")
    }

    func testExtractText_pdfNotFound() {
        let nonExistentPDFURL = tempDirectory.appendingPathComponent("non_existent.pdf")
        do {
            _ = try fileHandler.extractText(from: nonExistentPDFURL)
            XCTFail("pdfLoadFailed エラーが期待されたが、成功した")
        } catch let error as FileHandlingError {
            if case .pdfLoadFailed = error {
                // 成功
            } else {
                XCTFail(".pdfLoadFailed が期待されたが、\(error) が返された")
            }
        } catch {
            XCTFail("FileHandlingError が期待されたが、別のエラーが返された: \(error)")
        }
    }

    // MARK: - Test loadFileContent(from:)

    func testLoadFileContent_txtSuccess() throws {
        let testContent = "Unified load from TXT."
        let testFileURL = tempDirectory.appendingPathComponent("unified.txt")
        try testContent.write(to: testFileURL, atomically: true, encoding: .utf8)

        let loadedContent = try fileHandler.loadFileContent(from: testFileURL)
        XCTAssertEqual(loadedContent, testContent, "読み込んだ内容が書き込んだ内容と一致すること")
    }

    func testLoadFileContent_pdfSuccess() throws {
        guard let validPDFURL = self.testPDFURL else {
            throw XCTSkip("sample.pdf がテストバンドルに見つからないためスキップ")
        }
        let extractedContent = try fileHandler.loadFileContent(from: validPDFURL)
        XCTAssertFalse(extractedContent.isEmpty, "PDFから抽出されたテキストが空でないこと")
        XCTAssertTrue(extractedContent.contains("This is sample."), "PDFの内容に期待されるテキストが含まれること")
    }

    func testLoadFileContent_unsupportedFileType() {
        let unsupportedFileURL = tempDirectory.appendingPathComponent("image.jpg")
        let dummyData = Data("dummy content".utf8)
        try? dummyData.write(to: unsupportedFileURL)

        do {
            _ = try fileHandler.loadFileContent(from: unsupportedFileURL)
            XCTFail("unsupportedFileType エラーが期待されたが、成功した")
        } catch let error as FileHandlingError {
            if case .unsupportedFileType(let ext) = error {
                XCTAssertEqual(ext, "jpg")
            } else {
                XCTFail(".unsupportedFileType が期待されたが、\(error) が返された")
            }
        } catch {
            XCTFail("FileHandlingError が期待されたが、別のエラーが返された: \(error)")
        }
    }
}
