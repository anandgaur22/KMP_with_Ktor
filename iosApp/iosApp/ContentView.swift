import SwiftUI
import shared

@preconcurrency
struct ContentView: View {
	@StateObject private var viewModel = PostsViewModelWrapper()
	
	var body: some View {
		NavigationView {
			Group {
				if viewModel.isLoading {
					ProgressView()
				} else {
					ScrollView {
						LazyVStack(spacing: 0) {
							ForEach(viewModel.posts, id: \.id) { post in
								PostRow(post: post)
							}
						}
						.padding(.vertical, 8)
					}
					.background(Color(.systemGroupedBackground))
				}
			}
			.navigationTitle("Posts")
		}
		.onAppear {
			viewModel.fetchPosts()
		}
	}
}

struct PostRow: View {
	let post: PostModel
	
	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			// Title with simple black text
			Text(post.title)
				.font(.headline)
				.foregroundColor(.black)
				.padding(12)
				.frame(maxWidth: .infinity, alignment: .leading)
			
			// Body with card style
			Text(post.body)
				.font(.subheadline)
				.foregroundColor(.secondary)
				.lineLimit(3)
				.padding(.horizontal, 4)
			
			// Bottom info
			HStack {
				Image(systemName: "person.circle.fill")
					.foregroundColor(.blue)
				Text("User \(post.userId)")
					.font(.caption)
					.foregroundColor(.gray)
				
				Spacer()
				
				Image(systemName: "doc.text")
					.foregroundColor(.blue)
				Text("Post #\(post.id)")
					.font(.caption)
					.foregroundColor(.gray)
			}
			.padding(.top, 8)
			.padding(.horizontal, 4)
		}
		.padding(16)
		.background(
			RoundedRectangle(cornerRadius: 12)
				.fill(Color(.systemBackground))
				.shadow(
					color: Color.black.opacity(0.1),
					radius: 5,
					x: 0,
					y: 2
				)
		)
		.padding(.horizontal, 16)
		.padding(.vertical, 8)
	}
}

class PostsViewModelWrapper: ObservableObject {
	private let viewModel: PostsViewModel
	@Published var posts: [PostModel] = []
	@Published var isLoading = true
	
	init() {
		viewModel = PostsViewModel()
		observeViewModel()
	}
	
	private func observeViewModel() {
		// Observe posts using FlowCollector
		Task { @MainActor in
			do {
				let collector = FlowCollector<[PostModel]> { [weak self] posts in
					self?.posts = posts
				}
				try await viewModel.posts.collect(collector: collector)
			} catch {
				print("Error collecting posts: \(error)")
			}
		}
		
		// Observe loading state using FlowCollector
		Task { @MainActor in
			do {
				let collector = FlowCollector<Bool> { [weak self] isLoading in
					self?.isLoading = isLoading
				}
				try await viewModel.isLoading.collect(collector: collector)
			} catch {
				print("Error collecting loading state: \(error)")
			}
		}
		
		viewModel.fetchPosts()
	}
	
	func fetchPosts() {
		viewModel.fetchPosts()
	}
	
	deinit {
		viewModel.onCleared()
	}
}

// Update FlowCollector implementation
class FlowCollector<T>: Kotlinx_coroutines_coreFlowCollector {
	private let callback: (T) -> Void
	
	init(callback: @escaping (T) -> Void) {
		self.callback = callback
	}
	
	func emit(value: Any?) async throws {
		if let value = value as? T {
			callback(value)
		}
	}
	
	// Required by protocol
	func collect(value: Any?, completionHandler: @escaping (Any?, Error?) -> Void) {
		Task {
			do {
				try await emit(value: value)
				completionHandler(true, nil)
			} catch {
				completionHandler(nil, error)
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}