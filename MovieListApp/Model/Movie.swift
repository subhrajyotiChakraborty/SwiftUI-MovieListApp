//
//  Movie.swift
//  MovieListApp
//
//  Created by Subhrajyoti Chakraborty on 28/12/20.
//

import Foundation

struct Movie: Codable {
    var Title: String
    let Year: String
    var imdbID: String
    let Poster: String
    var isFav: Bool?
}

struct MovieDetails: Codable {
    let Title: String
    let Plot: String
    let Year: String
    let imdbID: String
    let Poster: String
    let Rated: String
    let Released: String
    let Runtime: String
    let Genre: String
    let Director: String
    let Writer: String
    let Actors: String
    let Language: String
    let Country: String
    let Awards: String
    let Metascore: String
    let imdbRating: String
    let imdbVotes: String
    let Production: String
    let Website: String
}

struct Movies: Codable {
    let Search: [Movie]
    let totalResults: String
}

struct FavMovies: Codable {
    let movies: [Movie]
}

struct DeleteMovieResponse: Codable {
    let message: String
}

class FavMoviesObservable: ObservableObject {
    @Published var movies: [Movie]
    static let savedKey = "FavMoviesList"
    
    init() {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = path[0].appendingPathComponent(Self.savedKey)
        do {
            let data = try Data(contentsOf: filePath)
            let decodedData = try JSONDecoder().decode([Movie].self, from: data)
            self.movies = decodedData
            return
        } catch  {
            print("Unable to decode fav movies data \(error.localizedDescription)")
        }
        
        self.movies = []
    }
    
    func getPath() -> URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return path[0]
    }
    
    func load() {
        let filePath = getPath().appendingPathComponent(Self.savedKey)
        do {
            let data = try Data(contentsOf: filePath)
            let decodedData = try JSONDecoder().decode([Movie].self, from: data)
            self.movies = decodedData
        } catch  {
            print("Unable to decode the fav movie data \(error.localizedDescription)")
        }
    }
    
    func save() {
        let filePath = getPath().appendingPathComponent(Self.savedKey)
        do {
            let data = try JSONEncoder().encode(movies)
            try data.write(to: filePath, options: [.atomicWrite, .completeFileProtection])
        } catch  {
            print("Unable to encode fav movies \(error.localizedDescription)")
        }
    }
}
