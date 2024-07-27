//
//  SetupVisionView.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 27/7/24.
//

import SwiftUI

struct SetupVisionView: View {
    @Binding var stage: SetupStage

    var body: some View {
        VStack(spacing: 10) {
            Text("Are you visually impaired?")
                .font(.title)
                .bold()

            Text(
"""
BeMyHands is built for the visually impaired, to automate simple actions \
that are tedious to do with accessibility tech
"""
            )
            .frame(width: 300)
            .font(.caption)

            Spacer()
                .frame(height: 30)

            HStack {
                Button {
                    stage = .setupAccessManager
                } label: {
                    Text("Sighted 👁️")
                        .frame(width: 100, height: 40)
                        .padding(4)
                        .background {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.blue.opacity(0.7))
                        }
                }

                Button {
                    stage = .setupAccessManager
                } label: {
                    Text("Mildly visually impaired 👓")
                        .frame(width: 100, height: 40)
                        .padding(4)
                        .background {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.green.opacity(0.7))
                        }
                }

                Button {
                    stage = .setupAccessManager
                } label: {
                    Text("Visually impaired 🕶️")
                        .frame(width: 100, height: 40)
                        .padding(4)
                        .background {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.orange.opacity(0.7))
                        }
                }

                Button {
                    stage = .setupAccessManager
                } label: {
                    Text("Fully blind ❌")
                        .frame(width: 100, height: 40)
                        .padding(4)
                        .background {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.indigo.opacity(0.7))
                        }
                }
            }
            .buttonStyle(.plain)
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    SetupVisionView(stage: .constant(.blindOrNot))
}
