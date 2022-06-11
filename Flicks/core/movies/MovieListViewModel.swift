//
//  MovieListViewModel.swift
//  Flicks
//
//  Created by Noel Obaseki on 25/04/2022.
//

import Foundation
import Combine


final class MovieListViewModel: ObservableObject {
    
    @Published var isLoading = false
    @Published var isRefreshing = false

    @Published var dataType: DataType = .noData
    @Published var error: Error? = nil
    
    @Published var isOffline = false
    @Published var showNoData = false
    
    @Published var category: Endpoints.Movies.Category = .popular {
        didSet {
            getMovies()
        }
    }
    
    
    
    
    private lazy var showOfflineView: AnyPublisher<Bool, Never> = {
        Publishers
            .CombineLatest3(self.$dataType, self.$isLoading, self.$isRefreshing)
            .map { element in
                if element.0 == .cached, !element.1, !element.2 {
                    return true
                } else {
                    return false
                }
            }
            .eraseToAnyPublisher()
    }()
    
    private lazy var showNoDataLabel: AnyPublisher<Bool, Never> = {
        Publishers
            .CombineLatest(self.$dataType, self.$isLoading)
            .map { element in
                if element.0 == .noData, !element.1 {
                    return true
                } else {
                    return false
                }
            }
            .eraseToAnyPublisher()
    }()
    
    
  //  var category: Endpoints.Movies.Category = .popular
    
    private let moviesStore: MovieListProtocol
    
    private var cancellableSet: Set<AnyCancellable> = []
    
    init(moviesStore: MovieListProtocol = MovieListService()) {
        self.moviesStore = moviesStore
        
        showOfflineView.assign(to: &self.$isOffline)
        showNoDataLabel.assign(to: &self.$showNoData)
        
//        NotificationCenter.default.publisher(for: .reachabilityChanged)
//            .sink(receiveValue: { [weak self] (notification) in
//                guard let self = self, let reachability = notification.object as? Reachability,
//                      reachability.connection != .unavailable, self.showNoData else { return }
//                self.getMovies()
//            })
//            .store(in: &cancellableSet)
        
        bindStore()
        getMovies()
    }
    
    func bindStore() {
        moviesStore
            .moviesResponseSubject
            .sink { [weak self] (completion) in
                switch completion {
                case .finished: break
                case .failure(let error):
                    self?.error = error
                }
            } receiveValue: { [weak self] (moviesStoreResult) in
                self?.isLoading = false
                self?.isRefreshing = false
                self?.dataType = moviesStoreResult.dataType
            }.store(in: &cancellableSet)
    }
    
    func loadMoviesIfNeeded() {
        guard self.dataType == .cached else { return }
        self.getMovies()
    }
        
    func getMovies() {
        self.isRefreshing = self.dataType != .noData
        self.isLoading = self.dataType == .noData
        
        moviesStore.fetchMoviesList(category: category) 
    }
    
 
}
