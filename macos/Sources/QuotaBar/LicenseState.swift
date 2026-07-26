import Foundation

// MARK: - 本地授权记录

/// 一次成功激活后本地保存的授权信息。
///
/// 明文存在 `preferences.json` 里，**这是有意的**：项目源码完全公开，任何人都能
/// 自行编译出一个去掉全部校验的版本，在客户端做设备指纹、加密存档、反调试之类的
/// 手段只会增加复杂度和误伤概率，不会真正增加约束力。付费买的是"签名公证 + 自动
/// 更新 + 一键安装"这份省事，授权体系按诚实的荣誉制来做就够了。
struct StoredLicense: Codable, Equatable, Sendable {
    /// Creem 的 license key（用户从购买邮件里拿到的那串）。
    var key: String
    /// Creem 侧为这台设备创建的 instance id，复验时要带上。
    var instanceId: String
    /// Creem 返回的 license 状态原文（`active` / `expired` / `disabled` / `inactive`）。
    /// 原样存而不是提前翻译成本地枚举——Creem 以后加了新状态时，这里至少不会把
    /// 未知状态静默误判成"有效"。
    var status: String
    var activatedAt: Date
    /// 最近一次成功复验的时间（复验失败时不更新，见 `LicenseManager` 的 fail-open 说明）。
    var lastValidatedAt: Date?
    /// Creem 返回的到期时间；一次性买断产品通常是 nil。
    var expiresAt: Date?

    static let activeStatus = "active"
}

// MARK: - 授权/试用状态

/// App 当前处于哪种授权状态。UI 和更新门禁都只看这个枚举，不直接读 `StoredLicense`。
enum LicenseState: Equatable, Sendable {
    /// 试用期内。`daysRemaining` 向上取整且至少为 1——剩 2 小时也显示"剩 1 天"，
    /// 不显示"剩 0 天"（0 天在自然语言里等同于"已经结束"，会让人以为功能已经没了）。
    case trial(daysRemaining: Int)
    /// 试用期结束且没有有效授权。
    case trialExpired
    /// 已激活。
    case licensed(expiresAt: Date?)
    /// 本地有授权记录，但已经不再有效（Creem 明确返回非 active，或订阅型授权已过期）。
    case licenseInvalid(reason: String)

    /// 是否允许自动更新（自动检查 + App 内下载安装）。
    ///
    /// 这是本 phase 唯一的门禁点：额度获取、Provider 管理这些核心功能在任何状态下
    /// 都照常工作。理由见 `StoredLicense` 顶部说明——开源可自编译的前提下，锁核心
    /// 功能只会把用户推向自编译版本，锁便利性才跟"付费买省事"的定位自洽。
    var allowsAutomaticUpdates: Bool {
        switch self {
        case .trial, .licensed:
            return true
        case .trialExpired, .licenseInvalid:
            return false
        }
    }

    /// 是否已经是付费用户（UI 用来决定要不要展示购买入口）。
    var isLicensed: Bool {
        if case .licensed = self { return true }
        return false
    }
}

// MARK: - 状态判定

/// 纯函数式的状态判定：输入首次启动时间 + 本地授权记录 + 当前时间，输出 `LicenseState`。
///
/// 刻意不依赖 `PreferencesStore.shared` 或 `Date()` 默认值之外的任何环境，方便把
/// "第 6 天 / 第 7 天 / 第 8 天"这类边界直接写成单测，而不用去改系统时钟。
enum LicenseEvaluator {
    /// 试用期长度：7 天（跟官网 Pricing 卡片上写的"7 天免费试用"是同一个数字，
    /// 改这里必须同步改 `site/src/i18n/dict.ts` 的 `pricing.*` 文案）。
    static let trialDuration: TimeInterval = 7 * 24 * 60 * 60

    static func state(
        firstLaunchAt: Date?,
        license: StoredLicense?,
        now: Date = Date()
    ) -> LicenseState {
        // 有授权记录时优先看授权，试用期是否走完都不影响——已付费用户不该因为
        // "装了很久"被降级。
        if let license {
            // 先判状态再判到期日：两者同时不满足时，Creem 给的状态原因更准确。
            guard license.status == StoredLicense.activeStatus else {
                return .licenseInvalid(reason: invalidReason(for: license.status))
            }
            if let expiresAt = license.expiresAt, expiresAt <= now {
                return .licenseInvalid(reason: "授权已于 \(Self.dateText(expiresAt)) 到期")
            }
            return .licensed(expiresAt: license.expiresAt)
        }

        // 没有首次启动时间说明这就是第一次跑（调用方随后会把它写进去），按完整试用期算。
        guard let firstLaunchAt else {
            return .trial(daysRemaining: Int(ceil(trialDuration / 86_400)))
        }

        let elapsed = now.timeIntervalSince(firstLaunchAt)
        // 系统时钟被往前调过（elapsed 为负）时按"刚开始试用"处理，不做惩罚性判定——
        // 时钟异常更可能是用户换机/时区问题，不是作弊。
        guard elapsed > 0 else {
            return .trial(daysRemaining: Int(ceil(trialDuration / 86_400)))
        }
        let remaining = trialDuration - elapsed
        guard remaining > 0 else { return .trialExpired }
        return .trial(daysRemaining: max(1, Int(ceil(remaining / 86_400))))
    }

    private static func invalidReason(for status: String) -> String {
        switch status {
        case "expired": return "授权已到期"
        case "disabled": return "授权已被停用"
        case "inactive": return "授权尚未激活"
        default: return "授权状态异常（\(status)）"
        }
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
