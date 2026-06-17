import SwiftUI

struct SubscriptionPlan: Identifiable {
    let id = UUID()
    let name: String
    let price: String
    let statusColor: Color
    let quotas: [QuotaStatus]
}

struct QuotaStatus: Identifiable {
    let id = UUID()
    let title: String
    let refreshText: String
    let value: Double
}

struct MenuView: View {
    let closeAction: () -> Void

    private let plans: [SubscriptionPlan] = [
        SubscriptionPlan(
            name: "Codex Plus",
            price: "¥ 150/月",
            statusColor: .quotaGreen,
            quotas: [
                QuotaStatus(title: "5小时额度", refreshText: "6月6日 0:14刷新", value: 1.0),
                QuotaStatus(title: "周额度", refreshText: "6月6日 0:14刷新", value: 0.64)
            ]
        ),
        SubscriptionPlan(
            name: "MiniMax Plus",
            price: "¥ 150/月",
            statusColor: .quotaRed,
            quotas: [
                QuotaStatus(title: "5小时额度", refreshText: "6月6日 0:14刷新", value: 0.0),
                QuotaStatus(title: "周额度", refreshText: "6月6日 0:14刷新", value: 1.0)
            ]
        ),
        SubscriptionPlan(
            name: "Kimi Plus",
            price: "¥ 150/月",
            statusColor: .quotaOrange,
            quotas: [
                QuotaStatus(title: "5小时额度", refreshText: "6月6日 0:14刷新", value: 0.28),
                QuotaStatus(title: "周额度", refreshText: "6月6日 0:14刷新", value: 1.0)
            ]
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            SummaryView()

            DividerLine()
                .padding(.top, 12)
                .padding(.bottom, 8)

            ForEach(Array(plans.enumerated()), id: \.element.id) { index, plan in
                PlanSection(plan: plan)

                if index < plans.count - 1 {
                    DividerLine()
                        .padding(.top, 9)
                        .padding(.bottom, 10)
                }
            }

            Spacer(minLength: 0)

            FooterView(closeAction: closeAction)
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .frame(width: 286, height: 462)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.quotaPanel)
        )
        .foregroundStyle(Color.quotaText)
    }
}

private struct SummaryView: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("每月费用")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.quotaText)

                Spacer()

                Text("¥150/月")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.quotaSecondary)
            }

            HStack(alignment: .firstTextBaseline) {
                Text("可用订阅")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.quotaText)

                Spacer()

                Text("2/3")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.quotaSecondary)
            }
        }
    }
}

private struct PlanSection: View {
    let plan: SubscriptionPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Circle()
                    .fill(plan.statusColor)
                    .frame(width: 7, height: 7)
                    .frame(width: 18, alignment: .leading)

                Text(plan.name)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.quotaText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer()

                Text(plan.price)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.quotaSecondary)
                    .lineLimit(1)
            }

            VStack(spacing: 6) {
                ForEach(plan.quotas) { quota in
                    QuotaRow(quota: quota)
                }
            }
            .padding(.leading, 26)
        }
    }
}

private struct QuotaRow: View {
    let quota: QuotaStatus

    private var percentText: String {
        "\(Int((quota.value * 100).rounded()))%"
    }

    var body: some View {
        VStack(spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                Text(quota.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.quotaText)
                    .lineLimit(1)
                    .frame(width: 58, alignment: .leading)

                Spacer(minLength: 6)

                Text(quota.refreshText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.quotaSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)

                Text(percentText)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.quotaSecondary)
                    .lineLimit(1)
                    .monospacedDigit()
                    .frame(width: 34, alignment: .trailing)
            }

            ProgressPill(value: quota.value)
        }
    }
}

private struct ProgressPill: View {
    let value: Double

    private var clampedValue: Double {
        min(max(value, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.quotaTrack)

                Capsule()
                    .fill(Color.quotaBlue)
                    .frame(width: max(10, proxy.size.width * clampedValue))
                    .opacity(clampedValue == 0 ? 0.95 : 1)
            }
        }
        .frame(height: 10)
    }
}

private struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.quotaDivider)
            .frame(height: 1)
    }
}

private struct FooterView: View {
    let closeAction: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("自动刷新 每5分钟 · 上次 07:10:44")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.quotaSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.9)

            Spacer(minLength: 8)

            Button {
                closeAction()
                NSApplication.shared.terminate(nil)
            } label: {
                Text("退出")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.quotaSecondary)
            }
            .buttonStyle(.plain)
        }
    }
}

private extension Color {
    static let quotaPanel = Color(hex: "#BDBDBD").opacity(0.86)
    static let quotaText = Color(hex: "#111111")
    static let quotaSecondary = Color(hex: "#777777")
    static let quotaDivider = Color.black.opacity(0.18)
    static let quotaTrack = Color.black.opacity(0.08)
    static let quotaBlue = Color(hex: "#0A7CFF")
    static let quotaGreen = Color(hex: "#35C85A")
    static let quotaRed = Color(hex: "#FF453A")
    static let quotaOrange = Color(hex: "#FF9F0A")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
