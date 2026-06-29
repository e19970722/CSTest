//
//  APIService.swift
//  CSTest
//
//  Created by Yen Lin on 2026/6/29.
//

import Foundation
import Combine

enum HTTPMethod: String {
    case GET, POST, DELETE, PUT
}

enum NetworkError: Error {
    case invalidURL
    case timeout
    case serverError(_ code: Int)
    case decodingError(_ error: Error)
    case responseError
    case unknown(_ error: Error)
}

protocol APIServiceType {
    func fetchItems() -> AnyPublisher<[User], Error>
}

class APIService: APIServiceType {
    
    func fetchItems() -> AnyPublisher<[User], Error> {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/users") else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.httpMethod = HTTPMethod.GET.rawValue
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let httpResponse = output.response as? HTTPURLResponse,
                      !output.data.isEmpty else {
                    throw NetworkError.responseError
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.serverError(httpResponse.statusCode)
                }
                return output.data
            }
            .decode(type: [User].self, decoder: JSONDecoder())
            .mapError{ error -> NetworkError in
                switch error {
                case let urlError as URLError where urlError.code == .timedOut:
                    return .timeout
                    
                case is DecodingError:
                    return .decodingError(error)
                    
                case let networkError as NetworkError:
                    return networkError
                    
                default:
                    return .unknown(error)
                }
            }
            .eraseToAnyPublisher()
    }
}
