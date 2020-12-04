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
    @State private var isEditing = false
    
    func loadData(searchKey:String="", isOnAppear: Bool=true) {
        
        let movieName = searchKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if (isOnAppear && searchText.trimmingCharacters(in: .whitespacesAndNewlines).count != 0) {
            return
        }
        
        var movieURL: String = ""
        movieURL = "https://flask-movie-app.herokuapp.com/movie/\(movieName.count != 0 ? movieName : "Jurassic")"
        movieURL = movieURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
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
                HStack {
                    
                    TextField("Search ...", text: $searchText) {    isEditing in
                        self.isEditing = isEditing
                    } onCommit: {
                        loadData(searchKey: self.searchText, isOnAppear: false)
                    }
                    .padding(7)
                    .padding(.horizontal, 25)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 8)
                            
                            if isEditing {
                                Button(action: {
                                    self.searchText = ""
                                }) {
                                    Image(systemName: "multiply.circle.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 8)
                                }
                            }
                            
                        }
                    )
                    .padding(.horizontal, 10)
                    
                    if isEditing {
                        withAnimation {
                            return                         Button(action: {
                                self.isEditing = false
                                self.searchText = ""
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                
                            }) {
                                Text("Cancel")
                            }
                            .padding(.trailing, 10)
                            .transition(.move(edge: .trailing))
                            .animation(.default)
                        }
                    }
                }
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(results, id: \.imdbID) {movie in
                            Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                                ZStack {
                                    Image(uiImage: movie.Poster.load())
                                        .resizable()
                                        .scaledToFill()
                                }
                            })
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
                loadData(searchKey: "", isOnAppear: true)
            })
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(favResults, id: \.imdbID) {movie in
                        ZStack {
                            Image(uiImage: movie.Poster.load())
                                .resizable()
                                .scaledToFill()
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
