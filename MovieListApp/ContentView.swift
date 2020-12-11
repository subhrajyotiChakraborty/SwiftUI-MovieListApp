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
    @State private var showDetailView = false
    @State private var selectedMovie = Movie(Title: "", Year: "", imdbID: "", Poster: "", isFav: false)
    @State private var isInitialViewLoad = false
    
    func loadData(searchKey:String="", isOnAppear: Bool=true) {
        
        let movieName = searchKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if (isOnAppear && searchText.trimmingCharacters(in: .whitespacesAndNewlines).count != 0) {
            return
        }
        
        var movieURL: String = ""
        movieURL = "https://flask-movie-app.herokuapp.com/movies/\(movieName.count != 0 ? movieName : "Jurassic")"
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
                        self.isInitialViewLoad = true
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
        NavigationView {
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
                                Button(action: {
                                    self.selectedMovie = movie
                                    self.showDetailView = true
                                }, label: {
                                    ZStack {
                                        Image(uiImage: movie.Poster.load())
                                            .resizable()
                                            .scaledToFill()
                                    }
                                    .frame(width: 180, height: 300)
                                    .clipShape(Rectangle())
                                    .border(Color.white, width: 1)
                                })
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .sheet(isPresented: $showDetailView, content: {
                    DetailView(imdbId: $selectedMovie.imdbID, movieTitle: $selectedMovie.Title, isFav: $selectedMovie.isFav)
                })
                .tabItem {
                    Image(systemName: "list.dash")
                    Text("Movies")
                }
                .onAppear(perform: {
                    if isInitialViewLoad {
                        print("condition")
                        return
                    }
                    loadData(searchKey: "", isOnAppear: true)
                })
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(favResults, id: \.imdbID) {movie in
                            Button(action: {
                                self.selectedMovie = movie
                                self.showDetailView = true
                            }, label: {
                                ZStack {
                                    Image(uiImage: movie.Poster.load())
                                        .resizable()
                                        .scaledToFill()
                                }
                                .frame(width: 180, height: 300)
                                .clipShape(Rectangle())
                                .border(Color.white, width: 1)
                            })
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
            .navigationBarTitle("MovieList")
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
}

struct FavMovies: Codable {
    let movies: [Movie]
}

struct DeleteMovieResponse: Codable {
    let message: String
}

struct DetailView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = true
    @State private var movieDetailsData = MovieDetails(Title: "", Plot: "", Year: "", imdbID: "", Poster: "", Rated: "", Released: "", Runtime: "", Genre: "", Director: "", Writer: "", Actors: "", Language: "", Country: "", Awards: "", Metascore: "", imdbRating: "", imdbVotes: "", Production: "", Website: "")
    @Binding var imdbId: String
    @Binding var movieTitle: String
    @Binding var isFav: Bool?
    
    func loadMovieDetail() {
        let movieDetailsURL = "https://flask-movie-app.herokuapp.com/movie/\(imdbId)"
        print(movieDetailsURL)
        
        guard let url = URL(string: movieDetailsURL) else {
            self.isLoading = false
            return
        }
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
                if let decodedData = try? JSONDecoder().decode(MovieDetails.self, from: data) {
                    DispatchQueue.main.async {
                        self.movieDetailsData = decodedData
                        self.isLoading = false
                    }
                    return
                }
            }
            self.isLoading = false
            print("Fetch details: \(error?.localizedDescription ?? "Unknown error")")
        }.resume()
    }
    
    func addToFavorites(movie: Movie) {
        guard let encoded = try? JSONEncoder().encode(movie) else {
            print("Unable to encode movie data")
            return
        }
        
        let url = URL(string: "https://flask-movie-app.herokuapp.com/movie")!
        
        var request = URLRequest(url: url)
        
        //        let body: [String: String] = ["Title": movie.Title, "Poster": movie.Poster, "imdbID": movie.imdbID, "Year": movie.Year]
        //
        //        let finalBody = try! JSONSerialization.data(withJSONObject: body)
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        // request.httpBody = finalBody
        request.httpBody = encoded
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
                if let decodedData = try? JSONDecoder().decode(Movie.self, from: data) {
                    print("Successfully added to fav list!!")
                    return
                } else {
                    print("Invalid response from server")
                    return
                }
            }
            print("Error => \(error?.localizedDescription ?? "Unknown error")")
        }.resume()
    }
    
    var body: some View {
        
        NavigationView {
            GeometryReader { fullView in
                ScrollView {
                    if isLoading {
                        ProgressView("Loading...")
                            .frame(width: fullView.size.width, height: fullView.size.height, alignment: .center)
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            ZStack {
                                Image(uiImage: movieDetailsData.Poster.load())
                                    .resizable()
                                    .frame(width: fullView.size.width, height: 500)
                                    .scaledToFit()
                            }
                            Group {
                                Text(movieDetailsData.Plot)
                                    .padding(.vertical)
                                Section {
                                    Text("Director")
                                        .font(.headline)
                                    Text(movieDetailsData.Director)
                                        .padding(.vertical)
                                }
                                Section {
                                    Button(action: {
                                        if let _ = isFav {
                                            // remove from fav
                                        } else {
                                            let movieData = Movie(Title: movieDetailsData.Title, Year: movieDetailsData.Year, imdbID: movieDetailsData.imdbID, Poster: movieDetailsData.Poster, isFav: false)
                                            addToFavorites(movie: movieData)
                                        }
                                    }, label: {
                                        Image(systemName: isFav ?? false ? "minus.circle" : "plus.circle")
                                        Text(isFav ?? false ? "Remove from favorites" : "Add to favorites")
                                    })
                                }
                                
                            }
                            .padding(.horizontal)
                            
                        }
                    }
                }
            }
            .navigationBarItems(leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }, label: {
                Image(systemName: "chevron.left")
            }))
            .navigationBarTitle(Text(self.movieTitle), displayMode: .inline)
            .onAppear(perform: {
                self.isLoading = true
                self.loadMovieDetail()
            })
        }
    }
}


