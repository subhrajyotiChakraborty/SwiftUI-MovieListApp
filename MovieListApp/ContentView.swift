//
//  ContentView.swift
//  MovieListApp
//
//  Created by Subhrajyoti Chakraborty on 03/12/20.
//

import SwiftUI

struct ContentView: View {
    let data = (0...10).map { "Item \($0)" }
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @State private var searchText: String = ""
    
    var body: some View {
        TabView {
            VStack {
                TextField("Search...", text: $searchText)
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(data, id: \.self) {item in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: "https://m.media-amazon.com/images/M/MV5BNjM0NTc0NzItM2FlYS00YzEwLWE0YmUtNTA2ZWIzODc2OTgxXkEyXkFqcGdeQXVyNTgwNzIyNzg@._V1_SX300.jpg".load())
                                    .resizable()
                                    .scaledToFill()
                                Text(item)
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
            
            Text("2")
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favorits")
                }
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
