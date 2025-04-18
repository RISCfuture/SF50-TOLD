import SwiftUI

struct CircularProgressView: View {
    var progress: StepProgress

    var body: some View {
        switch progress {
            case .pending:
                Circle().stroke(Color.gray.opacity(0.25), lineWidth: 4)
                    .frame(width: 16, height: 16)
                    .accessibilityLabel("Pending")
            case let .inProgress(current, total):
                ZStack {
                    Circle().stroke(Color.gray.opacity(0.25), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: (Double(current) / Double(total)))
                        .stroke(Color.gray, style: .init(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }.frame(width: 16, height: 16)
                    .accessibilityLabel("Progress: \(current) of \(total)")
            case .indeterminate:
                ProgressView().frame(width: 16, height: 16)
            case .complete:
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 20, height: 20)
                    .accessibilityLabel("Complete")
        }
    }
}

#Preview {
    VStack {
        CircularProgressView(progress: .pending)
        CircularProgressView(progress: .indeterminate)
        CircularProgressView(progress: .inProgress(current: 1, total: 3))
        CircularProgressView(progress: .complete)
    }
}
