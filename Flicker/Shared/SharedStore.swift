//
//  SharedStore.swift
//  Flicker
//
//  Shared between the container app and the Finder Sync extension.
//  Reads/writes the configured AppEntry list via a fixed file path.
//

import Foundation
import os

/// 配置读写。App 与扩展通过 App Group 容器共享同一组 JSON 文件。
/// 路径：~/Library/Group Containers/group.com.wangyanan.flicker/Flicker/
///
/// App 未开沙盒、扩展开了沙盒（含 com.apple.security.application-groups
/// entitlement），两侧都用 containerURL(forSecurityApplicationGroupIdentifier:)
/// 解析同一个容器路径，避免依赖任何硬编码的用户路径。
enum SharedStore {
    /// 与两个 target 的 entitlements 中 com.apple.security.application-groups 保持一致。
    static let appGroupIdentifier = "group.com.wangyanan.flicker"
    static let configFileName = "app_entries.json"
    static let menuSettingsFileName = "menu_settings.json"
    static let newFileSettingsFileName = "new_file_settings.json"
    static let appSupportSubdir = "Flicker"
    private static let logger = Logger(subsystem: "com.wangyanan.flicker", category: "SharedStore")

    /// 共享目录 URL（App Group 容器内）。
    static var sharedDirectoryURL: URL? {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else { return nil }
        let fm = FileManager.default
        let dir = container.appendingPathComponent(appSupportSubdir, isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// 共享配置文件 URL（App Group 容器内）。
    static var configFileURL: URL? {
        sharedDirectoryURL?.appendingPathComponent(configFileName, isDirectory: false)
    }

    /// 菜单设置文件 URL。
    static var menuSettingsFileURL: URL? {
        sharedDirectoryURL?.appendingPathComponent(menuSettingsFileName, isDirectory: false)
    }
    
    /// 新建文件设置文件 URL。
    static var newFileSettingsFileURL: URL? {
        sharedDirectoryURL?.appendingPathComponent(newFileSettingsFileName, isDirectory: false)
    }

    // MARK: - 旧配置迁移

    /// 旧版本配置位于 ~/Library/Application Support/Flicker（依赖沙盒临时例外
    /// entitlement 且路径硬编码了作者主目录，其他用户读不到）。新版本改用
    /// App Group 容器，首次读取时若目标文件缺失则从旧位置拷贝一次。
    private static var legacyMigrationDone = false
    private static func migrateLegacyFilesIfNeeded() {
        guard !legacyMigrationDone else { return }
        legacyMigrationDone = true
        let fm = FileManager.default
        let legacyDir = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent(appSupportSubdir, isDirectory: true)
        guard fm.fileExists(atPath: legacyDir.path),
              let sharedDir = sharedDirectoryURL else { return }
        for name in [configFileName, menuSettingsFileName, newFileSettingsFileName] {
            let src = legacyDir.appendingPathComponent(name, isDirectory: false)
            let dst = sharedDir.appendingPathComponent(name, isDirectory: false)
            if fm.fileExists(atPath: src.path), !fm.fileExists(atPath: dst.path) {
                try? fm.copyItem(at: src, to: dst)
            }
        }
    }

    /// 读取应用列表。
    static func loadEntries() -> [AppEntry] {
        migrateLegacyFilesIfNeeded()
        guard let url = configFileURL,
              let data = try? Data(contentsOf: url) else { return [] }
        do {
            return try JSONDecoder().decode([AppEntry].self, from: data)
        } catch {
            logger.error("loadEntries decode failed: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    /// 写入应用列表。
    @discardableResult
    static func saveEntries(_ entries: [AppEntry]) -> Bool {
        guard let url = configFileURL else { return false }
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            logger.error("saveEntries failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    // MARK: - Menu Settings

    /// 读取菜单设置。文件不存在时返回默认值。
    static func loadMenuSettings() -> MenuSettings {
        migrateLegacyFilesIfNeeded()
        guard let url = menuSettingsFileURL,
              let data = try? Data(contentsOf: url) else { return .defaults }
        do {
            return try JSONDecoder().decode(MenuSettings.self, from: data)
        } catch {
            logger.error("loadMenuSettings decode failed: \(error.localizedDescription, privacy: .public)")
            return .defaults
        }
    }

    /// 写入菜单设置。
    @discardableResult
    static func saveMenuSettings(_ settings: MenuSettings) -> Bool {
        guard let url = menuSettingsFileURL else { return false }
        do {
            let data = try JSONEncoder().encode(settings)
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            logger.error("saveMenuSettings failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
    
    // MARK: - New File Settings
    
    /// 读取新建文件设置。文件不存在时返回默认值。
    static func loadNewFileSettings() -> NewFileSettings {
        migrateLegacyFilesIfNeeded()
        guard let url = newFileSettingsFileURL,
              let data = try? Data(contentsOf: url) else { return .defaults }
        do {
            return try JSONDecoder().decode(NewFileSettings.self, from: data)
        } catch {
            logger.error("loadNewFileSettings decode failed: \(error.localizedDescription, privacy: .public)")
            return .defaults
        }
    }
    
    /// 写入新建文件设置。
    @discardableResult
    static func saveNewFileSettings(_ settings: NewFileSettings) -> Bool {
        guard let url = newFileSettingsFileURL else { return false }
        do {
            let data = try JSONEncoder().encode(settings)
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            logger.error("saveNewFileSettings failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
