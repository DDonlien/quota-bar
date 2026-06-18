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

enum MenuDashboardStyle {
    static let width: CGFloat = 292
    static let height: CGFloat = 320

    static let horizontalPadding: CGFloat = 14
    static let topPadding: CGFloat = 18
    static let bottomPadding: CGFloat = 16

    static let summarySpacing: CGFloat = 6
    static let summaryDividerTop: CGFloat = 10
    static let summaryDividerBottom: CGFloat = 8
    static let sectionDividerTop: CGFloat = 8
    static let sectionDividerBottom: CGFloat = 8
    static let sectionSpacing: CGFloat = 6
    static let quotaRowsSpacing: CGFloat = 5
    static let quotaRowSpacing: CGFloat = 2

    static let leadingGlyphColumn: CGFloat = 13
    static let statusDotSize: CGFloat = 6
    static let quotaTitleWidth: CGFloat = 56
    static let percentWidth: CGFloat = 34
    static let progressHeight: CGFloat = 6

    static let summaryFontSize: CGFloat = 13
    static let planNameFontSize: CGFloat = 14
    static let planPriceFontSize: CGFloat = 13
    static let quotaFontSize: CGFloat = 11

    static let summaryWeight: Font.Weight = .medium
    static let planNameWeight: Font.Weight = .regular
    static let quotaTitleWeight: Font.Weight = .medium
}

struct MenuView: View {
    private let plans: [SubscriptionPlan] = [
        SubscriptionPlan(
            name: "Codex Plus",
            price: "¥150/月",
            statusColor: .quotaGreen,
            quotas: [
                QuotaStatus(title: "5小时额度", refreshText: "6月6日 0:14刷新", value: 1.0),
                QuotaStatus(title: "周额度", refreshText: "6月6日 0:14刷新", value: 0.64)
            ]
        ),
        SubscriptionPlan(
            name: "MiniMax Plus",
            price: "¥150/月",
            statusColor: .quotaRed,
            quotas: [
                QuotaStatus(title: "5小时额度", refreshText: "6月6日 0:14刷新", value: 0.0),
                QuotaStatus(title: "周额度", refreshText: "6月6日 0:14刷新", value: 1.0)
            ]
        ),
        SubscriptionPlan(
            name: "Kimi Plus",
            price: "¥150/月",
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
                .padding(.top, MenuDashboardStyle.summaryDividerTop)
                .padding(.bottom, MenuDashboardStyle.summaryDividerBottom)

            ForEach(Array(plans.enumerated()), id: \.element.id) { index, plan in
                PlanSection(plan: plan)

                if index < plans.count - 1 {
                    DividerLine()
                        .padding(.top, MenuDashboardStyle.sectionDividerTop)
                        .padding(.bottom, MenuDashboardStyle.sectionDividerBottom)
                }
            }
        }
        .padding(.top, MenuDashboardStyle.topPadding)
        .padding(.horizontal, MenuDashboardStyle.horizontalPadding)
        .padding(.bottom, MenuDashboardStyle.bottomPadding)
        .frame(width: MenuDashboardStyle.width, height: MenuDashboardStyle.height)
        .background(Color.clear)
        .foregroundStyle(Color.quotaText)
    }
}

private struct SummaryView: View {
    var body: some View {
        VStack(spacing: MenuDashboardStyle.summarySpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text("每月费用")
                    .font(.system(size: MenuDashboardStyle.summaryFontSize, weight: MenuDashboardStyle.summaryWeight))
                    .foregroundStyle(Color.quotaText)

                Spacer()

                Text("¥150/月")
                    .font(.system(size: MenuDashboardStyle.summaryFontSize, weight: .regular))
                    .foregroundStyle(Color.quotaSecondary)
            }

            HStack(alignment: .firstTextBaseline) {
                Text("可用订阅")
                    .font(.system(size: MenuDashboardStyle.summaryFontSize, weight: MenuDashboardStyle.summaryWeight))
                    .foregroundStyle(Color.quotaText)

                Spacer()

                Text("2/3")
                    .font(.system(size: MenuDashboardStyle.summaryFontSize, weight: .regular))
                    .foregroundStyle(Color.quotaSecondary)
            }
        }
    }
}

private struct PlanSection: View {
    let plan: SubscriptionPlan

    var body: some View {
        VStack(alignment: .leading, spacing: MenuDashboardStyle.sectionSpacing) {
            HStack(spacing: 0) {
                Circle()
                    .fill(plan.statusColor)
                    .frame(width: MenuDashboardStyle.statusDotSize, height: MenuDashboardStyle.statusDotSize)
                    .frame(width: MenuDashboardStyle.leadingGlyphColumn, alignment: .center)

                Text(plan.name)
                    .font(.system(size: MenuDashboardStyle.planNameFontSize, weight: MenuDashboardStyle.planNameWeight))
                    .foregroundStyle(Color.quotaText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                Spacer()

                Text(plan.price)
                    .font(.system(size: MenuDashboardStyle.planPriceFontSize, weight: .regular))
                    .foregroundStyle(Color.quotaSecondary)
                    .lineLimit(1)
            }

            VStack(spacing: MenuDashboardStyle.quotaRowsSpacing) {
                ForEach(plan.quotas) { quota in
                    QuotaRow(quota: quota)
                }
            }
            .padding(.leading, MenuDashboardStyle.leadingGlyphColumn)
        }
    }
}

private struct QuotaRow: View {
    let quota: QuotaStatus

    private var percentText: String {
        "\(Int((quota.value * 100).rounded()))%"
    }

    var body: some View {
        VStack(spacing: MenuDashboardStyle.quotaRowSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text(quota.title)
                    .font(.system(size: MenuDashboardStyle.quotaFontSize, weight: MenuDashboardStyle.quotaTitleWeight))
                    .foregroundStyle(Color.quotaText)
                    .lineLimit(1)
                    .frame(width: MenuDashboardStyle.quotaTitleWidth, alignment: .leading)

                Spacer(minLength: 6)

                Text(quota.refreshText)
                    .font(.system(size: MenuDashboardStyle.quotaFontSize, weight: .regular))
                    .foregroundStyle(Color.quotaSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)

                Text(percentText)
                    .font(.system(size: MenuDashboardStyle.quotaFontSize, weight: .regular))
                    .foregroundStyle(Color.quotaSecondary)
                    .lineLimit(1)
                    .monospacedDigit()
                    .frame(width: MenuDashboardStyle.percentWidth, alignment: .trailing)
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
                    .frame(width: proxy.size.width * clampedValue)
            }
        }
        .frame(height: MenuDashboardStyle.progressHeight)
    }
}

private struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.quotaDivider)
            .frame(height: 1)
    }
}

private extension Color {
    static let quotaText = Color.primary
    static let quotaSecondary = Color.secondary
    static let quotaDivider = Color.primary.opacity(0.12)
    static let quotaTrack = Color.primary.opacity(0.08)
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
