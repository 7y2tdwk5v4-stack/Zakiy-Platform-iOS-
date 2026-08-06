import SwiftUI
import Charts

struct PerformanceView: View {
    @Environment(AuthSession.self) private var authSession

    @State private var summary: PerformanceSummary?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if !authSession.isSignedIn {
                SignedOutPlaceholder(feature: "لوحة أدائك")
            } else if isLoading {
                LoadingView()
            } else if let summary {
                content(summary)
            } else if let errorMessage {
                EmptyStateView(systemImage: "exclamationmark.triangle", title: "تعذر تحميل الأداء", message: errorMessage)
            }
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationTitle("أدائي")
        .task { await load() }
    }

    @ViewBuilder
    private func content(_ summary: PerformanceSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ZakiySpacing.lg) {
                statsRow(summary)

                if summary.attempts.count > 1 {
                    ZakiyCard {
                        VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                            SectionHeader(title: "تطور الدرجات")
                            Chart(Array(summary.attempts.suffix(20).enumerated()), id: \.offset) { index, attempt in
                                LineMark(
                                    x: .value("المحاولة", index),
                                    y: .value("النسبة", attempt.percentage * 100)
                                )
                                .foregroundStyle(Color.zakiyTeal)
                                .interpolationMethod(.catmullRom)
                                PointMark(
                                    x: .value("المحاولة", index),
                                    y: .value("النسبة", attempt.percentage * 100)
                                )
                                .foregroundStyle(Color.zakiyTeal)
                            }
                            .chartYScale(domain: 0...100)
                            .frame(height: 180)
                        }
                    }
                }

                if !summary.weakTopics.isEmpty {
                    ZakiyCard {
                        VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                            SectionHeader(title: "نقاط الضعف", subtitle: "المواضيع اللي تحتاج مراجعة أكثر")
                            ForEach(summary.weakTopics) { topic in
                                HStack {
                                    Text(topic.topic).font(.zakiyBody)
                                    Spacer()
                                    ZakiyChip(text: "\(topic.count)")
                                }
                            }
                        }
                    }
                }

                ZakiyCard {
                    VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                        SectionHeader(title: "آخر المحاولات")
                        ForEach(summary.attempts.suffix(10).reversed()) { attempt in
                            HStack {
                                Text("\(attempt.score) / \(attempt.total)")
                                    .font(.zakiyBody.weight(.semibold))
                                Spacer()
                                ZakiyChip(text: attempt.mode == "room" ? "غرفة" : "فردي")
                            }
                        }
                    }
                }
            }
            .padding(ZakiySpacing.lg)
        }
        .refreshable { await load() }
    }

    private func statsRow(_ summary: PerformanceSummary) -> some View {
        HStack(spacing: ZakiySpacing.md) {
            StatTile(title: "ستريك", value: "\(summary.currentStreak)", systemImage: "flame.fill", tint: .orange)
            StatTile(title: "أطول ستريك", value: "\(summary.longestStreak)", systemImage: "trophy.fill", tint: Color.zakiyMustard)
            StatTile(title: "دقائق المذاكرة", value: "\(summary.totalStudyMinutes)", systemImage: "clock.fill", tint: Color.zakiyTeal)
        }
    }

    private func load() async {
        guard authSession.isSignedIn else { return }
        isLoading = true
        do {
            summary = try await APIClient.shared.performance()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: ZakiySpacing.sm) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Color.zakiyTextPrimary)
            Text(title)
                .font(.zakiyCaption)
                .foregroundStyle(Color.zakiyTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ZakiySpacing.md)
        .background(Color.zakiySurface)
        .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.md, style: .continuous))
    }
}

#Preview {
    NavigationStack { PerformanceView() }
        .environment(AuthSession.shared)
}
