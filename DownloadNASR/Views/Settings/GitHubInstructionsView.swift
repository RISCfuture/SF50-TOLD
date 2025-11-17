//
//  GitHubTokenInstructions.swift
//  DownloadNASR
//
//  Instructions for creating a GitHub Personal Access Token
//

import SwiftUI

struct GitHubInstructionsView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("How to create a token:")
        .font(.headline)

      VStack(alignment: .leading, spacing: 4) {
        InstructionStep(number: 1) {
          Text(
            "Go to GitHub Settings → Developer settings → Personal access tokens → Fine-grained tokens"
          )
        }
        InstructionStep(number: 2) {
          Text("Click “Generate new token”")
        }
        InstructionStep(number: 3) {
          Text("Set repository access to “Only select repositories”")
        }
        InstructionStep(number: 4) {
          Text("Select “RISCfuture/SF50-TOLD-Airports”")
        }
        InstructionStep(number: 5) {
          Text("Under “Repository permissions”, give “Contents” Read and Write access")
        }
        InstructionStep(number: 6) {
          Text("Generate token and paste it above")
        }
      }
      .font(.caption)
      .foregroundStyle(.secondary)

      Link(destination: URL(string: "https://github.com/settings/personal-access-tokens/new")!) {
        Label("Open GitHub Token Settings", systemImage: "arrow.up.right.square")
          .font(.caption)
      }
      .padding(.top, 4)
    }
    .padding()
    .background {
      RoundedRectangle(cornerRadius: 8)
        .fill(.regularMaterial)
    }
  }
}

struct InstructionStep<Content: View>: View {
  let number: Int
  let content: Content

  var body: some View {
    HStack(alignment: .top, spacing: 6) {
      Text("\(number, format: .number).")
        .fontWeight(.medium)
        .frame(width: 16, alignment: .trailing)
      content
    }
  }

  init(number: Int, @ViewBuilder content: () -> Content) {
    self.number = number
    self.content = content()
  }
}

#Preview {
  GitHubInstructionsView()
    .padding()
}
