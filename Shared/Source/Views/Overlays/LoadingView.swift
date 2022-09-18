import SwiftUI

fileprivate let indeterminate = Foundation.Progress(totalUnitCount: 0)

struct LoadingView: View {
    var downloadProgress: StepProgress
    var decompressProgress: StepProgress
    var processingProgress: StepProgress
    
    var body: some View {
        VStack {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 200, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            Text("Loading latest airport information…")
                .padding(.bottom, 20)
            
            if #available(iOS 16.0, *) {
                Grid(alignment: .leading) {
                    GridRow {
                        CircularProgressView(progress: downloadProgress)
                        Text(downloadProgress == .complete ? "Downloaded" : "Downloading…")
                            .foregroundColor(downloadProgress == .pending ? .secondary : .primary)
                    }
                    
                    GridRow {
                        CircularProgressView(progress: decompressProgress)
                        Text(decompressProgress == .complete ? "Decompressed" : "Decompressing…")
                            .foregroundColor(decompressProgress == .pending ? .secondary : .primary)
                    }
                    
                    GridRow {
                        CircularProgressView(progress: processingProgress)
                        Text(processingProgress == .complete ? "Processed" : "Processing…")
                            .foregroundColor(processingProgress == .pending ? .secondary : .primary)
                    }
                }
            } else {
                VStack(alignment: .leading) {
                    HStack {
                        CircularProgressView(progress: downloadProgress)
                        Text(downloadProgress == .complete ? "Downloaded" : "Downloading…")
                            .foregroundColor(downloadProgress == .pending ? .secondary : .primary)
                    }
                    
                    HStack {
                        CircularProgressView(progress: decompressProgress)
                        Text(decompressProgress == .complete ? "Decompressed" : "Decompressing…")
                            .foregroundColor(decompressProgress == .pending ? .secondary : .primary)
                    }
                    
                    HStack {
                        CircularProgressView(progress: processingProgress)
                        Text(processingProgress == .complete ? "Processed" : "Processing…")
                            .foregroundColor(processingProgress == .pending ? .secondary : .primary)
                    }
                }
            }
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView(downloadProgress: .complete,
                    decompressProgress: .indeterminate,
                    processingProgress: .pending)
    }
}

fileprivate enum ExampleError: Swift.Error {
    case example
}
