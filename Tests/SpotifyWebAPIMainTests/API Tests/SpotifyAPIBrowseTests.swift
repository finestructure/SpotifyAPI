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

protocol SpotifyAPIBrowseTests: SpotifyAPITests { }

extension SpotifyAPIBrowseTests {
    
    func category() {

        let expectation = XCTestExpectation(description: "testCategory")
        
        Self.spotify.category(
            "party",
            country: "US",
            locale: "es_MX"  // Spanish Mexico
        )
        .XCTAssertNoFailure()
        .receiveOnMain()
        .sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { category in
                encodeDecode(category)
                XCTAssertEqual(category.name, "Fiesta")
                XCTAssertEqual(category.id, "party")
                XCTAssertEqual(
                    category.href,
                    "https://api.spotify.com/v1/browse/categories/party"
                )
                
                #if (canImport(AppKit) || canImport(UIKit)) && canImport(SwiftUI)
                let (imageExpectations, cancellables) =
                            XCTAssertImagesExist(category.icons)
                
                Self.cancellables.formUnion(cancellables)
                
                self.wait(
                    for: imageExpectations,
                    timeout: TimeInterval(imageExpectations.count * 60)
                )
                #endif
                
            }
        )
        .store(in: &Self.cancellables)
        
        self.wait(for: [expectation], timeout: 120)
        

    }

    func categories() {
        
        func receiveCategories(_ categories: PagingObject<SpotifyCategory>) {
            encodeDecode(categories)
            XCTAssertEqual(categories.limit, 10)
            XCTAssertEqual(categories.offset, 5)
            XCTAssertLessThanOrEqual(categories.items.count, 10)
            XCTAssertNotNil(categories.previous)
            if categories.total > categories.items.count + categories.offset {
                XCTAssertNotNil(categories.next)
            }
            print("categories:")
            dump(categories)
        }
        
        let expectation = XCTestExpectation(description: "testCategories")

        Self.spotify.categories(
            country: "US",
            locale: "es_MX",
            limit: 10,
            offset: 5
        )
        .XCTAssertNoFailure()
        .sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: receiveCategories(_:)
        )
        .store(in: &Self.cancellables)
        
        self.wait(for: [expectation], timeout: 120)

    }
    
    func categoryPlaylists() {
        
        func receiveCategoryPlaylists(
            _ playlists: PagingObject<Playlist<PlaylistsItemsReference>>
        ) {
            encodeDecode(playlists)
            XCTAssertEqual(playlists.limit, 15)
            XCTAssertEqual(playlists.offset, 2)
            XCTAssertLessThanOrEqual(playlists.items.count, 15)
            XCTAssertNotNil(playlists.previous)
            if playlists.total > playlists.items.count + playlists.offset {
                XCTAssertNotNil(playlists.next)
            }
            print("category playlists:")
            dump(playlists)
        }
        
        let expectation = XCTestExpectation(
            description: "testCategoryPlaylists"
        )
        
        Self.spotify.categoryPlaylists(
            "rock", country: "US", limit: 15, offset: 2
        )
        .XCTAssertNoFailure()
        .sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: receiveCategoryPlaylists(_:)
        )
        .store(in: &Self.cancellables)
        
        self.wait(for: [expectation], timeout: 120)
        
    }

    func featuredPlaylists() {
        
        func receivePlaylists(_ featuredPlaylists: FeaturedPlaylists) {
            encodeDecode(featuredPlaylists)
            let playlists = featuredPlaylists.playlists
            XCTAssertEqual(playlists.limit, 10)
            XCTAssertEqual(playlists.offset, 5)
            XCTAssertLessThanOrEqual(playlists.items.count, 10)
            XCTAssertNotNil(playlists.previous)
            if playlists.total > playlists.items.count + playlists.offset {
                XCTAssertNotNil(playlists.next)
            }
        }
        
        let expectation = XCTestExpectation(
            description: "testFeaturedPlaylists"
        )
        
        // 24 hours ago
        let yesterday = Date().addingTimeInterval(-86_400)
        
        Self.spotify.featuredPlaylists(
            locale: "en_US",
            country: "US",
            timestamp: yesterday,
            limit: 10,
            offset: 5
        )
        .XCTAssertNoFailure()
        .sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: receivePlaylists(_:)
        )
        .store(in: &Self.cancellables)
        
        self.wait(for: [expectation], timeout: 120)

    }
    
    func newAlbumReleases() {
        
        func recieveNewAlbumReleases(_ albumReleases: NewAlbumReleases) {
            encodeDecode(albumReleases)
            let albums = albumReleases.albums
            XCTAssertEqual(albums.limit, 5)
            XCTAssertEqual(albums.offset, 4)
            XCTAssertNotNil(albums.previous)
            if albums.total > albums.items.count + albums.offset {
                XCTAssertNotNil(albums.next)
            }
        }
        
        let expectation = XCTestExpectation(
            description: "testNewAlbumReleases"
        )

        Self.spotify.newAlbumReleases(country: "GB", limit: 5, offset: 4)
            .XCTAssertNoFailure()
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: recieveNewAlbumReleases(_:)
            )
            .store(in: &Self.cancellables)
        
        self.wait(for: [expectation], timeout: 120)
        
    }
    
    func recommendations() {
        
        func createTrackAttributesFromGenres(
            _ genres: [String]
        ) -> TrackAttributes {
        
            receivedGenres = Array((genres).prefix(2))
            
            let trackAttributes = TrackAttributes(
                seedArtists: URIs.Artists.array(.theBeatles, .crumb),
                seedTracks: URIs.Tracks.array(.fearless),
                seedGenres: receivedGenres!,
                energy: .init(min: 0.5, target: 0.67, max: 0.78),
                instrumentalness: .init(min: 0.3, target: 0.5, max: 1),
                popularity: .init(min: 60),
                valence: .init(target: 0.8)
            )
        
            encodeDecode(trackAttributes)
        
            return trackAttributes
        }
        
        func receiveRecommentations(_ recommentations: RecommendationsResponse) {
            
            encodeDecode(recommentations)

            
            // MARK: Seed Artists
            
            let seedArtists = recommentations.seedArtists
            for artist in seedArtists {
                XCTAssertEqual(artist.type, .artist)
            }
            
            if let theBeatles = seedArtists.first(where: { seedArtist in
                seedArtist.id == "3WrFJ7ztbogyGnTHbHJFl2"
            }) {
                XCTAssertEqual(
                    theBeatles.href,
                    "https://api.spotify.com/v1/artists/3WrFJ7ztbogyGnTHbHJFl2"
                )
            }
            else {
                XCTFail("should've found The Beatles in seed artists")
            }
            
            if let crumb = seedArtists.first(where: { seedArtist in
                seedArtist.id == "4kSGbjWGxTchKpIxXPJv0B"
            }) {
                XCTAssertEqual(
                    crumb.href,
                    "https://api.spotify.com/v1/artists/4kSGbjWGxTchKpIxXPJv0B"
                )
            }
            else {
                XCTFail("should've found Crumb in seed artists")
            }
            
            // MARK: Seed Tracks
            
            let seedTracks = recommentations.seedTracks
            for track in seedTracks {
                XCTAssertEqual(track.type, .track)
            }
            
            if let fearless = seedTracks.first(where: { seedTrack in
                seedTrack.id == "7AalBKBoLDR4UmRYRJpdbj"
            }) {
                XCTAssertEqual(
                    fearless.href,
                    "https://api.spotify.com/v1/tracks/7AalBKBoLDR4UmRYRJpdbj"
                )
            }
            else {
                XCTFail("should've found Fearless in seed tracks")
            }
            
            // MARK: Seed Genres
            guard let receivedGenres = receivedGenres else {
                XCTFail("receivedGenres should not be nil")
                return
            }
            
            let seedGenres = recommentations.seedGenres
            for genre in seedGenres {
                XCTAssertEqual(genre.type, .genre)
                XCTAssertNil(genre.href)
            }
            
            let seedGenresIds = seedGenres.map(\.id)
            for genre in receivedGenres {
                XCTAssert(
                    seedGenresIds.contains(genre),
                    "\(seedGenres) != \(receivedGenres)"
                )
            }
            
        }
        
        let expectation = XCTestExpectation(description: "testRecommendations")
        
        var receivedGenres: [String]? = nil
        
        Self.spotify.recommendationGenres()
            .XCTAssertNoFailure()
            .map(createTrackAttributesFromGenres(_:))
            .flatMap { trackAttributes in
                Self.spotify.recommendations(
                    trackAttributes,
                    limit: 6,
                    market: "US"
                )
            }
            .XCTAssertNoFailure()
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: receiveRecommentations(_:)
            )
            .store(in: &Self.cancellables)
        
        self.wait(for: [expectation], timeout: 120)
            
        
    }

}

final class SpotifyAPIClientCredentialsFlowBrowseTests:
    SpotifyAPIClientCredentialsFlowTests, SpotifyAPIBrowseTests
{

    static let allTests = [
        ("testCategory", testCategory),
        ("testCategories", testCategories),
        ("testCategoryPlaylists", testCategoryPlaylists),
        ("testFeaturedPlaylists", testFeaturedPlaylists),
        ("testNewAlbumReleases", testNewAlbumReleases),
        ("testRecommendations", testRecommendations)
    ]
    
    func testCategory() { category() }
    func testCategories() { categories() }
    func testCategoryPlaylists() { categoryPlaylists() }
    func testFeaturedPlaylists() { featuredPlaylists() }
    func testNewAlbumReleases() { newAlbumReleases() }
    func testRecommendations() { recommendations() }
    
}

final class SpotifyAPIAuthorizationCodeFlowBrowseTests:
    SpotifyAPIAuthorizationCodeFlowTests, SpotifyAPIBrowseTests
{
    
    static let allTests = [
        ("testCategory", testCategory),
        ("testCategories", testCategories),
        ("testCategoryPlaylists", testCategoryPlaylists),
        ("testFeaturedPlaylists", testFeaturedPlaylists),
        ("testNewAlbumReleases", testNewAlbumReleases),
        ("testRecommendations", testRecommendations)
    ]
    
    func testCategory() { category() }
    func testCategories() { categories() }
    func testCategoryPlaylists() { categoryPlaylists() }
    func testFeaturedPlaylists() { featuredPlaylists() }
    func testNewAlbumReleases() { newAlbumReleases() }
    func testRecommendations() { recommendations() }

}


final class SpotifyAPIAuthorizationCodeFlowPKCEBrowseTests:
    SpotifyAPIAuthorizationCodeFlowPKCETests, SpotifyAPIBrowseTests
{
    
    static let allTests = [
        ("testCategory", testCategory),
        ("testCategories", testCategories),
        ("testCategoryPlaylists", testCategoryPlaylists),
        ("testFeaturedPlaylists", testFeaturedPlaylists),
        ("testNewAlbumReleases", testNewAlbumReleases),
        ("testRecommendations", testRecommendations)
    ]
    
    func testCategory() { category() }
    func testCategories() { categories() }
    func testCategoryPlaylists() { categoryPlaylists() }
    func testFeaturedPlaylists() { featuredPlaylists() }
    func testNewAlbumReleases() { newAlbumReleases() }
    func testRecommendations() { recommendations() }
    
}
