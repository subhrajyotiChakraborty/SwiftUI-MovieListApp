//
//  ContentView.swift
//  MovieListApp
//
//  Created by Subhrajyoti Chakraborty on 03/12/20.
//

import SwiftUI

struct ContentView: View {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @State private var searchText: String = ""
    @State private var results = [Movie]()
    @State private var favResults = [Movie]()
    
    func loadData(searchKey:String="Jurassic", isOnAppear: Bool=true) {
        
        let movieName = searchKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
//        if (isOnAppear && movieName.count != 0) {
//            return
//        }
        
        var movieURL: String = ""
        movieURL = "https://flask-movie-app.herokuapp.com/movie/\(movieName)"
        
        guard let url = URL(string: movieURL) else {
            print("Invalid URL")
            return
        }
        
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(Movies.self, from: data) {
                    DispatchQueue.main.async {
                        self.results = decodedResponse.Search
                    }
                    return
                }
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
        }.resume()
    }
    
    func loadFavMovies() {
        guard let url = URL(string: "https://flask-movie-app.herokuapp.com/favorites") else {
            print("Invalid URL")
            return
        }
        
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(FavMovies.self, from: data) {
                    DispatchQueue.main.async {
                        self.favResults = decodedResponse.movies
                    }
                    return
                }
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
        }.resume()
    }
    
    var body: some View {
        TabView {
            VStack {
                TextField("Search...", text: $searchText) { isEditing in
                    print("is onEditChange \(isEditing)")
                } onCommit: {
                    print("Enter pressed!")
                    loadData(searchKey: self.searchText, isOnAppear: false)
                }

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(results, id: \.imdbID) {movie in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: movie.Poster.load())
                                    .resizable()
                                    .scaledToFill()
                                Image(systemName: "heart")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding()
                                    .background(Color.black.opacity(0.75))
                                    .clipShape(Circle())
                                    .offset(x: -0, y: -0)
                                    .onTapGesture {
                                        print("Fav tapped!!")
                                    }
                            }
                            .frame(width: 180, height: 300)
                            .clipShape(Rectangle())
                            .border(Color.white, width: 1)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .tabItem {
                Image(systemName: "list.dash")
                Text("Movies")
            }
            .onAppear(perform: {
                loadData()
            })
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(favResults, id: \.imdbID) {movie in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: movie.Poster.load())
                                .resizable()
                                .scaledToFill()
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.black.opacity(0.75))
                                .clipShape(Circle())
                                .offset(x: -0, y: -0)
                                .onTapGesture {
                                    print("Fav tapped!!")
                                }
                        }
                        .frame(width: 180, height: 300)
                        .clipShape(Rectangle())
                        .border(Color.white, width: 1)
                    }
                }
                .padding(.horizontal)
            }
            .tabItem {
                Image(systemName: "heart.fill")
                Text("Favorits")
            }
            .onAppear(perform: {
                loadFavMovies()
            })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


extension String {
    func load() -> UIImage {
        do {
            guard let url = URL(string: self) else { return UIImage() }
            let data: Data = try Data(contentsOf: url)
            return UIImage(data: data) ?? UIImage()
        } catch {
            print("Unable to load image")
        }
        return UIImage()
    }
}

struct Movie: Codable {
    let Title: String
    let Year: String
    let imdbID: String
    let Poster: String
    let isFav: Bool?
}

struct Movies: Codable {
    let Search: [Movie]
}

struct FavMovies: Codable {
    let movies: [Movie]
}
