//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

class RendezvousTransport: RendezvousTransportProtocol {
    private let baseURL: URL
    
    private var currentEtag: String?
    
    private(set) var rendezvousURL: URL? {
        didSet {
            self.currentEtag = nil
        }
    }
    
    init(baseURL: URL, rendezvousURL: URL? = nil) {
        self.baseURL = baseURL
        self.rendezvousURL = rendezvousURL
    }
    
    func get() async -> Result<Data, RendezvousTransportError> {
        guard let url = rendezvousURL else {
            return .failure(.rendezvousURLInvalid)
        }
        
        // Keep trying until resource changed
        while true {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            if let etag = currentEtag {
                request.addValue(etag, forHTTPHeaderField: "If-None-Match")
            }
            
            // Newer swift concurrency api unavailable due to iOS 14 support
            let result: Result<Data?, RendezvousTransportError> = await withCheckedContinuation { continuation in
                URLSession.shared.dataTask(with: request) { data, response, error in
                    guard let data = data,
                          let response = response,
                          let httpURLResponse = response as? HTTPURLResponse else {
                        continuation.resume(returning: .failure(.networkError))
                        return
                    }
                    
                    // Return empty data from here if unchanged so that the external while can continue
                    if httpURLResponse.statusCode == 404 {
                        continuation.resume(returning: .failure(.rendezvousCancelled))
                    } else if httpURLResponse.statusCode == 304 {
                        continuation.resume(returning: .success(nil))
                    } else if httpURLResponse.statusCode == 200 {
                        if httpURLResponse.allHeaderFields["Content-Type"] as? String != "application/json" {
                            continuation.resume(returning: .success(nil))
                        } else {
                            if let etag = httpURLResponse.allHeaderFields["Etag"] as? String {
                                self.currentEtag = etag
                            }
                            
                            continuation.resume(returning: .success(data))
                        }
                    }
                }.resume()
            }

            switch result {
            case .failure(let error):
                return .failure(error)
            case .success(let data):
                guard let data = data else {
                    continue
                }

                return .success(data)
            }
        }
    }
    
    func create<T: Encodable>(body: T) async -> Result<(), RendezvousTransportError> {
        switch await send(body: body, url: baseURL, usingMethod: "POST") {
        case .failure(let error):
            return .failure(error)
        case .success(let response):
            guard let rendezvousIdentifier = response.allHeaderFields["Location"] as? String else {
                return .failure(.networkError)
            }
            
            rendezvousURL = baseURL.appendingPathComponent(rendezvousIdentifier)
            
            return .success(())
        }
    }
    
    func send<T: Encodable>(body: T) async -> Result<(), RendezvousTransportError> {
        guard let url = rendezvousURL else {
            return .failure(.rendezvousURLInvalid)
        }
        
        switch await send(body: body, url: url, usingMethod: "PUT") {
        case .failure(let error):
            return .failure(error)
        case .success:
            return .success(())
        }
    }
    
    // MARK: - Private
    
    private func send<T: Encodable>(body: T, url: URL, usingMethod method: String) async -> Result<HTTPURLResponse, RendezvousTransportError> {
        guard let body = try? JSONEncoder().encode(body) else {
            return .failure(.encodingError)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        request.httpBody = body
        
        return await withCheckedContinuation { continuation in
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let httpURLResponse = response as? HTTPURLResponse else {
                    continuation.resume(returning: .failure(.networkError))
                    return
                }
                
                if let etag = httpURLResponse.allHeaderFields["Etag"] as? String {
                    self.currentEtag = etag
                }
                
                continuation.resume(returning: .success(httpURLResponse))
            }.resume()
        }
    }
}
