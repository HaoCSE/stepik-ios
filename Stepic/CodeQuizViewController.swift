//
//  CodeQuizViewController.swift
//  Stepic
//
//  Created by Ostrenkiy on 22.06.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import UIKit
import FLKAutoLayout
import Highlightr

class CodeQuizViewController: QuizViewController {

    var dataset: String?
    var reply: Reply?

    var limitsLabel: StepikLabel = StepikLabel()
    var toolbarView: CodeQuizToolbarView = CodeQuizToolbarView(frame: CGRect.zero)
    var codeTextView: UITextView = UITextView()

    let toolbarHeight: CGFloat = 44
    var limitsLabelHeight: CGFloat = 40

    let languagePicker = CodeLanguagePickerViewController(nibName: "PickerViewController", bundle: nil) as CodeLanguagePickerViewController

    var highlightr: Highlightr!
    let textStorage = CodeAttributedString()
    let size: CodeQuizElementsSize = DeviceInfo.current.isPad ? .big : .small

    let playgroundManager = CodePlaygroundManager()
    var currentCode: String = "" {
        didSet {
            guard let options = step.options else { return }
            if let userTemplate = options.template(language: language, userGenerated: true) {
                userTemplate.templateString = codeTextView.text
            } else {
                let newTemplate = CodeTemplate(language: language, template: codeTextView.text)
                newTemplate.isUserGenerated = true
                options.templates += [newTemplate]
            }
        }
    }

    var tabSize: Int = 0

    func setupAccessoryView(editable: Bool) {
        if editable {
            codeTextView.inputAccessoryView = InputAccessoryBuilder.buildAccessoryView(size: size.elements.toolbar, language: language, tabAction: {
                [weak self] in
                guard let s = self else { return }
                s.playgroundManager.insertAtCurrentPosition(symbols: String(repeating: " ", count: s.tabSize), textView: s.codeTextView)
                }, insertStringAction: {
                    [weak self]
                    symbols in
                    guard let s = self else { return }
                    s.playgroundManager.insertAtCurrentPosition(symbols: symbols, textView: s.codeTextView)
                    s.playgroundManager.analyzeAndComplete(textView: s.codeTextView, previousText: s.currentCode, language: s.language, tabSize: s.tabSize, inViewController: s, suggestionsDelegate: s)
                    s.currentCode = s.codeTextView.text
                }, hideKeyboardAction: {
                    [weak self] in
                    guard let s = self else { return }
                    s.codeTextView.resignFirstResponder()
            })
        } else {
            codeTextView.inputAccessoryView = nil
        }
        codeTextView.reloadInputViews()
    }

    var language: CodeLanguage! {
        didSet {
            if language != oldValue {
                textStorage.language = language.highlightr
            }
            if let limit = step.options?.limit(language: language) {
                setLimits(time: limit.time, memory: limit.memory)
            }

            tabSize = playgroundManager.countTabSize(text: step.options?.template(language: language, userGenerated: false)?.templateString ?? "")

            toolbarView.language = language.displayName

            if TooltipDefaultsManager.shared.shouldShowForCodeEditor {
                delay(2.0) { [weak self] in
                    guard let s = self else {
                        return
                    }

                    let tooltip = TooltipFactory.codeEditorSettings
                    tooltip.show(direction: .down, in: s.view, from: s.toolbarView.settingsButton)
                    TooltipDefaultsManager.shared.didShowForCodeEditor = true
                }
            }

            setupAccessoryView(editable: submissionStatus != .correct)

            if let userTemplate = step.options?.template(language: language, userGenerated: true) {
                if codeTextView.text != userTemplate.templateString {
                    codeTextView.text = userTemplate.templateString
                }
                currentCode = userTemplate.templateString
                return
            }
            if let template = step.options?.template(language: language, userGenerated: false) {
                if codeTextView.text != template.templateString {
                    codeTextView.text = template.templateString
                }
                currentCode = template.templateString
                return
            }
        }
    }

    override var submissionAnalyticsParams: [String : Any]? {
        guard let step = step else {
            return nil
        }
        var params: [String: Any]? = ["stepId": step.id, "language": language.rawValue]

        if let course = step.lesson?.unit?.section?.course?.id {
            params?["course"] = course
        }

        return params
    }

    fileprivate func setupTheme() {
        highlightr = textStorage.highlightr
        highlightr.setTheme(to: PreferencesContainer.codeEditor.theme)
        let theme = highlightr.theme!
        theme.setCodeFont(UIFont(name: "Courier", size: size.elements.editor.realSizes.fontSize)!)
        highlightr.theme = theme
        codeTextView.backgroundColor = highlightr.theme.themeBackgroundColor
    }

    fileprivate func setupConstraints() {
        self.containerView.addSubview(limitsLabel)
        self.containerView.addSubview(toolbarView)
        self.containerView.addSubview(codeTextView)
        limitsLabel.alignTopEdge(withView: self.containerView, predicate: "8")
        limitsLabel.alignLeading("8", trailing: "0", toView: self.containerView)
        limitsLabel.constrainHeight("\(limitsLabelHeight)")
        toolbarView.constrainTopSpace(toView: self.limitsLabel, predicate: "8")
        toolbarView.alignLeading("0", trailing: "0", toView: self.containerView)
        toolbarView.constrainBottomSpace(toView: self.codeTextView, predicate: "8")
        toolbarView.constrainHeight("\(toolbarHeight)")
        codeTextView.alignLeading("0", trailing: "0", toView: self.containerView)
        codeTextView.alignBottomEdge(withView: self.containerView, predicate: "0")
        codeTextView.constrainHeight("\(size.elements.editor.realSizes.editorHeight)")
    }

    fileprivate func setLimits(time: Double, memory: Double) {

        let attTimeLimit = NSAttributedString(string: "Time limit: ", attributes: [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 15)])
        let attMemoryLimit = NSAttributedString(string: "Memory limit: ", attributes: [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 15)])
        let attTime = NSAttributedString(string: "\(time) seconds\n", attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15)])
        let attMemory = NSAttributedString(string: "\(memory) MB", attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15)])

        let result = NSMutableAttributedString(attributedString: attTimeLimit)
        result.append(attTime)
        result.append(attMemoryLimit)
        result.append(attMemory)
        limitsLabel.numberOfLines = 2
        limitsLabel.attributedText = result
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer()
        layoutManager.addTextContainer(textContainer)
        codeTextView = UITextView(frame: CGRect.zero, textContainer: textContainer)
        codeTextView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        codeTextView.autocorrectionType = UITextAutocorrectionType.no
        codeTextView.autocapitalizationType = UITextAutocapitalizationType.none
        if #available(iOS 11.0, *) {
            codeTextView.smartQuotesType = .no
        }
        codeTextView.textColor = UIColor(white: 0.8, alpha: 1.0)

        setupTheme()
        setupConstraints()

        toolbarView.delegate = self

        guard let options = step.options else {
            return
        }

        languagePicker.languages = options.languages.map({return $0.displayName}).sorted()

        codeTextView.delegate = self
        submissionPressedBlock = {
            [weak self] in
            self?.codeTextView.resignFirstResponder()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        toolbarView.layoutSubviews()
        updateTextViewInsets()
    }

    func hidePicker() {
        languagePicker.removeFromParentViewController()
        languagePicker.view.removeFromSuperview()
        isSubmitButtonHidden = false
    }

    func showPicker() {
        isSubmitButtonHidden = true
        addChildViewController(languagePicker)
        view.addSubview(languagePicker.view)
        languagePicker.view.align(toView: containerView)
        languagePicker.backButton.isHidden = true
        languagePicker.selectedBlock = {
            [weak self] in
            guard let s = self else { return }

            guard let selectedLanguage = s.step.options?.languages.filter({$0.displayName == s.languagePicker.selectedData}).first else {
                return
            }

            s.language = selectedLanguage
            AnalyticsReporter.reportEvent(AnalyticsEvents.Code.languageChosen, parameters: ["size": "standard", "language": s.language.rawValue])
            s.hidePicker()
        }
    }

    override func display(dataset: Dataset) {
        guard let dataset = dataset as? String else {
            return
        }

        self.dataset = dataset

        guard let options = step.options else {
            return
        }

        self.submissionStatus = nil

        setQuizControls(enabled: true)

        if options.languages.count > 1 {
            showPicker()
        } else {
            language = options.languages[0]
            AnalyticsReporter.reportEvent(AnalyticsEvents.Code.languageChosen, parameters: ["size": "standard", "language": language.rawValue])
        }
    }

    var submissionStatus: SubmissionStatus?

    override func display(reply: Reply, withStatus status: SubmissionStatus) {
        guard let reply = reply as? CodeReply else {
            return
        }

        self.reply = reply
        self.submissionStatus = status
        display(reply: reply)

        if status == .correct {
            setQuizControls(enabled: false)
            setupAccessoryView(editable: false)
        } else {
            setQuizControls(enabled: true)
        }
    }

    override func display(reply: Reply) {
        guard let reply = reply as? CodeReply else {
            return
        }

        if let l = reply.language {
            language = l
            if codeTextView.text != reply.code {
                codeTextView.text = reply.code
            }
            currentCode = reply.code
        } else {
            setUnsupportedQuizView()
        }
        hidePicker()
    }

    func setUnsupportedQuizView() {
        let v = UIView()
        v.backgroundColor = UIColor.groupTableViewBackground
        let unsupportedLabel = StepikLabel()
        unsupportedLabel.text = NSLocalizedString("NotSupportedLanguage", comment: "")
        unsupportedLabel.textAlignment = .center
        unsupportedLabel.numberOfLines = 0
        unsupportedLabel.font = UIFont.systemFont(ofSize: 15)
        unsupportedLabel.textColor = UIColor.gray
        v.addSubview(unsupportedLabel)
        unsupportedLabel.align(toView: v)
        self.containerView.addSubview(v)
        v.align(toView: self.containerView)
    }

    fileprivate func setQuizControls(enabled: Bool) {
        guard let options = step.options else {
            return
        }

        codeTextView.isEditable = enabled
        toolbarView.resetButton.isEnabled = enabled
        if options.languages.count > 1 {
            toolbarView.languageButton.isEnabled = enabled
        }
    }

    override var needsToRefreshAttemptWhenWrong: Bool {
        return false
    }

    override func getReply() -> Reply? {
        guard let language = language, let code = codeTextView.text else {
            return nil
        }
        return CodeReply(code: code, language: language)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func updateTextViewInsets() {
        if #available(iOS 11.0, *) {
            codeTextView.textContainerInset = UIEdgeInsets(top: 0, left: containerView.safeAreaInsets.left, bottom: 0, right: containerView.safeAreaInsets.right)
        }
    }
}

extension CodeQuizViewController : CodeQuizToolbarDelegate {
    func changeLanguagePressed() {
        guard let options = step.options else {
            return
        }

        if options.languages.count > 1 {
            showPicker()
        }
    }

    func settingsPressed() {
        guard let vc = ControllerHelper.instantiateViewController(identifier: "CodeEditorSettings", storyboardName: "Profile") as? CodeEditorSettingsViewController else {
            return
        }

        let presenter = CodeEditorSettingsPresenter(view: vc)
        vc.presenter = presenter

        let navVC = WrappingNavigationViewController(wrappedViewController: vc, title: NSLocalizedString("Settings", comment: ""), onDismiss: { [weak self] in
            self?.setupTheme()
        })
        present(navVC, animated: true)
    }

    func fullscreenPressed() {
        guard let options = step.options else {
            return
        }

        AnalyticsReporter.reportEvent(AnalyticsEvents.Code.fullscreenPressed, parameters: ["size": "standard"])

        let fullscreen = FullscreenCodeQuizViewController(nibName: "FullscreenCodeQuizViewController", bundle: nil)
        fullscreen.options = options
        if submissionStatus == .correct {
            fullscreen.isSolved = true
        }
        fullscreen.language = language
        fullscreen.onDismissBlock = {
            [weak self]
            newLanguage, newText in
            guard let s = self else { return }
            s.language = newLanguage
            s.codeTextView.text = newText
            s.playgroundManager.analyzeAndComplete(textView: s.codeTextView, previousText: s.currentCode, language: s.language, tabSize: s.tabSize, inViewController: s, suggestionsDelegate: s)
            s.currentCode = newText
        }

        present(fullscreen, animated: true, completion: nil)
    }

    func resetPressed() {
        guard let options = step.options else {
            return
        }

        let alert = UIAlertController(title: nil, message: NSLocalizedString("ResetAlertDescription", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Reset", comment: ""), style: .destructive, handler: {
            [weak self]
            _ in
            guard let s = self else { return }

            AnalyticsReporter.reportEvent(AnalyticsEvents.Code.resetPressed, parameters: ["size": "standard"])

            if let userTemplate = options.template(language: s.language, userGenerated: true) {
                CoreDataHelper.instance.deleteFromStore(userTemplate)
            }

            if let template = options.template(language: s.language, userGenerated: false) {
                s.codeTextView.text = template.templateString
                s.currentCode = template.templateString
            } else {
                s.codeTextView.text = ""
                s.currentCode = ""
            }

            CoreDataHelper.instance.save()
        }))
        present(alert, animated: true, completion: nil)
    }
}

extension CodeQuizViewController : UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        guard step.options != nil else {
            return
        }

        playgroundManager.analyzeAndComplete(textView: codeTextView, previousText: currentCode, language: language, tabSize: tabSize, inViewController: self, suggestionsDelegate: self)

        currentCode = textView.text

        CoreDataHelper.instance.save()
    }
}

extension CodeQuizViewController: CodeSuggestionDelegate {
    func didSelectSuggestion(suggestion: String, prefix: String) {
        codeTextView.becomeFirstResponder()
        playgroundManager.insertAtCurrentPosition(symbols: suggestion.substring(from: suggestion.index(suggestion.startIndex, offsetBy: prefix.count)), textView: codeTextView)
        playgroundManager.analyzeAndComplete(textView: codeTextView, previousText: currentCode, language: language, tabSize: tabSize, inViewController: self, suggestionsDelegate: self)
        currentCode = codeTextView.text
    }

    var suggestionsSize: CodeSuggestionsSize {
        return self.size.elements.suggestions
    }
}
