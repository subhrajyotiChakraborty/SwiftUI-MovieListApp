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
    @State private var isEditing = false
    @State private var showDetailView = false
    @State private var selectedMovie = Movie(Title: "", Year: "", imdbID: "", Poster: "", isFav: false)
    @State private var isInitialViewLoad = false
    @ObservedObject var favMoviesList = FavMoviesObservable()
    
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
                    DetailView(imdbId: $selectedMovie.imdbID, movieTitle: $selectedMovie.Title, isFav: $selectedMovie.isFav, favMoviesObservable: self.favMoviesList)
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
                        ForEach(favMoviesList.movies, id: \.imdbID) {movie in
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
    @ObservedObject var favMoviesObservable: FavMoviesObservable
    
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
    
    func createMovieData() -> Movie {
        let movieData = Movie(Title: movieDetailsData.Title, Year: movieDetailsData.Year, imdbID: movieDetailsData.imdbID, Poster: movieDetailsData.Poster, isFav: true)
        return movieData
    }
    
    func saveAsFavMovies(movie: Movie) {
        let index = favMoviesObservable.movies.firstIndex { (movieI) -> Bool in
            movie.imdbID == movieI.imdbID
        }
        if index != nil {
            return
        }
        isFav = false
        favMoviesObservable.movies.append(movie)
        favMoviesObservable.save()
        isFav?.toggle()
        
        print("Total fav count add =>", favMoviesObservable.movies.count)
    }
    
    func deleteFromSavedMovies(imdbID: String) {
        let filteredList = favMoviesObservable.movies.filter { (movie) -> Bool in
            return movie.imdbID != imdbID
        }
        favMoviesObservable.movies = filteredList
        favMoviesObservable.save()
        isFav?.toggle()
        
        print("Total fav count delete =>", favMoviesObservable.movies.count)
    }
    
    //    func addToFavorites(movie: Movie) {
    //        guard let encoded = try? JSONEncoder().encode(movie) else {
    //            print("Unable to encode movie data")
    //            return
    //        }
    //
    //                let url = URL(string: "https://flask-movie-app.herokuapp.com/movie")!
    //
    //        var request = URLRequest(url: url)
    //
    //        //        let body: [String: String] = ["Title": movie.Title, "Poster": movie.Poster, "imdbID": movie.imdbID, "Year": movie.Year]
    //        //
    //        //        let finalBody = try! JSONSerialization.data(withJSONObject: body)
    //
    //        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    //        request.httpMethod = "POST"
    //
    //        // request.httpBody = finalBody
    //        request.httpBody = encoded
    //
    //        URLSession.shared.dataTask(with: request) { (data, response, error) in
    //            if let data = data {
    //                if let decodedData = try? JSONDecoder().decode(Movie.self, from: data) {
    //                    print("Successfully added to fav list!!")
    //                    return
    //                } else {
    //                    print("Invalid response from server")
    //                    return
    //                }
    //            }
    //            print("Error => \(error?.localizedDescription ?? "Unknown error")")
    //        }.resume()
    //    }
    
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
                                        if let fav = isFav {
                                            // remove or add from fav
                                            fav ?  deleteFromSavedMovies(imdbID: movieDetailsData.imdbID) : saveAsFavMovies(movie: createMovieData())
                                        } else {
                                            saveAsFavMovies(movie: createMovieData())
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


