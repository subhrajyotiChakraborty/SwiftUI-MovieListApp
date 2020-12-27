//
//  ContentView.swift
//  MovieListApp
//
//  Created by Subhrajyoti Chakraborty on 03/12/20.
//

import SwiftUI

struct ContentView: View {
    var favMoviesList = FavMoviesObservable()
    
    var body: some View {
        NavigationView {
            TabView {
                MovieListView()
                    .tabItem {
                        Image(systemName: "list.dash")
                        Text("Movies")
                    }
                    .environmentObject(favMoviesList)
                
                FavoritesView()
                    .tabItem {
                        Image(systemName: "heart.fill")
                        Text("Favorits")
                    }
                    .environmentObject(favMoviesList)
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



