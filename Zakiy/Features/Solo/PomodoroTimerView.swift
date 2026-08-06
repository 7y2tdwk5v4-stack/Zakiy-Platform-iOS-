import SwiftUI

/// Optional focus timer (25 minutes study / 5 minutes break), matching the
/// web app's Pomodoro feature mentioned for the solo study mode.
struct PomodoroTimerView: View {
    @Environment(\.dismiss) private var dismiss
    private let studyDuration = 25 * 60
    private let breakDuration = 5 * 60

    @State private var secondsRemaining = 25 * 60
    @State private var isStudyPhase = true
    @State private var isRunning = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var minutes: Int { secondsRemaining / 60 }
    private var seconds: Int { secondsRemaining % 60 }
    private var totalDuration: Int { isStudyPhase ? studyDuration : breakDuration }

    var body: some View {
        VStack(spacing: ZakiySpacing.xl) {
            Capsule()
                .fill(Color.zakiyBorder)
                .frame(width: 40, height: 5)
                .padding(.top, ZakiySpacing.sm)

            Text(isStudyPhase ? "وقت التركيز 📚" : "وقت الراحة ☕️")
                .font(.zakiyHeadline)
                .foregroundStyle(Color.zakiyTextPrimary)

            ZStack {
                Circle()
                    .stroke(Color.zakiyMutedSurface, lineWidth: 14)
                Circle()
                    .trim(from: 0, to: CGFloat(secondsRemaining) / CGFloat(totalDuration))
                    .stroke(isStudyPhase ? Color.zakiyTeal : Color.zakiyMustard, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: secondsRemaining)

                Text(String(format: "%02d:%02d", minutes, seconds))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.zakiyTextPrimary)
            }
            .frame(width: 200, height: 200)
            .padding(ZakiySpacing.lg)

            HStack(spacing: ZakiySpacing.md) {
                Button(isRunning ? "إيقاف مؤقت" : "ابدأ") { isRunning.toggle() }
                    .buttonStyle(.zakiyPrimary)

                Button("إعادة تعيين") { reset() }
                    .buttonStyle(.zakiySecondary)
            }

            Spacer()
        }
        .padding(ZakiySpacing.xl)
        .background(Color.zakiyBackground.ignoresSafeArea())
        .onReceive(timer) { _ in
            guard isRunning else { return }
            if secondsRemaining > 0 {
                secondsRemaining -= 1
            } else {
                isStudyPhase.toggle()
                secondsRemaining = totalDuration
            }
        }
    }

    private func reset() {
        isRunning = false
        isStudyPhase = true
        secondsRemaining = studyDuration
    }
}

#Preview {
    PomodoroTimerView()
}
