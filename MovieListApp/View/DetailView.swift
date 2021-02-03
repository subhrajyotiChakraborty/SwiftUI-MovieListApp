//
//  DetailView.swift
//  MovieListApp
//
//  Created by Subhrajyoti Chakraborty on 28/12/20.
//

import SwiftUI

struct DetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = true
    @State private var showAlert = false
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
            showAlert.toggle()
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
    
    func loadMoviePoster(movieData: MovieDetails) -> String {
        if movieData.Poster == "N/A" {
            return "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTChQdlYiED1Ot1XBsYrExnQlEPnuU55oXFXA&usqp=CAU"
        }
        return movieData.Poster
    }
    
    func simpleSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
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
                                Image(uiImage: loadMoviePoster(movieData: movieDetailsData).load())
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
                                        simpleSuccessHaptic()
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
            .alert(isPresented: $showAlert, content: {
                Alert(title: Text("Movie already present in favorites"))
            })
            .onAppear(perform: {
                self.isLoading = true
                self.loadMovieDetail()
            })
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(imdbId: .constant("1234"), movieTitle: .constant("TEST"), isFav: .constant(false), favMoviesObservable: FavMoviesObservable())
    }
}
