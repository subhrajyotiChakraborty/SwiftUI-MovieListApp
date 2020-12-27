//
//  FavoritesView.swift
//  MovieListApp
//
//  Created by Subhrajyoti Chakraborty on 28/12/20.
//

import SwiftUI

struct FavoritesView: View {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    @State private var showDetailView: Bool = false
    @State private var selectedMovie = Movie(Title: "", Year: "", imdbID: "", Poster: "", isFav: false)
    @EnvironmentObject var favMoviesList: FavMoviesObservable
    
    var body: some View {
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
        .sheet(isPresented: $showDetailView, content: {
            DetailView(imdbId: $selectedMovie.imdbID, movieTitle: $selectedMovie.Title, isFav: $selectedMovie.isFav, favMoviesObservable: self.favMoviesList)
        })
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
    }
}
