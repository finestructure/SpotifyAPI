import Foundation
import XCTest
#if canImport(Combine)
import Combine
#else
import OpenCombine
import OpenCombineDispatch
import OpenCombineFoundation

#endif

@testable import SpotifyWebAPI
import SpotifyAPITestUtilities
import SpotifyExampleContent

protocol SpotifyAPIPlaylistsTests: SpotifyAPITests { }

extension SpotifyAPIPlaylistsTests {

    func getCrumbPlaylist() {

        let expectation = XCTestExpectation(
            description: "getCrumbPlaylist"
        )

        let trackNames = [
            "Part III", "Plants", "Locket", "Nina", "Jinx",
            "M.R.", "And It Never Ends", "Thirty-Nine", "Cracking",
            "Recently Played", "Vinta", "Faces", "Ghostride",
            "Bones", "Fall Down"
        ]

        Self.spotify.playlist(URIs.Playlists.crumb)
            .XCTAssertNoFailure()
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { playlist in
                    encodeDecode(playlist)
                    XCTAssertEqual(playlist.name, "Crumb")
                    XCTAssertEqual(playlist.uri, "spotify:playlist:33yLOStnp2emkEA76ew1Dz")
                    XCTAssertEqual(playlist.id, "33yLOStnp2emkEA76ew1Dz")
                    guard playlist.items.items.count >= 15 else {
                        XCTFail("Crumb playlist should have at least 15 tracks")
                        return
                    }
                    let tracks = playlist.items.items.map(\.item)
                    for (i, track) in tracks.enumerated() {
                        guard trackNames.count > i else {
                            return
                        }
                        guard case .track(let track) = track else {
                            XCTFail("playlist should only contain tracks")
                            continue
                        }
                        print(i)
                        XCTAssertEqual(track.name, trackNames[i])
                    }

                }
            )
            .store(in: &Self.cancellables)

        self.wait(for: [expectation], timeout: 60)
    }

    func getCrumbPlaylistTracks() {

        let expectation = XCTestExpectation(
            description: "getCrumPlaylistTracks"
        )

        let trackNames = [
            "Nina", "Jinx", "M.R.", "And It Never Ends", "Thirty-Nine",
            "Cracking", "Recently Played", "Vinta", "Faces", "Ghostride"
        ]

        Self.spotify.authorizationManager.setExpirationDate(to: Date())

        var authChangeCount = 0
        Self.spotify.authorizationManagerDidChange
            .sink(receiveValue: {
                authChangeCount += 1
            })
            .store(in: &Self.cancellables)

        Self.spotify.playlistTracks(
            URIs.Playlists.crumb,
            limit: 10,
            offset: 3,
            market: "US"
        )
        .XCTAssertNoFailure()
        .sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { playlistTracks in
                encodeDecode(playlistTracks)
                let tracks = playlistTracks.items.map(\.item)
                XCTAssertEqual(playlistTracks.items.count, 10)
                if playlistTracks.items.count < 10 { return }

                for (i, track) in tracks.enumerated() {
                    guard let track = track else {
                        XCTFail("track should not be nil")
                        continue
                    }
                    XCTAssertEqual(track.name, trackNames[i])
                    XCTAssertEqual(track.artists?.first?.name, "Crumb")
                    XCTAssertEqual(
                        track.artists?.first?.uri,
                        "spotify:artist:4kSGbjWGxTchKpIxXPJv0B"
                    )
                    XCTAssertEqual(
                        track.artists?.first?.id,
                        "4kSGbjWGxTchKpIxXPJv0B"
                    )

                }

            }
        )
        .store(in: &Self.cancellables)

        self.wait(for: [expectation], timeout: 60)
        XCTAssertEqual(
            authChangeCount, 1,
            "authorizationManagerDidChange should emit exactly once"
        )

    }

    func filteredPlaylist() {

        func reveivePlaylist(_ playlist: FilteredPlaylist) {
            encodeDecode(playlist)
            XCTAssertEqual(playlist.name, "Mac DeMarco")
            XCTAssertEqual(playlist.uri, "spotify:playlist:6oyVZ3dZZVCkXJm451Hj5v")
            XCTAssertEqual(playlist.ownerDisplayName, "petervschorn")
            let artists = playlist.tracks.flatMap(\.artists)
            for artist in artists {
                XCTAssertEqual(artist.name, "Mac DeMarco")
                XCTAssertEqual(artist.type, .artist)
                XCTAssertEqual(artist.uri, "spotify:artist:3Sz7ZnJQBIHsXLUSo0OQtM")
            }
        }

        let filters = FilteredPlaylist.filters

        let expectationTrack = XCTestExpectation(
            description: "testFilteredPlaylist [.track]"
        )

        Self.spotify.filteredPlaylist(
            URIs.Playlists.macDeMarco,
            filters: filters,
            additionalTypes: [.track]
        )
        .XCTAssertNoFailure()
        .decodeSpotifyObject(FilteredPlaylist.self)
        .XCTAssertNoFailure()
        .sink(
            receiveCompletion: { _ in expectationTrack.fulfill() },
            receiveValue: reveivePlaylist(_:)
        )
        .store(in: &Self.cancellables)

        let expectationEmpty = XCTestExpectation(
            description: "testFilteredPlaylist []"
        )

        Self.spotify.filteredPlaylist(
            URIs.Playlists.macDeMarco,
            filters: filters,
            additionalTypes: []
        )
        .XCTAssertNoFailure()
        .decodeSpotifyObject(FilteredPlaylist.self)
        .XCTAssertNoFailure()
        .sink(
            receiveCompletion: { _ in expectationEmpty.fulfill() },
            receiveValue: reveivePlaylist(_:)
        )
        .store(in: &Self.cancellables)



        self.wait(for: [expectationTrack, expectationEmpty], timeout: 120)

    }

    func filteredPlaylistItems() {

        func receivePlaylistItems(_ playlistItems: FilteredPlaylistItems) {
            encodeDecode(playlistItems)
            for item in playlistItems.items {
                XCTAssertFalse(item.name.isEmpty)
                guard let artist = item.artists.first else {
                    XCTFail("no artists found for \(item.name)")
                    continue
                }
                XCTAssertEqual(artist.name, "Men I Trust")
                XCTAssertEqual(artist.type, .artist)
                XCTAssertEqual(artist.uri, "spotify:artist:3zmfs9cQwzJl575W1ZYXeT")
            }
        }

        let filters = FilteredPlaylistItems.filters

        let expectationEmpty = XCTestExpectation(
            description: "testFilteredPlaylistItems []"
        )

        Self.spotify.filteredPlaylistItems(
            URIs.Playlists.menITrust,
            filters: filters,
            additionalTypes: []
        )
        .XCTAssertNoFailure()
        .decodeSpotifyObject(FilteredPlaylistItems.self)
        .XCTAssertNoFailure()
        .sink(
            receiveCompletion: { _ in expectationEmpty.fulfill() },
            receiveValue: receivePlaylistItems(_:)
        )
        .store(in: &Self.cancellables)

        let expectationTrack = XCTestExpectation(
            description: "testFilteredPlaylistItems [.track]"
        )

        Self.spotify.filteredPlaylistItems(
            URIs.Playlists.menITrust,
            filters: filters,
            additionalTypes: [.track]
        )
        .XCTAssertNoFailure()
        .decodeSpotifyObject(FilteredPlaylistItems.self)
        .XCTAssertNoFailure()
        .sink(
            receiveCompletion: { _ in expectationTrack.fulfill() },
            receiveValue: receivePlaylistItems(_:)
        )
        .store(in: &Self.cancellables)

        self.wait(for: [expectationEmpty, expectationTrack], timeout: 120)

    }

    func otherUserCurrentPlaylists() {

        let expectation = XCTestExpectation(
            description: "testOtherUserCUrrentPlaylists"
        )

        let user = URIs.Users.april

        Self.spotify.userPlaylists(
            for: user,
            limit: 50,
            offset: 0
        )
        .XCTAssertNoFailure()
        .extendPages(Self.spotify)
        .XCTAssertNoFailure()
        .collect()
        .sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { playlistsArray in
                encodeDecode(playlistsArray)
                let playlists = playlistsArray.flatMap(\.items)
                for playlist in playlists {
                    print("[\(playlist.name)]")
                }
                let playlist = playlists.first(where: { playlist in
                    playlist.name.strip() == "Kpop" &&
                            playlist.uri == "spotify:playlist:7p0mfgdBNyKWugXrO04WhI" &&
                            playlist.id == "7p0mfgdBNyKWugXrO04WhI"
                })

                XCTAssertNotNil(
                    playlist, "Should've found April's Kpop playlist"
                )

            }
        )
        .store(in: &Self.cancellables)


    }

    func playlistWithEpisodesAndLocalTracks() {

        func receivePlaylistItems(
            _ playlistItems: PlaylistItems,
            onlyTracks: Bool
        ) {
            internalQueue.sync {
                receivePlaylistItemsCallCount += 1
            }
            for user in playlistItems.items.map(\.addedBy) {
                guard let user = user else {
                    XCTFail("addedBy should not be nil")
                    continue
                }
                assertUserIsPeter(user)
            }

            let items = playlistItems.items.map(\.item)

            if !onlyTracks {
                encodeDecode(items)
            }

            guard items.count >= 7 else {
                XCTFail("test playlist should contain at least 7 items")
                return
            }

            if case .track(let partIII) = items[0] {
                encodeDecode(partIII)
                XCTAssertFalse(partIII.isLocal)
                XCTAssertEqual(partIII.name, "Part III")
                XCTAssertEqual(partIII.uri, "spotify:track:4HDLmWf73mge8isanCASnU")
                XCTAssertEqual(partIII.id, "4HDLmWf73mge8isanCASnU")
                XCTAssertEqual(partIII.artists?.first?.name, "Crumb")
                XCTAssertEqual(
                    partIII.artists?.first?.uri,
                    "spotify:artist:4kSGbjWGxTchKpIxXPJv0B"
                )

                XCTAssertEqual(partIII.album?.name, "Jinx")
                XCTAssertEqual(partIII.album?.uri, "spotify:album:3vukTUpiENDHDoYTVrwqtz")
                if let releaseDate = partIII.album?.releaseDate {
                    XCTAssertEqual(
                        releaseDate.timeIntervalSince1970,
                        1560470400,
                        accuracy: 43_200
                    )
                }
                else {
                    XCTFail("release date should not be nil")
                }
                XCTAssertEqual(partIII.album?.releaseDatePrecision, "day")

            }
            else {
                XCTFail("should be track: \(items[0]?.name ?? "nil")")
            }

            if case .track(let whenIGetHome) = items[1] {
                encodeDecode(whenIGetHome)
                XCTAssertFalse(whenIGetHome.isLocal)
                XCTAssertEqual(whenIGetHome.name, "When I Get Home")
                XCTAssertEqual(whenIGetHome.uri, "spotify:track:5azJUob8ahbXB3M9YFwTpd")
                XCTAssertEqual(whenIGetHome.id, "5azJUob8ahbXB3M9YFwTpd")
                XCTAssertEqual(whenIGetHome.artists?.first?.name, "Post Animal")
                XCTAssertEqual(
                    whenIGetHome.artists?.first?.uri,
                    "spotify:artist:4iaDWP59Z3e62DW7YWDbIE"
                )
                XCTAssertEqual(whenIGetHome.album?.name, "The Garden Series")
                XCTAssertEqual(
                    whenIGetHome.album?.uri,
                    "spotify:album:5YAqGppPM8omUZKyiT0FRi"
                )
                if let releaseDate = whenIGetHome.album?.releaseDate {
                    XCTAssertEqual(
                        releaseDate.timeIntervalSince1970,
                        1469145600,
                        accuracy: 43_200
                    )
                }
                else {
                    XCTFail("release date should not be nil")
                }
                XCTAssertEqual(whenIGetHome.album?.releaseDatePrecision, "day")
            }
            else {
                XCTFail("should be track: \(items[1]?.name ?? "nil")")
            }

            if let item = items[2] {
                if onlyTracks {
                    if case .track(let newReligion) = item {
                        XCTAssertEqual(newReligion.name, "#217 — The New Religion of Anti-Racism")
                        XCTAssertEqual(newReligion.uri, "spotify:episode:7nsYz7tSJryO5vVYtkKiot")
                        XCTAssertEqual(newReligion.id, "7nsYz7tSJryO5vVYtkKiot")
                    }
                    else {
                        XCTFail("should be track: \(item.name)")
                    }
                }
                else {
                    if case .episode(let newReligion) = item {
                        encodeDecode(newReligion)
                        XCTAssertEqual(newReligion.name, "#217 — The New Religion of Anti-Racism")
                        XCTAssertEqual(newReligion.uri, "spotify:episode:7nsYz7tSJryO5vVYtkKiot")
                        XCTAssertEqual(newReligion.id, "7nsYz7tSJryO5vVYtkKiot")

                        if let show = newReligion.show {
                            XCTAssertEqual(show.name, "Making Sense with Sam Harris")
                            XCTAssertEqual(show.id, "5rgumWEx4FsqIY8e1wJNAk")
                            XCTAssertEqual(show.uri, "spotify:show:5rgumWEx4FsqIY8e1wJNAk")
                            XCTAssertEqual(show.type, .show)
                            XCTAssertEqual(
                                show.href,
                                "https://api.spotify.com/v1/shows/5rgumWEx4FsqIY8e1wJNAk"
                            )
                        }
                        else {
                            XCTFail("episode should contain show")
                        }
                    }
                    else {
                        XCTFail("should be episode: \(item.name)")
                    }
                }

            }
            else {
                print("third item should not be nil")
                XCTFail("third item should not be nil")
            }


            if case .track(let bensound) = items[3] {
                encodeDecode(bensound)
                XCTAssertEqual(bensound.name, "bensound-anewbeginning")
                XCTAssertTrue(bensound.isLocal)
                XCTAssertEqual(bensound.durationMS, 154000)
            }
            else {
                XCTFail("should be track: \(items[3]?.name ?? "nil")")
            }

            if case .track(let echoes) = items[4] {
                encodeDecode(echoes)
                XCTAssertEqual(echoes.name, "Echoes - Acoustic Version")
                XCTAssertTrue(echoes.isLocal)
                XCTAssertEqual(echoes.durationMS, 348000)
            }
            else {
                XCTFail("should be track: \(items[4]?.name ?? "nil")")
            }

            if case .track(let oceanBloom) = items[5] {
                encodeDecode(oceanBloom)
                XCTAssertEqual(
                    oceanBloom.name,
                    "Hans Zimmer & Radiohead - Ocean Bloom (full song HQ)"
                )
                XCTAssertTrue(oceanBloom.isLocal)
                XCTAssertEqual(oceanBloom.durationMS, 315000)
            }
            else {
                XCTFail("should be track: \(items[5]?.name ?? "nil")")
            }

            if case .track(let killshot) = items[6] {
                encodeDecode(killshot)
                XCTAssertEqual(killshot.name, "Killshot")
                XCTAssertTrue(killshot.isLocal)
                XCTAssertEqual(killshot.durationMS, 253000)
                if let artist = killshot.artists?.first {
                    XCTAssertEqual(artist.name, "Eminem")
                    XCTAssertEqual(artist.type, .artist)
                }
                else {
                    XCTFail("should have found artist 'Eminiem'")
                }
            }
            else {
                XCTFail("should be track: \(items[6]?.name ?? "nil")")
            }


        }

        let decodeLogLevel = spotifyDecodeLogger.logLevel
        spotifyDecodeLogger.logLevel = .trace

        let internalQueue = DispatchQueue(
            label: "testPlaylistWithEpisodesAndLocalTracks internal"
        )

        var receivePlaylistItemsCallCount = 0

        let playlistExpectation = XCTestExpectation(
            description: "testPlaylistWithEpisodesAndLocalTracks: playlist"
        )

        Self.spotify.playlist(URIs.Playlists.test, market: "us")
            .XCTAssertNoFailure()
            .sink(
                receiveCompletion: { _ in playlistExpectation.fulfill() },
                receiveValue: { playlist in
                    receivePlaylistItems(playlist.items, onlyTracks: false)
                }
            )
            .store(in: &Self.cancellables)

        let playlistItemsExpectation = XCTestExpectation(
            description: "testPlaylistWithEpisodesAndLocalTracks: playlistItems"
        )

        Self.spotify.playlistItems(URIs.Playlists.test, market: "us")
            .XCTAssertNoFailure()
            .sink(
                receiveCompletion: { _ in playlistItemsExpectation.fulfill() },
                receiveValue: { playlistItems in
                    receivePlaylistItems(playlistItems, onlyTracks: false)
                }
            )
            .store(in: &Self.cancellables)

        let playlistTracksExpectation = XCTestExpectation(
            description: "testPlaylistWithEpisodesAndLocalTracks: playlistTracks"
        )

        Self.spotify.playlistTracks(URIs.Playlists.test, market: "us")
            .XCTAssertNoFailure()
            .sink(
                receiveCompletion: { _ in playlistTracksExpectation.fulfill() },
                receiveValue: { playlistTracks in
                    let items = playlistTracks.items.map { container in
                        PlaylistItemContainer(
                            addedAt: container.addedAt,
                            addedBy: container.addedBy,
                            isLocal: container.isLocal,
                            item: container.item.map { PlaylistItem.track($0) }
                        )
                    }
                    let playlistItems = PagingObject(
                        href: playlistTracks.href,
                        items: items,
                        limit: playlistTracks.limit,
                        offset: playlistTracks.offset,
                        total: playlistTracks.total
                    )
                    receivePlaylistItems(playlistItems, onlyTracks: true)
                }
            )
            .store(in: &Self.cancellables)


        self.wait(
            for: [
                playlistExpectation,
                playlistItemsExpectation,
                playlistTracksExpectation
            ],
            timeout: 120
        )
        spotifyDecodeLogger.logLevel = decodeLogLevel
        XCTAssertEqual(receivePlaylistItemsCallCount, 3)

    }

}

extension SpotifyAPIPlaylistsTests where
    AuthorizationManager: SpotifyScopeAuthorizationManager
{

    func createPlaylistAndAddTracksThenUnfollowIt() {

        let dateString = Date().description(with: .current)
        let itemsToAddToPlaylist = URIs.Tracks.array(
            .jinx, .fearless, .illWind, .nuclearFusion, .theBay
        ) + URIs.Episodes.array(
            .samHarris213, .samHarris214, .samHarris212
        )

        let details = PlaylistDetails(
            name: "createPlaylistAddTracks",
            isPublic: false,
            isCollaborative: false,
            description: dateString
        )
        encodeDecode(details)

        let expectation = XCTestExpectation(
            description: "createPlaylistAndAddTracks"
        )

        var createdPlaylistURI = ""
        var createdPlaylistSnaphotId = ""

        // get the uri of the current user
        let publisher: AnyPublisher<Playlist<PlaylistItems>, Error> =
            Self.spotify.currentUserProfile()
            .XCTAssertNoFailure()
            .flatMap { user -> AnyPublisher<Playlist<PlaylistItems>, Error> in
                // create a playlist for them
                encodeDecode(user)
                return Self.spotify.createPlaylist(for: user.uri, details)
            }
            .XCTAssertNoFailure()
            .flatMap { playlist -> AnyPublisher<String, Error> in

                encodeDecode(playlist)
                XCTAssertEqual(playlist.name, "createPlaylistAddTracks")
                XCTAssertEqual(playlist.description, dateString)
                XCTAssertFalse(playlist.isPublic ?? true)
                XCTAssertFalse(playlist.isCollaborative)
                XCTAssertEqual(playlist.items.items.count, 0)

                createdPlaylistURI = playlist.uri
                XCTAssert(createdPlaylistURI.count > 5)

                // add tracks and episodes to the playlist
                return Self.spotify.addToPlaylist(
                    playlist.uri, uris: itemsToAddToPlaylist
                )
            }
            .XCTAssertNoFailure()
            .flatMap { snapshotId -> AnyPublisher<Playlist<PlaylistItems>, Error> in
                // retrieve the playlist
                createdPlaylistSnaphotId = snapshotId
                XCTAssert(createdPlaylistURI.count > 5)
                XCTAssert(createdPlaylistSnaphotId.count > 5)
                return Self.spotify.playlist(createdPlaylistURI)
            }
            .XCTAssertNoFailure()
            .eraseToAnyPublisher()
        
        publisher
            .flatMap { playlist -> AnyPublisher<Void, Error> in

                encodeDecode(playlist)
                XCTAssertEqual(playlist.uri, createdPlaylistURI)
                XCTAssertEqual(playlist.snapshotId, createdPlaylistSnaphotId)
                XCTAssertEqual(playlist.name, "createPlaylistAddTracks")
                XCTAssertEqual(playlist.description, dateString)
                XCTAssertFalse(playlist.isPublic ?? true)
                XCTAssertFalse(playlist.isCollaborative)
                // assert that the playlist contains all of the items that
                // we just added, in the same order.
                XCTAssertEqual(
                    playlist.items.items.compactMap(\.item?.uri),
                    itemsToAddToPlaylist.map(\.uri)
                )

                // unfollow the playlist
                return Self.spotify.unfollowPlaylistForCurrentUser(
                    createdPlaylistURI
                )

            }
            .XCTAssertNoFailure()
            .flatMap {
                // get all of the current user's playlists
                Self.spotify.currentUserPlaylists()
            }
            .XCTAssertNoFailure()
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { playlists in
                    encodeDecode(playlists)
                    XCTAssertFalse(
                        // ensure the user is no longer following the playlist
                        // because we just unfollowed it
                        playlists.items.map(\.uri).contains(createdPlaylistURI)
                    )
                }
            )
            .store(in: &Self.cancellables)

        self.wait(for: [expectation], timeout: 120)

    }

    func createPlaylistAddRemoveReorderItems() {

        let itemsToAddToPlaylist: [SpotifyURIConvertible] = [
            URIs.Tracks.anyColourYouLike,  // 0
            URIs.Tracks.because,           // 1 | rangeStart
            URIs.Tracks.blueBoy,           // 2 |
            URIs.Tracks.breathe,           // 3 | rangeLength = 3
            URIs.Episodes.seanCarroll111,  // 4
            URIs.Episodes.joeRogan1531,    // 5
            URIs.Episodes.samHarris212     // 6  insertBefore
        ]

        let urisDict = URIsDictWithInsertionIndex(
            uris: itemsToAddToPlaylist,
            position: 5
        )

        encodeDecode(urisDict)

        XCTAssertEqual(
            urisDict.uris.map(\.uri),
            itemsToAddToPlaylist.map(\.uri)
        )
        XCTAssertEqual(urisDict.position, 5)

        var reorderRequest1 = ReorderPlaylistItems(
            rangeStart: 1,
            rangeLength: 3,
            insertBefore: 6
        )

        /// The expected order of the items after sending `reorderRequest1`.
        let reordered1: [SpotifyURIConvertible] = [
            URIs.Tracks.anyColourYouLike,  //      0
                                           //---->
            URIs.Episodes.seanCarroll111,  //    | 1
            URIs.Episodes.joeRogan1531,    //    | 2
            URIs.Tracks.because,           //  <-| 3
            URIs.Tracks.blueBoy,           //  <-| 4
            URIs.Tracks.breathe,           //  <-| 5
            URIs.Episodes.samHarris212     //      6
        ]

        let reorderRequest2 = ReorderPlaylistItems(
            rangeStart: 5,
            insertBefore: 2
        )

        let reordered2: [SpotifyURIConvertible] = [
            URIs.Tracks.anyColourYouLike,  // 0
            URIs.Episodes.seanCarroll111,  // 1
            URIs.Tracks.breathe,           // 2  —
            URIs.Episodes.joeRogan1531,    // 3  |
            URIs.Tracks.because,           // 4  |
            URIs.Tracks.blueBoy,           // 5  —
            URIs.Episodes.samHarris212     // 6
        ]

        let dateString = Date().description(with: .current)
        var createdPlaylistURI = ""

        let playlistDetails = PlaylistDetails(
            name: "createPlaylistAddRemoveReorderItems",
            isCollaborative: nil,
            description: dateString
        )

        encodeDecode(playlistDetails)

        let expectation = XCTestExpectation(
            description: "testCreatePlaylistAddRemoveReorderItems"
        )

        let publisher: AnyPublisher<String, Error> = Self.spotify
            .currentUserProfile()
            .XCTAssertNoFailure()
            .flatMap { user -> AnyPublisher<Playlist<PlaylistItems>, Error> in
                encodeDecode(user)
                // MARK: Create the playlist
                return Self.spotify.createPlaylist(
                    for: user.uri, playlistDetails
                )
            }
            .XCTAssertNoFailure()
            .flatMap { (playlist: Playlist<PlaylistItems>) -> AnyPublisher<String, Error> in

                encodeDecode(playlist)
                // MARK: Ensure it has the details we added
                XCTAssertEqual(playlist.name, "createPlaylistAddRemoveReorderItems")
                XCTAssertEqual(playlist.description, dateString)
                if let isPublic = playlist.isPublic {
                    XCTAssertTrue(isPublic)
                }
                else {
                    XCTFail("playlist.isPublic should not be nil")
                }
                XCTAssertFalse(playlist.isCollaborative)
                XCTAssertEqual(playlist.items.items.count, 0)

                createdPlaylistURI = playlist.uri
                XCTAssert(createdPlaylistURI.count > 5)

                // MARK: Add Tracks and episodes to the playlist
                return Self.spotify.addToPlaylist(
                    playlist.uri, uris: itemsToAddToPlaylist
                )

            }
            .XCTAssertNoFailure()
            .receiveOnMain(delay: 2)
            .eraseToAnyPublisher()
        
        let publisher2: AnyPublisher<PlaylistItems, Error> = publisher
            .flatMap { (snapshotId: String) -> AnyPublisher<PagingObject<Playlist<PlaylistsItemsReference>>, Error> in
                // get all of the current user's playlists
                // MARK: Get all of the user's playlists
                Self.spotify.currentUserPlaylists()
            }
            .XCTAssertNoFailure()
            .extendPages(Self.spotify)
            .XCTAssertNoFailure()
            .collect()
            .flatMap { (playlistsArray: [PagingObject<Playlist<PlaylistsItemsReference>>]) -> AnyPublisher<PlaylistItems, Error> in

                encodeDecode(playlistsArray)
                // MARK: Ensure the user is following the playlist we just created
                let playlists = playlistsArray.flatMap({ $0.items })
                let playlist = playlists.first(where: { playlist in
                    playlist.uri == createdPlaylistURI
                })
                XCTAssertNotNil(
                    playlist,
                    "should've found just-created playlist in currentUserPlaylists"
                )
                reorderRequest1.snapshotId = playlist?.snapshotId

                XCTAssert(createdPlaylistURI.count > 5)
                // MARK: Get all of the tracks and episodes in the playlist
                return Self.spotify.playlistItems(createdPlaylistURI)
            }
            .XCTAssertNoFailure()
            .eraseToAnyPublisher()

        // A single subscription stream takes too long to type-check.
        let publisher3: AnyPublisher<PlaylistItems, Error> = publisher2
            .flatMap { playlistItems -> AnyPublisher<String, Error> in

                encodeDecode(playlistItems)
                // assert that the playlist contains all of the items that
                // we just added, in the same order.
                // MARK: Ensure the playlist has the items we added
                XCTAssertEqual(
                    playlistItems.items.compactMap(\.item?.uri),
                    itemsToAddToPlaylist.map(\.uri)
                )

                // MARK: Reorder the items in the playlist 1
                return Self.spotify.reorderPlaylistItems(
                    createdPlaylistURI, body: reorderRequest1
                )
            }
            .XCTAssertNoFailure()
            .receiveOnMain(delay: 1)
            .flatMap { snapshotId -> AnyPublisher<PlaylistItems, Error> in
                // MARK: Get the items in the playlist again
                return Self.spotify.playlistItems(createdPlaylistURI)
            }
            .XCTAssertNoFailure()
            .flatMap { playlistItems -> AnyPublisher<String, Error> in

                encodeDecode(playlistItems)
                // MARK: Ensure the items in the playlist were reordered as requested 1
                XCTAssertEqual(
                    playlistItems.items.compactMap(\.item?.uri),
                    reordered1.map(\.uri)
                )
                // MARK: Reorder the items in the playlist 2
                return Self.spotify.reorderPlaylistItems(
                    createdPlaylistURI, body: reorderRequest2
                )
            }
            .XCTAssertNoFailure()
            .receiveOnMain(delay: 1)
            .flatMap { snapshotId -> AnyPublisher<PlaylistItems, Error> in
                // MARK: Get the items in the playlist again
                return Self.spotify.playlistItems(createdPlaylistURI)
            }
            .XCTAssertNoFailure()
            .eraseToAnyPublisher()

        publisher3
            .flatMap { playlistItems -> AnyPublisher<Void, Error> in
                encodeDecode(playlistItems)
                // MARK: Ensure the items in the playlist were reordered as requested 2
                XCTAssertEqual(
                    playlistItems.items.compactMap(\.item?.uri),
                    reordered2.map(\.uri)
                )
                // MARK: Unfollow the playlist
                return Self.spotify.unfollowPlaylistForCurrentUser(
                    createdPlaylistURI
                )

            }
            .XCTAssertNoFailure()
            .receiveOnMain(delay: 1)
            .flatMap {
                // get all of the current user's playlists
                // MARK: Get all of the user's playlists
                Self.spotify.currentUserPlaylists()
            }
            .XCTAssertNoFailure()
            .extendPages(Self.spotify)
            .XCTAssertNoFailure()
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { playlists in
                    encodeDecode(playlists)
                    XCTAssertFalse(
                        // ensure the user is no longer following the playlist
                        // because we just unfollowed it
                        // MARK: Ensure the playlist is no longer being followed
                        playlists.items.map(\.uri).contains(createdPlaylistURI)
                    )
                }
            )
            .store(in: &Self.cancellables)


        self.wait(for: [expectation], timeout: 300)

    }

    func removeAllOccurencesFromPlaylist() {

        let itemsToAddToPlaylist: [SpotifyURIConvertible] = [
            URIs.Episodes.samHarris215,
            URIs.Tracks.honey,
            URIs.Tracks.friends,
            URIs.Tracks.friends,
            URIs.Tracks.because,
            URIs.Tracks.friends,
            URIs.Tracks.friends,
            URIs.Episodes.joeRogan1531,
            URIs.Episodes.joeRogan1531,
            URIs.Episodes.samHarris214,
            URIs.Episodes.joeRogan1531,
            URIs.Episodes.joeRogan1531
        ]

        let itemsToRemoveFromPlaylist: [SpotifyURIConvertible] = [
            URIs.Tracks.friends,
            URIs.Episodes.joeRogan1531,
            URIs.Tracks.because
        ]

        let itemsToRemoveContainer1 = URIsContainer(
            itemsToRemoveFromPlaylist, snapshotId: nil
        )
        encodeDecode(itemsToRemoveContainer1)

        let itemsToRemoveContainer2 = URIsContainer(
            itemsToRemoveFromPlaylist, snapshotId: "asdfsdfasdfasdfasdfasdf"
        )
        encodeDecode(itemsToRemoveContainer2)

        let itemsLeftInPlaylist: [SpotifyURIConvertible] = [
            URIs.Episodes.samHarris215,
            URIs.Tracks.honey,
            URIs.Episodes.samHarris214
        ]


        let playlistDetails = PlaylistDetails(
            name: "removeAllOccurencesFromPlaylist",
            isPublic: false,
            isCollaborative: true
        )

        encodeDecode(playlistDetails)

        let expectation = XCTestExpectation(
            description: "testRemoveAllOccurencesFromPlaylist"
        )

        var createdPlaylistURI = ""
        var playlistSnapshotId: String? = nil

        let publisher: AnyPublisher<PlaylistItems, Error> = Self.spotify
            .currentUserProfile()
            .XCTAssertNoFailure()
            .flatMap { user -> AnyPublisher<Playlist<PlaylistItems>, Error> in
                encodeDecode(user)
                return Self.spotify.createPlaylist(
                    for: user.uri, playlistDetails
                )
            }
            .XCTAssertNoFailure()
            .flatMap { playlist -> AnyPublisher<String, Error> in

                encodeDecode(playlist)
                XCTAssertEqual(playlist.name, "removeAllOccurencesFromPlaylist")
                XCTAssertFalse(playlist.isPublic ?? true)
                XCTAssertTrue(playlist.isCollaborative)
                XCTAssertEqual(playlist.items.items.count, 0)

                createdPlaylistURI = playlist.uri
                XCTAssert(createdPlaylistURI.count > 5)

                // add tracks and episodes to the playlist
                return Self.spotify.addToPlaylist(
                    playlist.uri, uris: itemsToAddToPlaylist
                )
            }
            .XCTAssertNoFailure()
            .flatMap { snapshotId -> AnyPublisher<PlaylistItems, Error> in
                playlistSnapshotId = snapshotId
                // retrieve the playlist
                XCTAssert(createdPlaylistURI.count > 5)
                return Self.spotify.playlistItems(createdPlaylistURI)
            }
            .XCTAssertNoFailure()
            .eraseToAnyPublisher()

        publisher
            .flatMap { playlistItems -> AnyPublisher<String, Error> in

                encodeDecode(playlistItems)
                XCTAssertEqual(
                    playlistItems.items.compactMap(\.item?.uri),
                    itemsToAddToPlaylist.map(\.uri)
                )

                XCTAssertNotNil(playlistSnapshotId)

                return Self.spotify.removeAllOccurencesFromPlaylist(
                    createdPlaylistURI, of: itemsToRemoveFromPlaylist,
                    snapshotId: playlistSnapshotId
                )
            }
            .XCTAssertNoFailure()
            .receiveOnMain(delay: 1)
            .flatMap { snapshotId -> AnyPublisher<PlaylistItems, Error> in
                return Self.spotify.playlistItems(createdPlaylistURI)
            }
            .XCTAssertNoFailure()
            .flatMap { playlistItems -> AnyPublisher<Void, Error> in

                encodeDecode(playlistItems)
                XCTAssertEqual(
                    playlistItems.items.compactMap(\.item?.uri),
                    itemsLeftInPlaylist.map(\.uri)
                )

                return Self.spotify.unfollowPlaylistForCurrentUser(
                    createdPlaylistURI
                )
            }
            .XCTAssertNoFailure()
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { }
            )
            .store(in: &Self.cancellables)

        self.wait(for: [expectation], timeout: 180)

    }

    func removeSpecificOccurencesFromPlaylist() {

        let itemsToAddToPlaylist: [SpotifyURIConvertible] = [
            URIs.Episodes.seanCarroll111,  // 0
            URIs.Episodes.seanCarroll112,  // 1
            URIs.Tracks.breathe,           // 2
            URIs.Tracks.houseOfCards,      // 3
            URIs.Tracks.illWind,           // 4
            URIs.Episodes.seanCarroll112,  // 5
            URIs.Tracks.houseOfCards,      // 6
            URIs.Tracks.breathe,           // 7
            URIs.Tracks.breathe            // 8
        ]

        var itemsToRemoveFromPlaylist = URIsWithPositionsContainer(
            snapshotId: nil,
            urisWithPositions: [
                .init(uri: URIs.Episodes.seanCarroll112, positions: [1, 5]),
                .init(uri: URIs.Tracks.breathe, positions: [2, 7]),
                .init(uri: URIs.Tracks.houseOfCards, positions: [3])
            ]
        )

        encodeDecode(itemsToRemoveFromPlaylist)

        do {
            var copy = itemsToRemoveFromPlaylist
            copy.snapshotId = "asdifhaslkjhfalksjfhaksdjfhaksjdhfasdkljf"
            encodeDecode(copy)
        }

        let itemsLeftInPlaylist: [SpotifyURIConvertible] = [
            URIs.Episodes.seanCarroll111,  // 0
            URIs.Tracks.illWind,           // 4
            URIs.Tracks.houseOfCards,      // 6
            URIs.Tracks.breathe            // 8
        ]

        let playlistDetails = PlaylistDetails(
            name: "removeSpecificOccurencesFromPlaylist",
            isCollaborative: nil
        )
        encodeDecode(playlistDetails)

        let newPlaylistDetails = PlaylistDetails(
            name: "renamed removeSpecificOccurencesFromPlaylist",
            isPublic: false,
            isCollaborative: false,
            description: "programmatically"
        )
        encodeDecode(newPlaylistDetails)

        let expectation = XCTestExpectation(
            description: "testRemoveSpecificOccurencesFromPlaylist"
        )

        var createdPlaylistURI = ""
        var playlistSnapshotId: String? = nil

        let publisher: AnyPublisher<Playlist<PlaylistItems>, Error> =
            Self.spotify.currentUserProfile()
            .XCTAssertNoFailure()
            .flatMap { user -> AnyPublisher<Playlist<PlaylistItems>, Error> in
                encodeDecode(user)
                return Self.spotify.createPlaylist(
                    for: user.uri, playlistDetails
                )
            }
            .XCTAssertNoFailure()
            .flatMap { playlist -> AnyPublisher<Void, Error> in

                encodeDecode(playlist)
                XCTAssertEqual(playlist.name, "removeSpecificOccurencesFromPlaylist")
                if let isPublic = playlist.isPublic {
                    XCTAssertTrue(isPublic)
                }
                else {
                    XCTFail("playlist.isPublic should not be nil")
                }
                XCTAssertFalse(playlist.isCollaborative)
                XCTAssertEqual(playlist.items.items.count, 0)

                createdPlaylistURI = playlist.uri
                XCTAssert(createdPlaylistURI.count > 5)

                return Self.spotify.changePlaylistDetails(
                    createdPlaylistURI, to: newPlaylistDetails
                )

            }
            .XCTAssertNoFailure()
            .flatMap { () -> AnyPublisher<String, Error> in
                // add tracks and episodes to the playlist
                return Self.spotify.addToPlaylist(
                    createdPlaylistURI, uris: itemsToAddToPlaylist
                )
            }
            .XCTAssertNoFailure()
            .flatMap { snapshotId -> AnyPublisher<Playlist<PlaylistItems>, Error> in
                playlistSnapshotId = snapshotId
                // retrieve the playlist
                XCTAssert(createdPlaylistURI.count > 5)
                return Self.spotify.playlist(
                    createdPlaylistURI, market: "US"
                )
            }
            .XCTAssertNoFailure()
            .eraseToAnyPublisher()

        publisher
            .flatMap { playlist -> AnyPublisher<String, Error> in

                encodeDecode(playlist)

                XCTAssertEqual(playlist.name, "renamed removeSpecificOccurencesFromPlaylist")
                if let isPublic = playlist.isPublic {
                    XCTAssertFalse(isPublic)
                }
                else {
                    XCTFail("playlist.isPublic should not be nil")
                }
                XCTAssertFalse(playlist.isCollaborative)
                XCTAssertEqual(playlist.description, "programmatically")

                let playlistItems = playlist.items.items.compactMap(\.item?.uri)
                XCTAssertEqual(
                    playlistItems, itemsToAddToPlaylist.map(\.uri)
                )

                XCTAssertNotNil(playlistSnapshotId)
                itemsToRemoveFromPlaylist.snapshotId = playlistSnapshotId

                return Self.spotify.removeSpecificOccurencesFromPlaylist(
                    createdPlaylistURI, of: itemsToRemoveFromPlaylist
                )
            }
            .XCTAssertNoFailure()
            .receiveOnMain(delay: 1)
            .flatMap { snapshotId -> AnyPublisher<PlaylistItems, Error> in
                return Self.spotify.playlistItems(
                    createdPlaylistURI,
                    limit: 100,
                    offset: 0,
                    market: "US"
                )
            }
            .XCTAssertNoFailure()
            .flatMap { playlistItems -> AnyPublisher<Void, Error> in

                encodeDecode(playlistItems)
                XCTAssertEqual(
                    playlistItems.items.compactMap(\.item?.uri),
                    itemsLeftInPlaylist.map(\.uri)
                )

                return Self.spotify.unfollowPlaylistForCurrentUser(
                    createdPlaylistURI
                )
            }
            .XCTAssertNoFailure()
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { }
            )
            .store(in: &Self.cancellables)

        self.wait(for: [expectation], timeout: 180)

    }

    func replaceItemsInPlaylist() {

        let itemsToAddToPlaylist: [SpotifyURIConvertible] = [
            URIs.Tracks.plants,
            URIs.Tracks.jinx,
            URIs.Tracks.wadingOut,
            URIs.Tracks.plants,
            URIs.Tracks.nuclearFusion,
            URIs.Tracks.odeToViceroy,
            URIs.Episodes.samHarris213,
            URIs.Episodes.samHarris213
        ]

        let replacementItems: [SpotifyURIConvertible] = [
            URIs.Tracks.plants,
            URIs.Tracks.jinx,
            URIs.Episodes.samHarris213
        ]

        let dateString = Date().description(with: .current)

        var createdPlaylistURI = ""

        let playlistDetails = PlaylistDetails(
            name: "replaceItemsInPlaylist",
            isPublic: false,
            isCollaborative: true,
            description: dateString
        )
        encodeDecode(playlistDetails)

        let expectation = XCTestExpectation(
            description: "testReplaceItemsInPlaylist"
        )

        let publisher: AnyPublisher<PlaylistItems, Error> = Self.spotify
            .currentUserProfile()
            .XCTAssertNoFailure()
            .flatMap { user -> AnyPublisher<Playlist<PlaylistItems>, Error> in
                encodeDecode(user)
                return Self.spotify.createPlaylist(
                    for: user.uri, playlistDetails
                )
            }
            .XCTAssertNoFailure()
            .flatMap { playlist -> AnyPublisher<String, Error> in

                encodeDecode(playlist)
                XCTAssertEqual(playlist.name, "replaceItemsInPlaylist")
                XCTAssertEqual(playlist.items.items.count, 0)
                XCTAssertTrue(playlist.isCollaborative)
                if let isPublic = playlist.isPublic {
                    XCTAssertFalse(isPublic)
                }
                else {
                    XCTFail("playlist.isPublic should not be nil")
                }
                XCTAssertEqual(playlist.description, dateString)
                createdPlaylistURI = playlist.uri
                XCTAssert(createdPlaylistURI.count > 5)

                return Self.spotify.addToPlaylist(
                    createdPlaylistURI,
                    uris: itemsToAddToPlaylist,
                    position: 0
                )

            }
            .XCTAssertNoFailure()
            .flatMap { snapshotId -> AnyPublisher<PlaylistItems, Error> in
                // retrieve the playlist
                return Self.spotify.playlistItems(
                    createdPlaylistURI,
                    limit: 32,
                    offset: 0
                )
            }
            .XCTAssertNoFailure()
            .flatMap { playlistItems -> AnyPublisher<String, Error> in

                let tracks = playlistItems.items.compactMap(\.item?.uri)
                XCTAssertEqual(tracks, itemsToAddToPlaylist.map(\.uri))

                return Self.spotify.replaceAllPlaylistItems(
                    createdPlaylistURI, with: replacementItems
                )

            }
            .XCTAssertNoFailure()
            .flatMap { snapshotId -> AnyPublisher<PlaylistItems, Error> in
                // retrieve the playlist
                return Self.spotify.playlistItems(
                    createdPlaylistURI,
                    limit: 69,
                    offset: 0,
                    market: "US"
                )
            }
            .XCTAssertNoFailure()
            .eraseToAnyPublisher()
            
        publisher
            .flatMap { playlistItems -> AnyPublisher<String, Error> in

                let tracks = playlistItems.items.compactMap(\.item?.uri)
                XCTAssertEqual(tracks, replacementItems.map(\.uri))

                return Self.spotify.replaceAllPlaylistItems(
                    createdPlaylistURI, with: []
                )
            }
            .XCTAssertNoFailure()
            .flatMap { snapshotId -> AnyPublisher<PlaylistItems, Error> in
                // retrieve the playlist
                return Self.spotify.playlistItems(
                    createdPlaylistURI,
                    limit: 69,
                    offset: 0,
                    market: "US"
                )
            }
            .XCTAssertNoFailure()
            .flatMap { playlistItems -> AnyPublisher<Void, Error> in

                XCTAssertEqual(playlistItems.items.count, 0)
                XCTAssertEqual(playlistItems.total, 0)
                return Self.spotify.unfollowPlaylistForCurrentUser(
                    createdPlaylistURI
                )

            }
            .XCTAssertNoFailure()
            .receiveOnMain(delay: 1)
            .flatMap {
                // get all of the current user's playlists
                // MARK: Get all of the user's playlists
                Self.spotify.currentUserPlaylists()
            }
            .XCTAssertNoFailure()
            .extendPages(Self.spotify)
            .XCTAssertNoFailure()
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { playlists in
                    encodeDecode(playlists)
                    XCTAssertFalse(
                        // ensure the user is no longer following the playlist
                        // because we just unfollowed it
                        // MARK: Ensure the playlist is no longer being followed
                        playlists.items.map(\.uri).contains(createdPlaylistURI)
                    )
                }
            )
            .store(in: &Self.cancellables)

        self.wait(for: [expectation], timeout: 300)

    }

    func playlistImage() {

        var cancellables: [AnyCancellable] = []

        var expectations: [XCTestExpectation] = []

        func receiveImages(_ images: [SpotifyImage]) {


            print("line \(#line): recevied \(images.count) images")
            XCTAssertFalse(images.isEmpty)
            
            #if (canImport(AppKit) || canImport(UIKit)) && canImport(SwiftUI)

            var imageExpectations: [XCTestExpectation] = []
            for (i, image) in images.enumerated() {

                let loadImageExpectation = XCTestExpectation(
                    description: "load image \(i)"
                )
                imageExpectations.append(loadImageExpectation)

                image.load()
                    .XCTAssertNoFailure()
                    .sink(
                        receiveCompletion: { _ in
                            print("loadImageExpectation.fulfill() \(i)")
                            loadImageExpectation.fulfill()
                        },
                        receiveValue: { image in
                            print("received image \(i): \(image)")
                        }
                    )
                    .store(in: &Self.cancellables)

                guard let url = URL(string: image.url) else {
                    XCTFail("couldn't convert to URL: '\(image.url)'")
                    continue
                }

                let assertImageExistsExpectation = XCTestExpectation(
                    description: "assert image exists \(i)"
                )
                imageExpectations.append(assertImageExistsExpectation)

                assertURLExists(url)
                    .sink(
                        receiveCompletion: { _ in
                            print("urlExists.fulfill() '\(image.url)'")
                            assertImageExistsExpectation.fulfill()
                        },
                        receiveValue: { _ in
                            print("urlExists receiveValue '\(image.url)'")
                        }
                    )
                    .store(in: &Self.cancellables)

            }

            self.wait(for: imageExpectations, timeout: TimeInterval(60 * images.count))
            
            #endif
        }

        let playlists: [URIs.Playlists] = [
            .thisIsTheBeatles, .all, .bluesClassics
        ]
        for (i, playlist) in playlists.enumerated() {

            let playlistImageExpectation = XCTestExpectation(
                description: "testPlaylistImage \(i)"
            )
            expectations.append(playlistImageExpectation)

            Self.spotify.playlistImage(playlist)
                .receiveOnMain()
                .XCTAssertNoFailure()
                .sink(
                    receiveCompletion: { _ in
                        playlistImageExpectation.fulfill()
                    },
                    receiveValue: receiveImages(_:)
                )
                .store(in: &cancellables)

        }

        self.wait(for: expectations, timeout: 240)


    }

    func uploadPlaylistImage() {

//        let imageData = SpotifyExampleImages.annabelle
//        let encodedData = imageData.base64EncodedData()
//
//        print("encoded data count: ", encodedData.count)
//
//
//        let expectation = XCTestExpectation(
//            description: "uploadPlaylistImage"
//        )
//
//        Self.spotify.uploadPlaylistImage(
//            URIs.Playlists.test,
//            imageData: encodedData
//        )
//        .XCTAssertNoFailure()
//        .sink(receiveCompletion: { _ in
//            expectation.fulfill()
//        })
//        .store(in: &Self.cancellables)
//
//        self.wait(for: [expectation], timeout: 120)

    }

}

final class SpotifyAPIClientCredentialsFlowPlaylistsTests:
    SpotifyAPIClientCredentialsFlowTests, SpotifyAPIPlaylistsTests
{

    static let allTests = [
        ("testGetCrumbPlaylist", testGetCrumbPlaylist),
        ("testGetCrumPlaylistTracks", testGetCrumbPlaylistTracks),
        ("testFilteredPlaylist", testFilteredPlaylist),
        ("testFilteredPlaylistItems", testFilteredPlaylistItems),
        ("testOtherUserCurrentPlaylists", testOtherUserCurrentPlaylists),
        (
            "testPlaylistWithEpisodesAndLocalTracks",
            testPlaylistWithEpisodesAndLocalTracks
        )
    ]

    func testGetCrumbPlaylist() { getCrumbPlaylist() }
    func testGetCrumbPlaylistTracks() { getCrumbPlaylistTracks() }
    func testFilteredPlaylist() { filteredPlaylist() }
    func testFilteredPlaylistItems() { filteredPlaylistItems() }

    func testOtherUserCurrentPlaylists() { otherUserCurrentPlaylists() }
    func testPlaylistWithEpisodesAndLocalTracks() {
        playlistWithEpisodesAndLocalTracks()
    }

}


final class SpotifyAPIAuthorizationCodeFlowPlaylistsTests:
    SpotifyAPIAuthorizationCodeFlowTests, SpotifyAPIPlaylistsTests
{

    static let allTests = [
        ("testGetCrumbPlaylist", testGetCrumbPlaylist),
        ("testGetCrumPlaylistTracks", testGetCrumbPlaylistTracks),
        ("testFilteredPlaylist", testFilteredPlaylist),
        ("testFilteredPlaylistItems", testFilteredPlaylistItems),
        ("testOtherUserCurrentPlaylists", testOtherUserCurrentPlaylists),
        (
            "testPlaylistWithEpisodesAndLocalTracks",
            testPlaylistWithEpisodesAndLocalTracks
        ),
        (
            "testCreatePlaylistAndAddTracksThenUnfollowIt",
            testCreatePlaylistAndAddTracksThenUnfollowIt
        ),
        (
            "testCreatePlaylistAddRemoveReorderItems",
            testCreatePlaylistAddRemoveReorderItems
        ),
        (
            "testRemoveAllOccurencesFromPlaylist",
            testRemoveAllOccurencesFromPlaylist
        ),
        (
            "testRemoveSpecificOccurencesFromPlaylist",
            testRemoveSpecificOccurencesFromPlaylist
        ),
        ("testReplaceItemsInPlaylist", testReplaceItemsInPlaylist),
        ("testPlaylistImage", testPlaylistImage),
        ("testUploadPlaylistImage", testUploadPlaylistImage)
    ]

    func testGetCrumbPlaylist() { getCrumbPlaylist() }
    func testGetCrumbPlaylistTracks() { getCrumbPlaylistTracks() }
    func testFilteredPlaylist() { filteredPlaylist() }
    func testFilteredPlaylistItems() { filteredPlaylistItems() }
    func testOtherUserCurrentPlaylists() { otherUserCurrentPlaylists() }
    func testPlaylistWithEpisodesAndLocalTracks() {
        playlistWithEpisodesAndLocalTracks()
    }

    func testCreatePlaylistAndAddTracksThenUnfollowIt() {
        createPlaylistAndAddTracksThenUnfollowIt()
    }
    func testCreatePlaylistAddRemoveReorderItems() {
        createPlaylistAddRemoveReorderItems()
    }
    func testRemoveAllOccurencesFromPlaylist() {
        removeAllOccurencesFromPlaylist()
    }
    func testRemoveSpecificOccurencesFromPlaylist() {
        removeSpecificOccurencesFromPlaylist()
    }
    func testReplaceItemsInPlaylist() { replaceItemsInPlaylist() }
    func testPlaylistImage() { playlistImage() }
    func testUploadPlaylistImage() { uploadPlaylistImage() }

}

final class SpotifyAPIAuthorizationCodeFlowPKCEPlaylistsTests:
    SpotifyAPIAuthorizationCodeFlowPKCETests, SpotifyAPIPlaylistsTests
{

    static let allTests = [
        ("testGetCrumbPlaylist", testGetCrumbPlaylist),
        ("testGetCrumPlaylistTracks", testGetCrumbPlaylistTracks),
        ("testFilteredPlaylist", testFilteredPlaylist),
        ("testFilteredPlaylistItems", testFilteredPlaylistItems),
        ("testOtherUserCurrentPlaylists", testOtherUserCurrentPlaylists),
        (
            "testPlaylistWithEpisodesAndLocalTracks",
            testPlaylistWithEpisodesAndLocalTracks
        ),
        (
            "testCreatePlaylistAndAddTracksThenUnfollowIt",
            testCreatePlaylistAndAddTracksThenUnfollowIt
        ),
        (
            "testCreatePlaylistAddRemoveReorderItems",
            testCreatePlaylistAddRemoveReorderItems
        ),
        (
            "testRemoveAllOccurencesFromPlaylist",
            testRemoveAllOccurencesFromPlaylist
        ),
        (
            "testRemoveSpecificOccurencesFromPlaylist",
            testRemoveSpecificOccurencesFromPlaylist
        ),
        ("testReplaceItemsInPlaylist", testReplaceItemsInPlaylist),
        ("testPlaylistImage", testPlaylistImage),
        ("testUploadPlaylistImage", testUploadPlaylistImage)
    ]

    func testGetCrumbPlaylist() { getCrumbPlaylist() }
    func testGetCrumbPlaylistTracks() { getCrumbPlaylistTracks() }
    func testFilteredPlaylist() { filteredPlaylist() }
    func testFilteredPlaylistItems() { filteredPlaylistItems() }
    func testOtherUserCurrentPlaylists() { otherUserCurrentPlaylists() }
    func testPlaylistWithEpisodesAndLocalTracks() {
        playlistWithEpisodesAndLocalTracks()
    }

    func testCreatePlaylistAndAddTracksThenUnfollowIt() {
        createPlaylistAndAddTracksThenUnfollowIt()
    }
    func testCreatePlaylistAddRemoveReorderItems() {
        createPlaylistAddRemoveReorderItems()
    }
    func testRemoveAllOccurencesFromPlaylist() {
        removeAllOccurencesFromPlaylist()
    }
    func testRemoveSpecificOccurencesFromPlaylist() {
        removeSpecificOccurencesFromPlaylist()
    }
    func testReplaceItemsInPlaylist() { replaceItemsInPlaylist() }
    func testPlaylistImage() { playlistImage() }
    func testUploadPlaylistImage() { uploadPlaylistImage() }

}
