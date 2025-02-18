import Foundation
#if canImport(Combine)
import Combine
#else
import OpenCombine
import OpenCombineDispatch
import OpenCombineFoundation

#endif

private extension SpotifyAPI where
    AuthorizationManager: SpotifyScopeAuthorizationManager
{
    
    func saveItemsForCurrentUser(
        uris: [SpotifyURIConvertible],
        type: IDCategory,
        path: String
    ) -> AnyPublisher<Void, Error> {
        
        do {
            
            if uris.isEmpty {
                return ResultPublisher(())
                    .eraseToAnyPublisher()
            }
            
            let idsString = try SpotifyIdentifier
                .commaSeparatedIdsString(
                    uris, ensureCategoryMatches: [type]
                )
            
            return self.apiRequest(
                path: path,
                queryItems: ["ids": idsString],
                httpMethod: "PUT",
                makeHeaders: Headers.bearerAuthorizationAndContentTypeJSON(_:),
                bodyData: nil,
                requiredScopes: [.userLibraryModify]
            )
            .decodeSpotifyErrors()
            .map { _, _ in }
            .eraseToAnyPublisher()
            
        } catch {
            return error.anyFailingPublisher()
        }
        
    }
    
    func removeItemsForCurrentUser(
        uris: [SpotifyURIConvertible],
        type: IDCategory,
        path: String,
        market: String? = nil
    ) -> AnyPublisher<Void, Error> {
        
        do {
            
            if uris.isEmpty {
                return ResultPublisher(())
                    .eraseToAnyPublisher()
            }
            
            let idsString = try SpotifyIdentifier
                .commaSeparatedIdsString(
                    uris, ensureCategoryMatches: [type]
                )
            
            return self.apiRequest(
                path: path,
                queryItems: [
                    "ids": idsString,
                    "market": market
                ],
                httpMethod: "DELETE",
                makeHeaders: Headers.bearerAuthorization(_:),
                bodyData: nil,
                requiredScopes: [.userLibraryModify]
            )
            .decodeSpotifyErrors()
            .map { _, _ in }
            .eraseToAnyPublisher()
            
        } catch {
            return error.anyFailingPublisher()
        }

    }

    func currentUserLibraryContains(
        uris: [SpotifyURIConvertible],
        type: IDCategory,
        path: String
    ) -> AnyPublisher<[Bool], Error> {
        
        do {
            
            if uris.isEmpty {
                return ResultPublisher([])
                    .eraseToAnyPublisher()
            }
            
            let idsString = try SpotifyIdentifier
                .commaSeparatedIdsString(
                    uris, ensureCategoryMatches: [type]
                )
            
            return self.getRequest(
                path: path,
                queryItems: ["ids": idsString],
                requiredScopes: [.userLibraryRead]
            )
            .decodeSpotifyObject([Bool].self)
            
        } catch {
            return error.anyFailingPublisher()
        }

    }
    
}

public extension SpotifyAPI where
    AuthorizationManager: SpotifyScopeAuthorizationManager
{

    // MARK: Library (Requires Authorization Scopes)
    
    /**
     Get the saved albums for the current user.
     
     See also `currentUserSavedAlbumsContains(_:)`.
     
     This endpoint requires the `userLibraryRead` scope.
     
     To get just the albums, use:
     ```
     results.items.map(\.item)
     ```
     
     Read more at the [Spotify web API reference][1].
     
     - Parameters:
       - limit: *Optional*. The maximum number of albums to return.
             Default: 20; Minimum: 1; Maximum: 50.
       - offset: *Optional*. The index of the first album to return.
             Default: 0. Use with `limit` to get the next set of albums.
       - market: *Optional*. An [ISO 3166-1 alpha-2 country code][2] or
             the string "from_token". Provide this parameter if you want
             to apply [Track Relinking][3].
     - Returns: An array of the full versions of `Album` objects wrapped in
           a `SavedItem` object, wrapped in a `PagingObject`.
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/library/get-users-saved-albums/
     [2]: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
     [3]: https://developer.spotify.com/documentation/general/guides/track-relinking-guide/
     */
    func currentUserSavedAlbums(
        limit: Int? = nil,
        offset: Int? = nil,
        market: String? = nil
    ) -> AnyPublisher<PagingObject<SavedItem<Album>>, Error> {
        
        return self.getRequest(
            path: "/me/albums",
            queryItems: [
                "limit": limit,
                "offset": offset,
                "market": market
            ],
            requiredScopes: [.userLibraryRead]
        )
        .decodeSpotifyObject(PagingObject<SavedItem<Album>>.self)
        
    }

    /**
     Get the saved tracks for the current user.
     
     See also `currentUserSavedTracksContains(_:)`.
     
     This endpoint requires the `userLibraryRead` scope.
     
     To get just the tracks, use:
     ```
     results.items.map(\.item)
     ```
     
     Read more at the [Spotify web API reference][1].
     
     - Parameters:
       - limit: *Optional*. The maximum number of tracks to return.
             Default: 20; Minimum: 1; Maximum: 50.
       - offset: *Optional*. The index of the first track to return.
             Default: 0. Use with `limit` to get the next
             set of tracks.
       - market: *Optional*. An [ISO 3166-1 alpha-2 country code][2] or
             the string "from_token". Provide this parameter if you want
             to apply [Track Relinking][3].
     - Returns: An array of the full versions of `Track` objects wrapped in
           a `SavedItem` object, wrapped in a `PagingObject`.
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/library/get-users-saved-tracks/
     [2]: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
     [3]: https://developer.spotify.com/documentation/general/guides/track-relinking-guide/
     */
    func currentUserSavedTracks(
        limit: Int? = nil,
        offset: Int? = nil,
        market: String? = nil
    ) -> AnyPublisher<PagingObject<SavedItem<Track>>, Error> {
        
        return self.getRequest(
            path: "/me/tracks",
            queryItems: [
                "limit": limit,
                "offset": offset,
                "market": market
            ],
            requiredScopes: [.userLibraryRead]
        )
        .decodeSpotifyObject(PagingObject<SavedItem<Track>>.self)
        
    }
    
    /**
     Get the saved shows for the current user.
     
     See also `currentUserSavedShowsContains(_:)`.
     
     This endpoint requires the `userLibraryRead` scope.
     
     To get just the shows, use:
     ```
     results.items.map(\.item)
     ```
     
     Read more at the [Spotify web API reference][1].
     
     - Parameters:
       - limit: *Optional*. The maximum number of shows to return.
             Default: 20; Minimum: 1; Maximum: 50.
       - offset: *Optional*. The index of the first show to return.
             Default: 0. Use with `limit` to get the next set of shows.
       - market: *Optional*. An [ISO 3166-1 alpha-2 country code][2] or
             the string "from_token". Provide this parameter if you want
             to apply [Track Relinking][3].
     - Returns: An array of the full versions of `Show` objects wrapped in
           a `SavedItem` object, wrapped in a `PagingObject`.
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/library/get-users-saved-shows/
     [2]: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
     [3]: https://developer.spotify.com/documentation/general/guides/track-relinking-guide/
     */
    func currentUserSavedShows(
        limit: Int? = nil,
        offset: Int? = nil,
        market: String? = nil
    ) -> AnyPublisher<PagingObject<SavedItem<Show>>, Error> {
        
        return self.getRequest(
            path: "/me/shows",
            queryItems: [
                "limit": limit,
                "offset": offset,
                "market": market
            ],
            requiredScopes: [.userLibraryRead]
        )
        .decodeSpotifyObject(PagingObject<SavedItem<Show>>.self)
        
    }
    
    /**
     Check if one or more albums is saved in the current user's
     "Your Music" library.
     
     This endpoint requires the `userLibraryRead` scope.
     
     Read more at the [Spotify web API reference][1].
     
     - Parameter uris: An array of album URIs. Maximum: 50.
           Duplicate albums in the request will result in
           duplicate values in the response. A single invalid URI causes
           the entire request to fail. Passing in an empty array will
           immediately cause an empty array of results to be returned
           without a network request being made.
     - Returns: An array of `true` or `false` values,
           in the order requested, indicating whether the user's
           library contains each album.
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/library/check-users-saved-albums/
     */
    func currentUserSavedAlbumsContains(
        _ uris: [SpotifyURIConvertible]
    ) -> AnyPublisher<[Bool], Error> {
        
        return self.currentUserLibraryContains(
            uris: uris, type: .album, path: "/me/albums/contains"
        )

    }
    
    /**
     Check if one or more tracks is saved in the current user's
     "Your Music" library.
     
     This endpoint requires the `userLibraryRead` scope.
     
     Read more at the [Spotify web API reference][1].
     
     - Parameter uris: An array of track URIs. Maximum: 50.
           Duplicate tracks in the request will result in
           duplicate values in the response. A single invalid URI causes
           the entire request to fail. Passing in an empty array will
           immediately cause an empty array of results to be returned
           without a network request being made.
     - Returns: An array of `true` or `false` values,
           in the order requested, indicating whether the user's
           library contains each track.
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/library/check-users-saved-tracks/
     */
    func currentUserSavedTracksContains(
        _ uris: [SpotifyURIConvertible]
    ) -> AnyPublisher<[Bool], Error> {
        
        return self.currentUserLibraryContains(
            uris: uris, type: .track, path: "/me/tracks/contains"
        )

    }
    
    /**
     Check if one or more shows is saved in the current user's
     "Your Music" library.
     
     This endpoint requires the `userLibraryRead` scope.
     
     Read more at the [Spotify web API reference][1].
     
     - Parameter uris: An array of show URIs. Maximum: 50.
           Duplicate shows in the request will result in
           duplicate values in the response. A single invalid URI causes
           the entire request to fail. Passing in an empty array will
           immediately cause an empty array of results to be returned
           without a network request being made.
     - Returns: An array of `true` or `false` values,
           in the order requested, indicating whether the user's
           library contains each show.
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/library/check-users-saved-shows/
     */
    func currentUserSavedShowsContains(
        _ uris: [SpotifyURIConvertible]
    ) -> AnyPublisher<[Bool], Error> {
        
        return self.currentUserLibraryContains(
            uris: uris, type: .show, path: "/me/shows/contains"
        )

    }

    /**
     Save albums for the current user.
     
     This endpoint requires the `userLibraryModify` scope.
     
     Read more at the [Spotify web API reference][1].
     
     - Parameter uris: An array of album URIs. Maximum: 50.
           Duplicates will be ignored. A single invalid URI causes
           the entire request to fail. Passing in an empty array will
           prevent a network request from being made.
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/library/save-albums-user/
     */
    func saveAlbumsForCurrentUser(
        _ uris: [SpotifyURIConvertible]
    ) -> AnyPublisher<Void, Error> {

        return self.saveItemsForCurrentUser(
            uris: uris, type: .album, path: "/me/albums"
        )
        
    }
    
    /**
     Save tracks for the current user.
     
     This endpoint requires the `userLibraryModify` scope.
     
     Read more at the [Spotify web API reference][1].
     
     - Parameter uris: An array of track URIs. Maximum: 50.
           Duplicates will be ignored. A single invalid URI causes
           the entire request to fail. Passing in an empty array will
           prevent a network request from being made.
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/library/save-tracks-user/
     */
    func saveTracksForCurrentUser(
        _ uris: [SpotifyURIConvertible]
    ) -> AnyPublisher<Void, Error> {

        return self.saveItemsForCurrentUser(
            uris: uris, type: .track, path: "/me/tracks"
        )
        
    }
    
    /**
     Save shows for the current user.
     
     This endpoint requires the `userLibraryModify` scope.
     
     Read more at the [Spotify web API reference][1].
     
     - Parameter uris: An array of show URIs. Maximum: 50.
           Duplicates will be ignored. A single invalid URI causes
           the entire request to fail. Passing in an empty array will
           prevent a network request from being made.
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/library/save-shows-user/
     */
    func saveShowsForCurrentUser(
        _ uris: [SpotifyURIConvertible]
    ) -> AnyPublisher<Void, Error> {

        return self.saveItemsForCurrentUser(
            uris: uris, type: .show, path: "/me/shows"
        )
        
    }
    
    /**
     Remove saved albums for the current user.
     
     This endpoint requires the `userLibraryModify` scope.
     
     Read more at the [Spotify web API reference][1].
     
     - Parameter uris: An array of album URIs. Maximum: 50.
           Duplicates will be ignored. A single invalid URI causes
           the entire request to fail. Passing in an empty array will
           prevent a network request from being made.
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/library/remove-albums-user/
     */
    func removeSavedAlbumsForCurrentUser(
        _ uris: [SpotifyURIConvertible]
    ) -> AnyPublisher<Void, Error> {
        
        return self.removeItemsForCurrentUser(
            uris: uris, type: .album, path: "/me/albums", market: nil
        )
    }
    
    /**
     Remove saved tracks for the current user.
     
     This endpoint requires the `userLibraryModify` scope.
     
     Read more at the [Spotify web API reference][1].
     
     - Parameter uris: An array of track URIs. Maximum: 50.
           Duplicates will be ignored. A single invalid URI causes
           the entire request to fail. Passing in an empty array will
           prevent a network request from being made.
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/library/remove-tracks-user/
     */
    func removeSavedTracksForCurrentUser(
        _ uris: [SpotifyURIConvertible]
    ) -> AnyPublisher<Void, Error> {
        
        return self.removeItemsForCurrentUser(
            uris: uris, type: .track, path: "/me/tracks", market: nil
        )
    }
    
    /**
     Remove saved shows for the current user.
     
     This endpoint requires the `userLibraryModify` scope.
     
     Read more at the [Spotify web API reference][1].
     
     - Parameters:
       - uris: An array of album URIs. Maximum: 50.
             Duplicates will be ignored. A single invalid URI causes
             the entire request to fail. Passing in an empty array will
             prevent a network request from being made.
       - market: *Optional*. An [ISO 3166-1 alpha-2 country code][2].
             If a country code is specified, only shows that are available
             in that market will be removed. If a valid user access token is
             specified in the request header, the country associated with the
             user account will take priority over this parameter.
             Note: If neither market or user country are provided, the content
             is considered unavailable for the client. Users can view the country
             that is associated with their account in the [account settings][3].
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/library/remove-shows-user/
     [2]: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
     [3]: https://www.spotify.com/account/overview/
     */
    func removeSavedShowsForCurrentUser(
        _ uris: [SpotifyURIConvertible],
        market: String? = nil
    ) -> AnyPublisher<Void, Error> {
        
        return self.removeItemsForCurrentUser(
            uris: uris, type: .show, path: "/me/shows", market: market
        )
    }

}
