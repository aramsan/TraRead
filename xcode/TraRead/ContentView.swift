import SwiftUI
import Translation
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

struct ContentView: View {
    @EnvironmentObject var viewModel: TraReadViewModel

    // カラーパレット（設計書準拠）
    let primaryColor = Color(hex: "FFD700")    // Tiger Gold
    let secondaryColor = Color(hex: "FF8C00")  // Accent Orange
    let surfaceColor = Color(hex: "121212")    // Almost Black
    let backgroundColor = Color(hex: "FFFBE6") // Warm Off-White
    let greyColor = Color(hex: "BDBDBD")       // Medium Grey

    // コピー完了フィードバック
    @State private var showCopiedFeedback: Bool = false

    // Translation Configuration
    @State private var translationConfig: TranslationSession.Configuration?

    // File Picker State
    @State private var isFileImporterPresented = false

    // MARK: - フォントサイズ調整（iOS/macOS対応）
    private var mainFontSize: CGFloat {
        #if os(iOS)
        return 22
        #else
        return 32
        #endif
    }

    private var translationFontSize: CGFloat {
        #if os(iOS)
        return 16
        #else
        return 24
        #endif
    }

    private var contextFontSize: CGFloat {
        #if os(iOS)
        return 12
        #else
        return 18
        #endif
    }

    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all)

            if viewModel.sentences.isEmpty {
                // MARK: - プレースホルダー（テキスト未読込時）
                placeholderView
            } else {
                // MARK: - メインコンテンツ（テキスト読込済み）
                VStack(spacing: 0) {
                    // 上部：ファイルを開くボタン
                    HStack {
                        Button {
                            isFileImporterPresented = true
                        } label: {
                            Label("Open File...", systemImage: "doc.badge.plus")
                                .font(.caption)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(primaryColor)
                        .foregroundColor(surfaceColor)
                        .controlSize(.small)

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // MARK: - 文章表示エリア（前後コンテキスト付き）
                    sentenceDisplayView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // MARK: - プログレスバー
                    progressBarView

                    // MARK: - コントロールエリア
                    HStack(alignment: .bottom) {
                        Spacer()

                        // ナビゲーションボタン群
                        navigationControls

                        Spacer()
                    }
                    .overlay(alignment: .bottomTrailing) {
                        // コピーボタン（右下）
                        copyButton
                            .padding(.trailing, 24)
                    }
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // コピー完了フィードバック
            if showCopiedFeedback {
                copiedFeedbackOverlay
            }
        }
        .background {
            // Bulletproof Translation Trigger: Use if let + dynamic ID to force re-initialization
            if let config = translationConfig {
                Color.clear
                    .translationTask(config) { session in
                        guard let textToTranslate = viewModel.translationTrigger, !textToTranslate.isEmpty else { return }
                        
                        print("TranslationTask: Starting (Sentence \(viewModel.currentSentenceIndex))")
                        do {
                            let response = try await session.translate(textToTranslate)
                            await MainActor.run {
                                viewModel.japaneseTranslation = response.targetText
                                viewModel.speakJapaneseTranslation()
                            }
                        } catch {
                            await MainActor.run {
                                viewModel.japaneseTranslation = "Translation error: \(error.localizedDescription)"
                                viewModel.isSpeaking = false
                            }
                        }
                    }
                    .id("TranslationTask-\(viewModel.currentSentenceIndex)")
            }
        }
        // 画面全体タップで次文進行
        .contentShape(Rectangle())
        .onTapGesture {
            if canAdvance {
                advanceToNext()
            }
        }
        #if os(macOS)
        // Enter キーで次文進行
        .onKeyPress(.return) {
            if canAdvance {
                advanceToNext()
                return .handled
            }
            return .ignored
        }
        #endif
        .onChange(of: viewModel.translationTrigger) { oldValue, newValue in
            handleTranslationTrigger(newValue)
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleFileDrop(providers)
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.plainText, .pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result: result)
        }
    }

    // MARK: - サブビュー

    /// プレースホルダー表示
    private var placeholderView: some View {
        VStack(spacing: 20) {
            Image("TraReadIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 128, height: 128)
                .opacity(0.5)

            Text("英語のファイルをドロップしてください")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(greyColor)
                .multilineTextAlignment(.center)

            #if os(macOS)
            Text("または ⌘V でテキストをペースト")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(greyColor.opacity(0.7))
            #endif

            HStack(spacing: 12) {
                Button {
                    isFileImporterPresented = true
                } label: {
                    Label("ファイルを開く...", systemImage: "folder")
                        .font(.system(size: 13))
                }
                .buttonStyle(.borderedProminent)
                .tint(primaryColor)
                .foregroundColor(surfaceColor)
            }
            .padding(.top, 8)

            Text(".txt / .pdf に対応")
                .font(.system(size: 11))
                .foregroundColor(greyColor.opacity(0.5))
        }
        .padding()
    }

    /// 文章表示（前後コンテキスト付き）
    private var sentenceDisplayView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    // 上端アンカー
                    Color.clear.frame(height: 1).id("SentenceTop")

                    // 前の文（フェード表示）
                    Group {
                        if viewModel.currentSentenceIndex > 0 {
                            let prevIndex = viewModel.currentSentenceIndex - 1
                            VStack(spacing: 4) {
                                Text(viewModel.sentences[prevIndex])
                                    .font(.system(size: contextFontSize, weight: .regular, design: .rounded))
                                    .foregroundColor(greyColor)
                            }
                            .opacity(0.3)
                            .scaleEffect(0.9)
                        } else {
                            Color.clear.frame(height: 40)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                    // 現在の英語文と翻訳（中央配置・強調）
                    VStack(spacing: 16) {
                        Text(viewModel.currentSentence)
                            .font(.system(size: mainFontSize, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.5)
                            .allowsTightening(true)
                            .foregroundColor(surfaceColor)
                            .lineSpacing(6)
                            .id("EnglishContent")

                        if !viewModel.japaneseTranslation.isEmpty {
                            Text(viewModel.japaneseTranslation)
                                .font(.system(size: translationFontSize, weight: .medium, design: .rounded))
                                .minimumScaleFactor(0.6)
                                .allowsTightening(true)
                                .foregroundColor(secondaryColor)
                                .lineSpacing(4)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                                .id("TranslationContent")
                        } else if viewModel.isProcessing {
                             ProgressView()
                                .tint(secondaryColor)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 20)

                    // 下端アンカー
                    Color.clear.frame(height: 1).id("SentenceBottom")

                    // 次の文（フェード表示）
                    Group {
                        if viewModel.currentSentenceIndex < viewModel.sentences.count - 1 {
                            Text(viewModel.sentences[viewModel.currentSentenceIndex + 1])
                                .font(.system(size: contextFontSize, weight: .regular, design: .rounded))
                                .foregroundColor(greyColor)
                                .opacity(0.3)
                                .scaleEffect(0.9)
                        } else {
                            Color.clear.frame(height: 20)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                }
                .padding(.vertical, 40)
            }
            .scrollIndicators(.hidden)
            .onChange(of: viewModel.currentSentenceIndex) { _, _ in
                // 文が切り替わったら即座に先頭へ
                proxy.scrollTo("SentenceTop", anchor: .top)
            }
            .onChange(of: viewModel.japaneseTranslation) { _, newValue in
                // 翻訳が表示されたら余裕を持って下部へスクロール
                if !newValue.isEmpty {
                    withAnimation(.easeInOut(duration: 1.5)) {
                        proxy.scrollTo("SentenceBottom", anchor: .bottom)
                    }
                }
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.currentSentenceIndex)
        .animation(.easeInOut(duration: 0.3), value: viewModel.japaneseTranslation)
    }

    /// プログレスバー
    private var progressBarView: some View {
        Group {
            if !viewModel.sentences.isEmpty {
                VStack(spacing: 8) {
                    ProgressView(
                        value: Double(viewModel.currentSentenceIndex + 1),
                        total: Double(viewModel.sentences.count)
                    )
                    .tint(primaryColor)
                    .padding(.horizontal, 40)

                    HStack {
                        Text("\(viewModel.currentSentenceIndex + 1) / \(viewModel.sentences.count)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(greyColor)
                        
                        Spacer()
                        
                        autoPlayToggle
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 16)
            }
        }
    }

    /// ナビゲーションコントロール
    private var navigationControls: some View {
        HStack(spacing: 32) {
            // Prev ボタン
            Button {
                withAnimation {
                    viewModel.prevSentence()
                }
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title2)
                    .foregroundColor(canGoPrev ? surfaceColor : greyColor.opacity(0.3))
                    .frame(width: 56, height: 56)
                    .background(
                        Circle().fill(canGoPrev ? primaryColor.opacity(0.2) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canGoPrev)

            // メイン再生ボタン（大きな丸型グラデーション）
            Button {
                advanceToNext()
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [primaryColor, secondaryColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: secondaryColor.opacity(0.3), radius: 10, y: 5)
                    
                    Image(systemName: viewModel.isSpeaking ? "pause.fill" : "play.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(surfaceColor)
                }
                .frame(width: 88, height: 88)
                .opacity(canAdvance ? 1.0 : 0.5)
            }
            .buttonStyle(.plain)
            .disabled(!canAdvance)

            // Next ボタン
            Button {
                withAnimation {
                    viewModel.nextSentence()
                }
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundColor(canGoNext ? surfaceColor : greyColor.opacity(0.3))
                    .frame(width: 56, height: 56)
                    .background(
                        Circle().fill(canGoNext ? primaryColor.opacity(0.2) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canGoNext)
        }
    }

    /// コピーボタン（右下）
    private var copyButton: some View {
        Button {
            copyAllSentences()
        } label: {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 16))
                .foregroundColor(surfaceColor.opacity(0.7))
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(primaryColor.opacity(0.2))
                )
        }
        .buttonStyle(.plain)
    }

    /// 連続再生（オートプレイ）トグル
    private var autoPlayToggle: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.isContinuousPlayEnabled.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Text("Auto Play")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(viewModel.isContinuousPlayEnabled ? secondaryColor : greyColor)
                
                ZStack {
                    Capsule()
                        .fill(viewModel.isContinuousPlayEnabled ? primaryColor : greyColor.opacity(0.3))
                        .frame(width: 36, height: 20)
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 16, height: 16)
                        .shadow(radius: 1)
                        .offset(x: viewModel.isContinuousPlayEnabled ? 8 : -8)
                }
            }
        }
        .buttonStyle(.plain)
    }

    /// コピー完了フィードバック
    private var copiedFeedbackOverlay: some View {
        Text("Copied!")
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(surfaceColor.opacity(0.9))
            )
            .transition(.scale.combined(with: .opacity))
            .padding(.bottom, 100)
            .frame(maxHeight: .infinity, alignment: .bottom)
    }

    // MARK: - 状態ヘルパー

    private var canAdvance: Bool {
        !viewModel.isSpeaking && viewModel.currentSentenceIndex < viewModel.sentences.count - 1
    }

    private var canGoPrev: Bool {
        !viewModel.isSpeaking && viewModel.currentSentenceIndex > 0
    }

    private var canGoNext: Bool {
        viewModel.currentSentenceIndex < viewModel.sentences.count - 1
    }

    // MARK: - アクション

    private func advanceToNext() {
        withAnimation {
            viewModel.nextSentence()
        }
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedURL = urls.first else { return }
            
            // Security scoped resource for iOS
            let accessed = selectedURL.startAccessingSecurityScopedResource()
            defer { if accessed { selectedURL.stopAccessingSecurityScopedResource() } }
            
            let fileHandler = FileHandler()
            do {
                let content = try fileHandler.loadFileContent(from: selectedURL)
                viewModel.processInputText(loadedText: content)
            } catch {
                viewModel.currentSentence = "Error loading file: \(error.localizedDescription)"
            }
        case .failure(let error):
            viewModel.currentSentence = "File Selection Error: \(error.localizedDescription)"
        }
    }

    private func copyAllSentences() {
        viewModel.saveCurrentTranslation()

        var lines: [String] = []
        for (index, sentence) in viewModel.sentences.enumerated() {
            lines.append(sentence)
            if let translation = viewModel.translations[index] {
                lines.append(translation)
            }
            lines.append("")
        }
        let textToCopy = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(textToCopy, forType: .string)
        #elseif os(iOS)
        UIPasteboard.general.string = textToCopy
        #endif

        withAnimation {
            showCopiedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopiedFeedback = false
            }
        }
    }

    private func handleTranslationTrigger(_ newValue: String?) {
        guard let textToTranslate = newValue, !textToTranslate.isEmpty else {
            translationConfig = nil
            return
        }
        
        print("handleTranslationTrigger: Changing config to trigger task...")
        
        let sourceLanguage = Locale.Language(identifier: "en-US")
        let targetLanguage = Locale.Language(identifier: "ja-JP")
        
        // Resetting to ensure a fresh start
        translationConfig = nil 
        
        // Delay slightly to ensure nil state is registered by SwiftUI
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.translationConfig = TranslationSession.Configuration(
                source: sourceLanguage,
                target: targetLanguage
            )
        }
    }

    private func handleFileDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    DispatchQueue.main.async {
                        guard let fileURL = url else { return }
                        let accessed = fileURL.startAccessingSecurityScopedResource()
                        defer { if accessed { fileURL.stopAccessingSecurityScopedResource() } }

                        let fileHandler = FileHandler()
                        do {
                            let content = try fileHandler.loadFileContent(from: fileURL)
                            viewModel.processInputText(loadedText: content)
                        } catch {
                            viewModel.currentSentence = "Error: \(error.localizedDescription)"
                        }
                    }
                }
                return true
            }
        }
        return false
    }
}

#Preview {
    ContentView()
        .environmentObject(TraReadViewModel())
}

#Preview {
    ContentView()
        .environmentObject(TraReadViewModel())
}
