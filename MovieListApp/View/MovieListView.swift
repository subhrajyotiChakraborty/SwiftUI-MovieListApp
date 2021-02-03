//
//  MovieListView.swift
//  MovieListApp
//
//  Created by Subhrajyoti Chakraborty on 27/12/20.
//

import SwiftUI

struct MovieListView: View {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @State private var pageCount = 1
    @State private var totalMoviesCount = 0
    @State private var searchText: String = ""
    @State private var results = [Movie]()
    @State private var isEditing = false
    @State private var showDetailView = false
    @State private var selectedMovie = Movie(Title: "", Year: "", imdbID: "", Poster: "", isFav: false)
    @State private var isInitialViewLoad = false
    @EnvironmentObject var favMoviesList: FavMoviesObservable
    
    func loadData(searchKey:String="", isOnAppear: Bool=true) {
        
        let movieName = searchKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if (isOnAppear && searchText.trimmingCharacters(in: .whitespacesAndNewlines).count != 0) {
            return
        }
        
        var movieURL: String = ""
        movieURL = "https://flask-movie-app.herokuapp.com/movies/\(movieName.count != 0 ? movieName : "Jurassic")?page=\(pageCount)"
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
                        self.totalMoviesCount = Int(decodedResponse.totalResults)!
                        self.results += decodedResponse.Search
                        self.isInitialViewLoad = true
                    }
                    return
                }
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
        }.resume()
    }
    
    func loadMoreMovies() {
        totalMoviesCount = 0
        loadData(searchKey: self.searchText, isOnAppear: false)
    }
    
    func loadMoviePoster(movieData: Movie) -> String {
        if movieData.Poster == "N/A" {
            return "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTChQdlYiED1Ot1XBsYrExnQlEPnuU55oXFXA&usqp=CAU"
        }
        return movieData.Poster
    }
    
    var body: some View {
        VStack {
            HStack {
                
                TextField("Search ...", text: $searchText) {    isEditing in
                    self.isEditing = isEditing
                } onCommit: {
                    pageCount = 1
                    results = [Movie]()
                    totalMoviesCount = 0
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
                                Image(uiImage: loadMoviePoster(movieData: movie).load())
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
                
                .padding(.vertical)
                
                if totalMoviesCount > results.count {
                    Button(action: {
                        pageCount += 1
                        loadMoreMovies()
                    }, label: {
                        Text("Load More")
                            .frame(width: 100, height: 30, alignment: .center)
                    })
                    .padding()
                    .border(Color.blue, width: 1)
                    .contentShape(Rectangle())
                }
            }
            .padding(.vertical)
            
            .sheet(isPresented: $showDetailView, content: {
                DetailView(imdbId: $selectedMovie.imdbID, movieTitle: $selectedMovie.Title, isFav: $selectedMovie.isFav, favMoviesObservable: self.favMoviesList)
            })
            .onAppear(perform: {
                if isInitialViewLoad {
                    print("condition")
                    return
                }
                loadData(searchKey: "", isOnAppear: true)
            })
        }
    }
}

struct MovieListView_Previews: PreviewProvider {
    static var previews: some View {
        MovieListView()
    }
}
