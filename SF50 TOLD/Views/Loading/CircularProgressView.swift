import SwiftUI

struct CircularProgressView: View {
  var progress: StepProgress

  var body: some View {
    switch progress {
      case .pending:
        Circle().stroke(Color.gray.opacity(0.25), lineWidth: 4)
          .frame(width: 16, height: 16)
          .accessibilityLabel("Pending")
      case .inProgress(let progress):
        ZStack {
          Circle().stroke(Color.gray.opacity(0.25), lineWidth: 4)
          Circle()
            .trim(from: 0, to: CGFloat(progress))
            .stroke(Color.gray, style: .init(lineWidth: 4, lineCap: .round))
            .rotationEffect(.degrees(-90))
        }.frame(width: 16, height: 16)
          .accessibilityLabel("Progress: \(progress, format: .percent)")
      case .indeterminate:
        ProgressView().frame(width: 16, height: 16)
      case .complete:
        Image(systemName: "checkmark.circle.fill")
          .resizable()
          .foregroundStyle(.gray)
          .frame(width: 20, height: 20)
          .accessibilityLabel("Complete")
    }
  }
}

enum StepProgress: Equatable {
  case pending
  case inProgress(progress: Float)
  case indeterminate
  case complete

  var isLoading: Bool {
    switch self {
      case .pending: return false
      case .inProgress: return true
      case .indeterminate: return true
      case .complete: return false
    }
  }
}

#Preview {
  VStack {
    CircularProgressView(progress: .pending)
    CircularProgressView(progress: .indeterminate)
    CircularProgressView(progress: .inProgress(progress: 0.3))
    CircularProgressView(progress: .complete)
  }
}
