import SwiftUI

fileprivate let indeterminate = Foundation.Progress(totalUnitCount: 0)

struct LoadingView: View {
    var progress: Foundation.Progress? = nil
    
    var body: some View {
        VStack {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 200, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            Text("Loading latest airport information…")
            ProgressView(progress ?? indeterminate)
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        let progress = Foundation.Progress(totalUnitCount: 100)
        progress.localizedDescription = ""
        progress.localizedAdditionalDescription = ""
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            progress.completedUnitCount += 1
            if progress.completedUnitCount == 101 { progress.completedUnitCount = 0}
        }
        
        return LoadingView(progress: progress)
    }
}

fileprivate enum ExampleError: Swift.Error {
    case example
}
