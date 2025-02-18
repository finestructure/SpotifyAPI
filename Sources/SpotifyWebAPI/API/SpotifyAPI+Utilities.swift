import Foundation
#if canImport(Combine)
import Combine
#else
import OpenCombine
import OpenCombineDispatch
import OpenCombineFoundation
#endif
import Logging

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public extension SpotifyAPI {

    // MARK: Utilities
    
    /**
     Retrieves the data linked to by an href and decodes it
     into `responseType`.
     
     An href is a URL provided in many of the responses from
     the Spotify web API which links to addtional data instead of
     including it in the current response in order to limit the size.
     
     Always prefer using a different method whenever possible because
     this method adds the additional complexity of determining the
     appropriate `ResponseType`.
     
     - Parameters:
       - href: The full URL to a Spotify web API endpoint.
       - responseType: The expected response from the server.
     - Returns: The data decoded into `responseType`.
     */
    func getFromHref<ResponseType: Decodable>(
        _ href: String,
        responseType: ResponseType.Type
    ) -> AnyPublisher<ResponseType, Error> {
        
        do {
            
            guard let url = URL(string: href, sortQueryItems: true) else {
                throw SpotifyLocalError.other(
                    #"couldn't convert href to URL: "\#(href)""#
                )
            }
            
            return self.refreshTokensAndEnsureAuthorized(for: [])
                .flatMap { accessToken -> AnyPublisher<ResponseType, Error> in
                    
                    self.apiRequestLogger.trace(
                        #"GET request to href: "\#(url)""#
                    )
                    
                    return URLSession.shared.dataTaskPublisher(
                        url: url,
                        httpMethod: "GET",
                        headers: Headers.bearerAuthorization(accessToken)
                    )
                    .decodeSpotifyObject(ResponseType.self)
                }
                .eraseToAnyPublisher()
        
        } catch {
            return error.anyFailingPublisher()
        }
        
    }

    /**
     Retrieves additional pages of results from a `Paginated` type.
     
     This method is also available as a combine operator (same name)
     for all publishers where `Output`: `Paginated`.
     
     This method immediately republishes the page of results that
     were passed in and then begins requesting additional pages.
     Each time an additional page is received, its `next` property
     is used to retrieve the next page of results, and so on, until
     `next` is `nil` or `maxExtraPages` is reached. This means that
     the next page will not be requested until the previous one
     is received. This also means that the pages will always be
     returned in order.
     
     - Parameters:
       - results: A `Paginated` type; that is, a type that contains
             a link for retrieving the next page of results.
       - maxExtraPages: The maximum number of additional pages to retrieve.
             For example, to just get the next page, use `1`. Leave as
             `nil` (default) to retrieve all pages of results.
     - Returns: A publisher that immediately republishes the `results`
           that were passed in, as well as additional pages that are
           returned by the Spotify web API.
     */
    func extendPages<PaginatedResults: Paginated>(
        _ results: PaginatedResults, maxExtraPages: Int? = nil
    ) -> AnyPublisher<PaginatedResults, Error> {

        // indicates that there are no more pages to return
        let emptyCompletionPublisher = Empty<PaginatedResults, Error>(
            completeImmediately: true
        )
        .eraseToAnyPublisher()
        
        var nextPageIndex = 1
        
        let currentPageSubject =
                CurrentValueSubject<PaginatedResults, Error>(results)
        
        let nextPagePublisher = currentPageSubject
            .flatMap { nextPage -> AnyPublisher<PaginatedResults, Error> in
        
                self.logger.trace("got page at index \(nextPageIndex)")
        
                guard let next = nextPage.next else {
                    // the last page of results has been reached
                    self.logger.trace("next was nil")
                    currentPageSubject.send(completion: .finished)
                    return emptyCompletionPublisher
                }
        
                if let max = maxExtraPages, nextPageIndex > max {
                    // the maximum number of pages requested by the caller
                    // have been reached
                    self.logger.debug(
                        "nextPageIndex (\(nextPageIndex)) > maxPages (\(max))"
                    )
                    currentPageSubject.send(completion: .finished)
                    return emptyCompletionPublisher
                }
        
                nextPageIndex += 1
        
                self.logger.trace("requesting next page")
                return self.getFromHref(
                    next, responseType: PaginatedResults.self
                )
                .handleEvents(receiveOutput: currentPageSubject.send(_:))
                .eraseToAnyPublisher()
        
            }
            .eraseToAnyPublisher()
        
        return nextPagePublisher
            // A page of results (not necessarily the first) was already
            // retrieved before this method was called, so pass it through
            // to downstream subscribers.
            .prepend(results)
            .eraseToAnyPublisher()
        
    }
    
}
