//
//  SettingsPresenter.swift
//  Stepic
//
//  Created by Ostrenkiy on 04.09.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Foundation

protocol SettingsView: class {
    func setMenu(menu: Menu)
    func changeVideoQuality(action: VideoQualityChoiceAction)
    func changeCodeEditorSettings()

    func presentAuth()
    func navigateToDownloads()
}

class SettingsPresenter {
    weak var view: SettingsView?
    var menu: Menu = Menu(blocks: [])

    init(view: SettingsView) {
        self.view = view
        self.menu = buildSettingsMenu()
        view.setMenu(menu: self.menu)
    }

    private func buildSettingsMenu() -> Menu {
        var blocks = [
            buildTitleMenuBlock(id: videoHeaderBlockId, title: NSLocalizedString("Video", comment: "")),
            buildOnlyWifiSwitchBlock(),
            buildLoadedVideoQualityBlock(),
            buildOnlineVideoQualityBlock(),
            buildTitleMenuBlock(id: adaptiveHeaderBlockId, title: NSLocalizedString("AdaptivePreferencesTitle", comment: "")),
            buildAdaptiveModeSwitchBlock(),
            buildTitleMenuBlock(id: adaptiveHeaderBlockId, title: NSLocalizedString("CodeEditorTitle", comment: "")),
            buildCodeEditorSettingsBlock(),
            buildTitleMenuBlock(id: adaptiveHeaderBlockId, title: ""),
            buildDownloadsTransitionBlock(),
            buildLogoutBlock()
        ]

        return Menu(blocks: blocks)
    }

    // MARK: - Menu blocks

    private let videoHeaderBlockId = "video_header"
    private let onlyWifiSwitchBlockId = "only_wifi_switch"
    private let loadedVideoQualityBlockId = "loaded_video_quality"
    private let onlineVideoQualityBlockId = "online_video_quality"
    private let adaptiveHeaderBlockId = "adaptive_header"
    private let adaptiveModeSwitchBlockId = "use_adaptive_mode"
    private let codeEditorSettingsHeaderBlockId = "code_editor_header"
    private let codeEditorSettingsBlockId = "code_editor_settings"
    private let downloadsBlockId = "downloads"
    private let logoutBlockId = "logout"

    private func buildTitleMenuBlock(id: String, title: String) -> HeaderMenuBlock {
        return HeaderMenuBlock(id: id, title: title)
    }

    private func buildLoadedVideoQualityBlock() -> TransitionMenuBlock {
        let block = TransitionMenuBlock(id: loadedVideoQualityBlockId, title: NSLocalizedString("LoadingVideoQualityPreference", comment: ""))

        block.onTouch = {
            [weak self] in
            self?.view?.changeVideoQuality(action: .downloading)
        }

        return block
    }

    private func buildOnlineVideoQualityBlock() -> TransitionMenuBlock {
        let block = TransitionMenuBlock(id: onlineVideoQualityBlockId, title: NSLocalizedString("WatchingVideoQualityPreference", comment: ""))

        block.onTouch = {
            [weak self] in
            self?.view?.changeVideoQuality(action: .watching)
        }

        return block
    }

    private func buildOnlyWifiSwitchBlock() -> SwitchMenuBlock {
        let block = SwitchMenuBlock(id: onlyWifiSwitchBlockId, title: NSLocalizedString("WiFiLoadPreference", comment: ""), isOn: !ConnectionHelper.shared.reachableOnWWAN)

        block.onSwitch = {
            isOn in
            ConnectionHelper.shared.reachableOnWWAN = !isOn
        }

        return block
    }

    private func buildAdaptiveModeSwitchBlock() -> SwitchMenuBlock {
        let block = SwitchMenuBlock(id: adaptiveModeSwitchBlockId, title: NSLocalizedString("UseAdaptiveModePreference", comment: ""), isOn: AdaptiveStorageManager.shared.isAdaptiveModeEnabled)

        block.onSwitch = {
            isOn in
            AdaptiveStorageManager.shared.isAdaptiveModeEnabled = !AdaptiveStorageManager.shared.isAdaptiveModeEnabled
        }

        return block
    }

    private func buildCodeEditorSettingsBlock() -> TransitionMenuBlock {
        let block = TransitionMenuBlock(id: codeEditorSettingsBlockId, title: NSLocalizedString("CodeEditorSettingsTitle", comment: ""))

        block.onTouch = {
            [weak self] in
            self?.view?.changeCodeEditorSettings()
        }

        return block
    }

    private func buildDownloadsTransitionBlock() -> TransitionMenuBlock {
        let block: TransitionMenuBlock = TransitionMenuBlock(id: downloadsBlockId, title: NSLocalizedString("Downloads", comment: ""))

        block.onTouch = {
            [weak self] in
            self?.view?.navigateToDownloads()
        }

        return block
    }

    private func buildLogoutBlock() -> TransitionMenuBlock {
        let block: TransitionMenuBlock = TransitionMenuBlock(id: logoutBlockId, title: NSLocalizedString("Logout", comment: ""))

        block.titleColor = UIColor(red: 200 / 255.0, green: 40 / 255.0, blue: 80 / 255.0, alpha: 1)
        block.onTouch = {
            [weak self] in
            self?.logout()
        }

        return block
    }

    private func logout() {
        AuthInfo.shared.token = nil
        view?.presentAuth()
    }
}
