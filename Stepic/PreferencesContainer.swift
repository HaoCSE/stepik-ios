//
//  PreferencesContainer.swift
//  Stepic
//
//  Created by Alexander Karpov on 23.11.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import Foundation

/*
 Used to store application preferences, generated by user
 */
class PreferencesContainer {
    static let notifications = NotificationPreferencesContainer()
    static let codeEditor = CodeEditorPreferencesContainer()
}
