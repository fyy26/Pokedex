//
//  ContentView.swift
//  Pokedex
//
//  Created by Yuying Fan on 1/2/23.
//

import SwiftUI

struct ContentView: View {
    @State private var pokemonsToLoad = [Pokemon]()
    @State private var pokemonDetails = [PokemonDetail]()
    @State private var previousPageURL: String? = nil
    @State private var nextPageURL: String? = "https://pokeapi.co/api/v2/pokemon?limit=20&offset=0"
    @State private var selectedPokemon: PokemonDetail? = nil
    private let stageHeight: CGFloat = 200

    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]

    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                        .fill(.black)
                        .frame(height: stageHeight)
                        .padding(10)
                if let selectedPokemonDetail = selectedPokemon {
                    AsyncImage(
                            url: URL(string: selectedPokemonDetail.sprites.front_default),
                            content: { image in
                                image.resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: stageHeight)
                            },
                            placeholder: {
                                ProgressView()
                            }
                    )
                }
            }
            GeometryReader { geo in
                ScrollViewReader { scrollView in
                    ScrollView {
//                        PullToRefresh(coordinateSpaceName: "pullToRefresh", offset: stageHeight, frameHeight: geo.size.height) {
//                            print("load previous page")
//                        }
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(pokemonDetails) { pokemonDetail in
                                AsyncImage(url: URL(string: pokemonDetail.sprites.front_default))
                                        .onTapGesture {
                                            selectedPokemon = pokemonDetail
                                        }
                            }
                        }
                                .frame(minHeight: geo.size.height)
                                .padding(.horizontal)
                        if (!pokemonDetails.isEmpty && nextPageURL != nil) {
                            PullToRefresh(coordinateSpaceName: "pullToRefresh", pullsDown: false, offset: stageHeight, frameHeight: geo.size.height) {
                                print("load next page")
                                loadPokemons()
                            }
                                    .frame(alignment: .bottom)
                        }
                    }
                }
            }
        }
                .onAppear(perform: {
                    loadPokemons()
                })
                .onChange(of: pokemonsToLoad) { _ in
                    for pokemon in pokemonsToLoad {
                        loadPokemonDetails(url: pokemon.url)
                    }
                }
    }

    func loadPokemons() {
        // Prepare the url to fetch
        guard let urlString = nextPageURL else {
            print("Nothing more to fetch")
            return
        }
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        // Make the request
        let urlRequest = URLRequest(url: url)
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }
            guard let response = response as? HTTPURLResponse else {
                return
            }
            if response.statusCode == 200 {
                guard let data = data else {
                    return
                }
                DispatchQueue.main.async {
                    do {
                        let pokemonPage = try JSONDecoder().decode(PokemonPage.self, from: data)
                        previousPageURL = pokemonPage.previous
                        nextPageURL = pokemonPage.next
                        pokemonsToLoad = pokemonPage.results
                    } catch let error {
                        print("Decoding error: ", error)
                    }
                }
            }
        }
        dataTask.resume()
    }

    func loadPokemonDetails(url: String) {
        guard let pokemonURL = URL(string: url) else {
            print("Invalid URL")
            return
        }
        let urlRequest = URLRequest(url: pokemonURL)
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }
            guard let response = response as? HTTPURLResponse else {
                return
            }
            if response.statusCode == 200 {
                guard let data = data else {
                    return
                }
                DispatchQueue.main.async {
                    do {
                        let pokemonDetail = try JSONDecoder().decode(PokemonDetail.self, from: data)
                        pokemonDetails.append(pokemonDetail)
                        if selectedPokemon == nil {
                            selectedPokemon = pokemonDetail
                        }
                    } catch let error {
                        print("Decoding error: ", error)
                    }
                }
            }
        }
        dataTask.resume()
    }
}

struct PullToRefresh: View {

    var coordinateSpaceName: String
    var pullsDown = true  // true = pull down to trigger, false = pull up to trigger
    var offset: CGFloat = 0
    var frameHeight: CGFloat
    var onRefresh: () -> Void

    @State var needRefresh: Bool = false

    var body: some View {
        GeometryReader { geo in
            if (pullsDown && geo.frame(in: .named(coordinateSpaceName)).midY > offset + 50 ||
                    !pullsDown && geo.frame(in: .named(coordinateSpaceName)).midY < offset + frameHeight - 50) {
                Spacer()
                        .onAppear {
                            needRefresh = true
                        }
            } else if (pullsDown && geo.frame(in: .named(coordinateSpaceName)).maxY < offset + 10 ||
                    !pullsDown && geo.frame(in: .named(coordinateSpaceName)).maxY > offset + frameHeight) {
                Spacer()
                        .onAppear {
                            if needRefresh {
                                needRefresh = false
                                onRefresh()
                            }
                        }
            }
            HStack {
                Spacer()
                if needRefresh {
                    ProgressView()
                }
                Spacer()
            }
        }
                .padding(.top, pullsDown ? -50 : 0)
                .padding(.bottom, pullsDown ? 0 : -50)
    }
}
