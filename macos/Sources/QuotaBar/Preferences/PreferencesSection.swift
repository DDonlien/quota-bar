import Foundation
import SwiftUI

/// 偏好设置窗口的 sidebar 路由项。
///
/// 设计原则：按"用户面向"的语义命名（通用 / 模型 / 激活 / 关于），
/// 而不是按"代码模块"命名，方便后续扩展和文案改写。
enum PreferencesSection: String, Hashable, Identifiable, CaseIterable, Sendable {
    case general
    case models
    case activation
    case diagnostics
    case about

    var id: String { rawValue }

    /// sidebar 显示名（中文，面向用户）。
    var title: String {
        switch self {
        case .general: return "通用"
        case .models: return "模型"
        case .activation: return "激活"
        case .diagnostics: return "日志"
        case .about: return "关于"
        }
    }

    /// sidebar SF Symbol 图标。
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .models: return "square.stack.3d.up"
        case .activation: return "key.fill"
        case .diagnostics: return "doc.text.magnifyingglass"
        case .about: return "info.circle"
        }
    }

    /// sidebar 图标的色彩（macOS 26 系统设置风格：每个 section 有自己的颜色，
    /// 选中后高亮用 system glass）。
    var tint: Color {
        switch self {
        case .general: return .gray
        case .models: return .blue
        case .activation: return .orange
        case .diagnostics: return .green
        case .about: return .blue
        }
    }

    /// 该 sidebar 项所属的 group；`.default` 不渲染 section 标题。
    var group: PreferencesGroup {
        switch self {
        case .general, .models: return .default
        case .activation, .diagnostics, .about: return .quotaBar
        }
    }
}

/// sidebar 分组枚举。仅 `.quotaBar` 渲染可见的 section header；`.default` 顶部无标题。
enum PreferencesGroup: Hashable, Sendable {
    case `default`
    case quotaBar

    /// 显示给用户的标题；nil 表示不渲染标题（默认组）。
    var title: String? {
        switch self {
        case .default: return nil
        case .quotaBar: return "Quota Bar"
        }
    }
}