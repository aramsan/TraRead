//
//  ContentView.swift
//  TraRead
//
//  Created by aram.mine on 2026/02/11.
//

import SwiftUI
import Translation
import AppKit
import UniformTypeIdentifiers

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
                            openFilePicker()
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

                    Spacer()

                    // MARK: - 文章表示エリア（前後コンテキスト付き）
                    sentenceDisplayView

                    Spacer()

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
        // 画面全体タップで次文進行
        .contentShape(Rectangle())
        .onTapGesture {
            if canAdvance {
                advanceToNext()
            }
        }
        // Enter キーで次文進行
        .onKeyPress(.return) {
            if canAdvance {
                advanceToNext()
                return .handled
            }
            return .ignored
        }

        .onChange(of: viewModel.translationTrigger) { oldValue, newValue in
            handleTranslationTrigger(newValue)
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleFileDrop(providers)
        }
    }

    // MARK: - サブビュー

    /// プレースホルダー表示
    private var placeholderView: some View {
        VStack(spacing: 20) {
            if let icon = getResizedIcon() {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 128)
                    .opacity(0.5)
            } else {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 48))
                    .foregroundColor(greyColor.opacity(0.5))
            }

            Text("英語のファイルをドロップしてください")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(greyColor)

            Text("または ⌘V でテキストをペースト")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(greyColor.opacity(0.7))

            HStack(spacing: 12) {
                Button {
                    openFilePicker()
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
    }

    /// 文章表示（前後コンテキスト付き）
    private var sentenceDisplayView: some View {
        VStack(spacing: 6) {
            // 前の文（英文＋日本語翻訳をコンテキストとして表示）
            if viewModel.currentSentenceIndex > 0 {
                let prevIndex = viewModel.currentSentenceIndex - 1
                VStack(spacing: 2) {
                    Text(viewModel.sentences[prevIndex])
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(greyColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    if let prevTranslation = viewModel.translations[prevIndex] {
                        Text(prevTranslation)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(secondaryColor.opacity(0.4))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                }
                .padding(.horizontal, 40)
                .transition(.opacity)
            }

            // 現在の英語文（大きく強調）
            Text(viewModel.currentSentence)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(surfaceColor)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)
                .padding(.vertical, 8)

            // 日本語翻訳
            if !viewModel.japaneseTranslation.isEmpty {
                Text(viewModel.japaneseTranslation)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(secondaryColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // 次の文（コンテキスト）
            if viewModel.currentSentenceIndex < viewModel.sentences.count - 1 {
                Text(viewModel.sentences[viewModel.currentSentenceIndex + 1])
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(greyColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                    .padding(.top, 4)
                    .transition(.opacity)
            }
        }
        .id(viewModel.currentSentenceIndex) // インデックスごとにViewを再生成してトランジションを適用
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
        // 翻訳の表示アニメーションは個別に保持（ただしトランジションと衝突しないよう注意）
        .animation(.easeInOut(duration: 0.3), value: viewModel.japaneseTranslation)
    }

    /// プログレスバー
    private var progressBarView: some View {
        Group {
            if !viewModel.sentences.isEmpty {
                VStack(spacing: 4) {
                    ProgressView(
                        value: Double(viewModel.currentSentenceIndex + 1),
                        total: Double(viewModel.sentences.count)
                    )
                    .tint(primaryColor)
                    .padding(.horizontal, 40)

                    Text("\(viewModel.currentSentenceIndex + 1) / \(viewModel.sentences.count)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(greyColor)
                }
                .padding(.bottom, 8)
            }
        }
    }

    /// ナビゲーションコントロール
    private var navigationControls: some View {
        HStack(spacing: 24) {
            // Prev ボタン
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.prevSentence()
                }
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title2)
                    .foregroundColor(canGoPrev ? surfaceColor : greyColor)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle().fill(canGoPrev ? primaryColor.opacity(0.3) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canGoPrev)

            // 再生ボタン（大きな丸型）
            Button {
                advanceToNext()
            } label: {
                Image(systemName: viewModel.isSpeaking ? "pause.fill" : "play.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(surfaceColor)
                    .frame(width: 72, height: 72)
                    .background(
                        Circle().fill(
                            canAdvance
                                ? LinearGradient(
                                    colors: [primaryColor, secondaryColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                                : LinearGradient(
                                    colors: [greyColor.opacity(0.5), greyColor.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                        )
                    )
                    .shadow(color: primaryColor.opacity(canAdvance ? 0.4 : 0), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(!canAdvance)

            // Next ボタン
            Button {
                viewModel.nextSentence()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundColor(canGoNext ? surfaceColor : greyColor)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle().fill(canGoNext ? primaryColor.opacity(0.3) : Color.clear)
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
                .font(.system(size: 14))
                .foregroundColor(surfaceColor.opacity(0.6))
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(primaryColor.opacity(0.2))
                )
        }
        .buttonStyle(.plain)
        .help("英文・日文をコピー")
    }

    /// コピー完了フィードバック
    private var copiedFeedbackOverlay: some View {
        Text("コピーしました")
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(surfaceColor.opacity(0.8))
            )
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 80)
    }

    // MARK: - 状態ヘルパー

    private var canAdvance: Bool {
        // 最後の文では再生ボタン（Play/Next）を無効化
        !viewModel.isSpeaking && viewModel.currentSentenceIndex < viewModel.sentences.count - 1
    }

    private var canGoPrev: Bool {
        !viewModel.isSpeaking && viewModel.currentSentenceIndex > 0
    }

    private var canGoNext: Bool {
        // 音声再生中でもNextボタン（FF）は有効化
        viewModel.currentSentenceIndex < viewModel.sentences.count - 1
    }

    // MARK: - アクション

    private func advanceToNext() {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.nextSentence()
        }
    }

    /// クリップボードからテキストをペースト
    private func pasteFromClipboard() {
        guard let pastedString = NSPasteboard.general.string(forType: .string),
              !pastedString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        viewModel.processInputText(loadedText: pastedString)
    }

    /// 全文の英文・日文をクリップボードにコピー
    private func copyAllSentences() {
        // まず現在の翻訳を保存
        viewModel.saveCurrentTranslation()

        var lines: [String] = []
        for (index, sentence) in viewModel.sentences.enumerated() {
            lines.append(sentence)
            if let translation = viewModel.translations[index] {
                lines.append(translation)
            }
            lines.append("") // 文間に空行
        }
        let textToCopy = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(textToCopy, forType: .string)

        withAnimation(.easeInOut(duration: 0.3)) {
            showCopiedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showCopiedFeedback = false
            }
        }
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.text, .pdf]

        if panel.runModal() == .OK, let selectedURL = panel.url {
            let fileHandler = FileHandler()
            do {
                let content = try fileHandler.loadFileContent(from: selectedURL)
                viewModel.processInputText(loadedText: content)
            } catch {
                viewModel.currentSentence = "Error loading file: \(error.localizedDescription)"
            }
        }
    }

    private func handleTranslationTrigger(_ newValue: String?) {
        guard let textToTranslate = newValue else { return }

        let sourceLanguage = Locale.Language(identifier: "en-US")
        let targetLanguage = Locale.Language(identifier: "ja-JP")

        Task {
            do {
                let session = TranslationSession(
                    installedSource: sourceLanguage,
                    target: targetLanguage
                )
                let response = try await session.translate(textToTranslate)

                await MainActor.run { [weak viewModel] in
                    viewModel?.japaneseTranslation = response.targetText
                    viewModel?.speakJapaneseTranslation()
                }
            } catch {
                await MainActor.run { [weak viewModel] in
                    viewModel?.japaneseTranslation = "Translation error: \(error.localizedDescription)"
                    viewModel?.isSpeaking = false
                    viewModel?.currentSpeakingLanguage = .none
                }
            }
            await MainActor.run { [weak viewModel] in
                viewModel?.translationTrigger = nil
            }
        }
    }

    private func handleFileDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    DispatchQueue.main.async { [weak viewModel] in
                        guard let vm = viewModel else { return }

                        if let error = error {
                            vm.currentSentence = "Error loading dropped file: \(error.localizedDescription)"
                            return
                        }
                        guard let fileURL = url else {
                            vm.currentSentence = "Error: Dropped item is not a valid file URL."
                            return
                        }

                        let accessed = fileURL.startAccessingSecurityScopedResource()
                        defer {
                            if accessed { fileURL.stopAccessingSecurityScopedResource() }
                        }

                        let fileHandler = FileHandler()
                        do {
                            let content = try fileHandler.loadFileContent(from: fileURL)
                            vm.processInputText(loadedText: content)
                        } catch {
                            vm.currentSentence = "Error loading dropped file: \(error.localizedDescription)"
                        }
                    }
                }
                return true
            }
        }
        return false
    }

    private func getResizedIcon() -> NSImage? {
        guard let originalIcon = NSImage(named: "TraReadIcon") else { return nil }
        let targetSize = NSSize(width: 128, height: 128)
        let resizedIcon = NSImage(size: targetSize)
        
        resizedIcon.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        originalIcon.draw(in: NSRect(origin: .zero, size: targetSize),
                          from: NSRect(origin: .zero, size: originalIcon.size),
                          operation: .copy,
                          fraction: 1.0)
        resizedIcon.unlockFocus()
        
        return resizedIcon
    }
}

#Preview {
    ContentView()
        .environmentObject(TraReadViewModel())
}
