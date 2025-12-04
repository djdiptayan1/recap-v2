//
//  citations.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import SwiftUI

struct CitationsView: View {
    @StateObject private var viewModel = CitationsViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else {
                List(viewModel.citations) { citation in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(citation.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack {
                            Text(citation.authors)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(citation.year)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if !citation.journal.isEmpty {
                            Text(citation.journal)
                                .font(.caption)
                                .italic()
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
//                .listStyle(.plain)
            }
        }
        .standardBackground()
        .navigationTitle("Medical Citations")
        .task {
            await viewModel.fetchCitations()
        }
    }
}

#Preview {
    CitationsView()
}
