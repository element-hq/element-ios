import Foundation
import Combine

@available(iOS 14.0, *)
extension Publisher {
    
    func sinkDispatchTo<S, SA, IA>(_ store: StateStoreViewModel<S, SA, IA>) where SA == Output, Failure == Never {
        return self
            .subscribe(on: DispatchQueue.main)
            .sink { [weak store] (output) in
                guard let store = store else { return }
                store.dispatch(action: output)
            }
            .store(in: &store.cancellables)
    }
    
    
    func dispatchTo<S, SA, IA>(_ store: StateStoreViewModel<S, SA, IA>)  -> Publishers.HandleEvents<Publishers.SubscribeOn<Self, DispatchQueue>> where SA == Output, Failure == Never {
        return self
            .subscribe(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak store] action in
                guard let store = store else { return }
                store.dispatch(action: action)
            })
    }
}
