//
//  UserViewModel.swift
//  CSTest
//
//  Created by Yen Lin on 2026/6/29.
//

import Foundation
import Combine

class UserViewModel {
    enum Input {
        case fetchItems
    }
    
    enum Output {
        case fetchItemsSuccess
        case fetchItemsFailed(_ error: Error)
    }
    
    var users: [User] = []
    let output: PassthroughSubject<Output, Never> = .init()
    
    private let service: APIServiceType
    private var cancellables = Set<AnyCancellable>()
    
    init(service: APIServiceType = APIService()) {
        self.service = service
    }
    
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .fetchItems:
                handleFetchItems()
            }
        }
        .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
    func handleFetchItems() {
        service.fetchItems()
            .sink { [weak self] completion in
                guard let self = self else { return }
                if case .failure(let error) = completion {
                    self.output.send(.fetchItemsFailed(error))
                }
                
            } receiveValue: { [weak self] users in
                guard let self = self else { return }
                self.users = users.count >= 3 ? Array(users.prefix(3)) : users
                self.output.send(.fetchItemsSuccess)
            }
            .store(in: &cancellables)
    }
}
