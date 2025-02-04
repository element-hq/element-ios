//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixSDK

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
        // Keep trying until resource changed
        while true {
            guard let url = rendezvousURL else {
                return .failure(.rendezvousURLInvalid)
            }
            
            MXLog.debug("[RendezvousTransport] polling \(url) after etag: \(String(describing: currentEtag))")
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            if let etag = currentEtag {
                request.addValue(etag, forHTTPHeaderField: "If-None-Match")
            }
            
            // Newer swift concurrency api unavailable due to iOS 14 support
            let result: Result<Data?, RendezvousTransportError> = await withCheckedContinuation { continuation in
                URLSession.shared.dataTask(with: request) { data, response, error in
                    guard error == nil,
                          let data = data,
                          let httpURLResponse = response as? HTTPURLResponse else {
                        continuation.resume(returning: .failure(.networkError))
                        return
                    }
                    
                    // Return empty data from here if unchanged so that the external while can continue
                    if httpURLResponse.statusCode == 404 {
                        MXLog.warning("[RendezvousTransport] Rendezvous no longer available")
                        continuation.resume(returning: .failure(.rendezvousCancelled))
                    } else if httpURLResponse.statusCode == 304 {
                        MXLog.debug("[RendezvousTransport] Rendezvous unchanged")
                        continuation.resume(returning: .success(nil))
                    } else if httpURLResponse.statusCode == 200 {
                        // The resouce changed, update the etag
                        if let etag = httpURLResponse.allHeaderFields["Etag"] as? String {
                            self.currentEtag = etag
                        }
                        
                        MXLog.debug("[RendezvousTransport] Received update")
                        
                        continuation.resume(returning: .success(data))
                    }
                }
                .resume()
            }

            switch result {
            case .failure(let error):
                return .failure(error)
            case .success(let data):
                guard let data = data else {
                    // Avoid making too many requests. Sleep for one second before the next attempt
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    
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
    
    func tearDown() async -> Result<(), RendezvousTransportError> {
        guard let url = rendezvousURL else {
            return .failure(.rendezvousURLInvalid)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        return await withCheckedContinuation { continuation in
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard error == nil, response as? HTTPURLResponse != nil else {
                    MXLog.warning("[RendezvousTransport] Failed tearing down rendezvous with error: \(String(describing: error))")
                    continuation.resume(returning: .failure(.networkError))
                    return
                }
                
                MXLog.debug("[RendezvousTransport] Tore down rendezvous at URL: \(url)")
                
                self?.rendezvousURL = nil
                
                continuation.resume(returning: .success(()))
            }
            .resume()
        }
    }
    
    // MARK: - Private
    
    private func send<T: Encodable>(body: T, url: URL, usingMethod method: String) async -> Result<HTTPURLResponse, RendezvousTransportError> {
        guard let bodyData = try? JSONEncoder().encode(body) else {
            return .failure(.encodingError)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        request.httpBody = bodyData
        
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        if let etag = currentEtag {
            request.addValue(etag, forHTTPHeaderField: "If-Match")
        }
        
        return await withCheckedContinuation { continuation in
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard error == nil, let httpURLResponse = response as? HTTPURLResponse else {
                    MXLog.warning("[RendezvousTransport] Failed sending data with error: \(String(describing: error))")
                    continuation.resume(returning: .failure(.networkError))
                    return
                }
                
                if let etag = httpURLResponse.allHeaderFields["Etag"] as? String {
                    self.currentEtag = etag
                }
                
                MXLog.debug("[RendezvousTransport] Sent data: \(body)")
                
                continuation.resume(returning: .success(httpURLResponse))
            }
            .resume()
        }
    }
}
