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
    private let cellHeight: CGFloat = 100

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
                                        .frame(height: cellHeight)
                                        .onTapGesture {
                                            selectedPokemon = pokemonDetail
                                        }
                            }
                        }
                                .frame(minHeight: geo.size.height)
                                .padding(.horizontal)
                        if (!pokemonDetails.isEmpty && nextPageURL != nil) {
                            PullToRefresh(coordinateSpaceName: "pullToRefresh", pullsDown: false, offset: stageHeight, frameHeight: geo.size.height) {
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
                    APIRequests.loadPokemonDetails(pokemonsToLoad: pokemonsToLoad, onCompletion: { loadedDetails in
                        if selectedPokemon == nil && !loadedDetails.isEmpty {
                            selectedPokemon = loadedDetails[0]
                        }
                        for pokemonDetail in loadedDetails {
                            pokemonDetails.append(pokemonDetail)
                        }
                    })
                }
    }

    func loadPokemons() {
        APIRequests.loadPokemons(nextPageURL: nextPageURL, onCompletion: { pokemonPage in
            previousPageURL = pokemonPage.previous
            nextPageURL = pokemonPage.next
            pokemonsToLoad = pokemonPage.results
        })
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
