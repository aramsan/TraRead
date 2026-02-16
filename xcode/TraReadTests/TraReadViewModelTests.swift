import XCTest
@testable import TraRead

class TraReadViewModelTests: XCTestCase {

    var viewModel: TraReadViewModel!

    override func setUpWithError() throws {
        viewModel = TraReadViewModel()
    }

    override func tearDownWithError() throws {
        viewModel = nil
    }

    // MARK: - processInputText(loadedText:) テスト

    func testProcessInputText_withLoadedText_success() {
        let loadedText = "This is sentence one. This is sentence two. And a third."
        viewModel.processInputText(loadedText: loadedText)

        XCTAssertEqual(viewModel.inputText, loadedText)
        XCTAssertEqual(viewModel.sentences.count, 3)
        XCTAssertEqual(viewModel.currentSentence, "This is sentence one.")
        XCTAssertEqual(viewModel.currentSentenceIndex, 0)
        XCTAssertFalse(viewModel.isProcessing)
    }

    func testProcessInputText_withLoadedText_empty() {
        let loadedText = ""
        viewModel.processInputText(loadedText: loadedText)

        XCTAssertEqual(viewModel.inputText, "")
        XCTAssertTrue(viewModel.sentences.isEmpty)
        XCTAssertEqual(viewModel.currentSentence, "No text to process. Please enter text or load a file.")
        XCTAssertEqual(viewModel.currentSentenceIndex, 0)
        XCTAssertFalse(viewModel.isProcessing)
    }

    func testProcessInputText_withLoadedText_noSentences() {
        let loadedText = "Single phrase without punctuation"
        viewModel.processInputText(loadedText: loadedText)

        XCTAssertEqual(viewModel.inputText, loadedText)
        XCTAssertEqual(viewModel.sentences.count, 1)
        XCTAssertEqual(viewModel.currentSentence, "Single phrase without punctuation")
        XCTAssertEqual(viewModel.currentSentenceIndex, 0)
        XCTAssertFalse(viewModel.isProcessing)
    }

    func testProcessInputText_withoutLoadedText_success() {
        viewModel.inputText = "Hello from manual input. This is also processed."
        viewModel.processInputText()

        XCTAssertEqual(viewModel.sentences.count, 2)
        XCTAssertEqual(viewModel.currentSentence, "Hello from manual input.")
        XCTAssertEqual(viewModel.currentSentenceIndex, 0)
        XCTAssertFalse(viewModel.isProcessing)
    }
    
    func testProcessInputText_withoutLoadedText_empty() {
        viewModel.inputText = ""
        viewModel.processInputText()

        XCTAssertEqual(viewModel.inputText, "")
        XCTAssertTrue(viewModel.sentences.isEmpty)
        XCTAssertEqual(viewModel.currentSentence, "No text to process. Please enter text or load a file.")
        XCTAssertEqual(viewModel.currentSentenceIndex, 0)
        XCTAssertFalse(viewModel.isProcessing)
    }

    // MARK: - nextSentence() テスト

    func testNextSentence_advancesToNextSentence() {
        viewModel.processInputText(loadedText: "First sentence. Second sentence. Third sentence.")
        XCTAssertEqual(viewModel.currentSentenceIndex, 0)
        XCTAssertEqual(viewModel.currentSentence, "First sentence.")

        viewModel.nextSentence()

        XCTAssertEqual(viewModel.currentSentenceIndex, 1)
        XCTAssertEqual(viewModel.currentSentence, "Second sentence.")
    }

    func testNextSentence_atEndOfText() {
        viewModel.processInputText(loadedText: "Only sentence.")
        XCTAssertEqual(viewModel.sentences.count, 1)
        XCTAssertEqual(viewModel.currentSentenceIndex, 0)

        viewModel.nextSentence()

        // 最終文に達した場合、テキストはそのまま維持される（"End of text..." は表示しない）
        XCTAssertEqual(viewModel.currentSentence, "Only sentence.")
        XCTAssertEqual(viewModel.currentSentenceIndex, 0)
        XCTAssertFalse(viewModel.isSpeaking)
        XCTAssertEqual(viewModel.currentSpeakingLanguage, .none)
    }

    func testNextSentence_clearsJapaneseTranslation() {
        viewModel.processInputText(loadedText: "First. Second.")
        viewModel.japaneseTranslation = "最初。"
        viewModel.translationTrigger = "First."

        viewModel.nextSentence()

        XCTAssertEqual(viewModel.japaneseTranslation, "", "nextSentenceで日本語翻訳がクリアされること")
        XCTAssertNil(viewModel.translationTrigger, "nextSentenceで翻訳トリガーがクリアされること")
    }

    // MARK: - prevSentence() テスト

    func testPrevSentence_goesBackToPreviousSentence() {
        viewModel.processInputText(loadedText: "First sentence. Second sentence. Third sentence.")
        viewModel.nextSentence() // index = 1
        viewModel.nextSentence() // index = 2
        XCTAssertEqual(viewModel.currentSentenceIndex, 2)

        viewModel.prevSentence()

        XCTAssertEqual(viewModel.currentSentenceIndex, 1)
        XCTAssertEqual(viewModel.currentSentence, "Second sentence.")
    }

    func testPrevSentence_atFirstSentence() {
        viewModel.processInputText(loadedText: "First sentence. Second sentence.")
        XCTAssertEqual(viewModel.currentSentenceIndex, 0)

        viewModel.prevSentence()

        // 最初の文の場合、インデックスは0のまま
        XCTAssertEqual(viewModel.currentSentenceIndex, 0)
        XCTAssertEqual(viewModel.currentSentence, "First sentence.")
    }

    func testPrevSentence_clearsJapaneseTranslation() {
        viewModel.processInputText(loadedText: "First. Second.")
        viewModel.nextSentence() // index = 1
        viewModel.japaneseTranslation = "第二。"
        viewModel.translationTrigger = "Second."

        viewModel.prevSentence()

        XCTAssertEqual(viewModel.japaneseTranslation, "", "prevSentenceで日本語翻訳がクリアされること")
        XCTAssertNil(viewModel.translationTrigger, "prevSentenceで翻訳トリガーがクリアされること")
    }

    // MARK: - saveCurrentTranslation() テスト

    func testSaveCurrentTranslation_persistsTranslation() {
        viewModel.processInputText(loadedText: "Sentence one. Sentence two.")
        viewModel.japaneseTranslation = "文章一。"
        
        viewModel.saveCurrentTranslation()
        
        XCTAssertEqual(viewModel.translations[0], "文章一。", "現在の翻訳が辞書に正しく保存されること")
    }

    func testNextPrev_automaticallySavesTranslation() {
        viewModel.processInputText(loadedText: "Sentence one. Sentence two.")
        viewModel.japaneseTranslation = "文章一。"
        
        viewModel.nextSentence()
        
        XCTAssertEqual(viewModel.translations[0], "文章一。", "nextSentence時に前の文の翻訳が保存されること")
        XCTAssertEqual(viewModel.japaneseTranslation, "", "遷移先では現在の翻訳がクリアされていること")
        
        viewModel.japaneseTranslation = "文章二。"
        viewModel.prevSentence()
        
        XCTAssertEqual(viewModel.translations[1], "文章二。", "prevSentence時に現在の翻訳が保存されること")
    }

    // MARK: - reset() テスト

    func testReset_clearsAllState() {
        viewModel.processInputText(loadedText: "Some text. Another sentence.")
        viewModel.nextSentence()
        viewModel.japaneseTranslation = "翻訳テスト"
        viewModel.translationTrigger = "Some text."

        viewModel.reset()

        XCTAssertEqual(viewModel.inputText, "")
        XCTAssertEqual(viewModel.currentSentence, "Welcome to TraRead! Enter your text above to begin.")
        XCTAssertEqual(viewModel.japaneseTranslation, "")
        XCTAssertTrue(viewModel.sentences.isEmpty)
        XCTAssertEqual(viewModel.currentSentenceIndex, 0)
        XCTAssertFalse(viewModel.isSpeaking)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertEqual(viewModel.currentSpeakingLanguage, .none)
        XCTAssertNil(viewModel.translationTrigger)
    }

    // MARK: - processInputText 再処理テスト

    func testProcessInputText_reprocessClearsOldState() {
        // 最初のテキストを処理
        viewModel.processInputText(loadedText: "First batch. Two sentences.")
        XCTAssertEqual(viewModel.sentences.count, 2)
        viewModel.nextSentence()
        XCTAssertEqual(viewModel.currentSentenceIndex, 1)

        // 新しいテキストで再処理 → 状態がリセットされること
        viewModel.processInputText(loadedText: "New single sentence.")
        XCTAssertEqual(viewModel.sentences.count, 1)
        XCTAssertEqual(viewModel.currentSentenceIndex, 0)
        XCTAssertEqual(viewModel.currentSentence, "New single sentence.")
        XCTAssertEqual(viewModel.japaneseTranslation, "")
    }
}
