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
    @State private var nextPageURL: String? = "https://pokeapi.co/api/v2/pokemon?limit=20&offset=0" // Change the limit param to modify batch size
    @State private var selectedPokemon: PokemonDetail? = nil
    @State private var stageImageIsShiny = false
    @State private var likedPokemons = [String]()
    private let stageHeight: CGFloat = 200
    private let cellHeight: CGFloat = 100

    let columns = [GridItem(.adaptive(minimum: 100))]

    // The stage image flash every 0.5 seconds
    let imageSwitchTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            ZStack {
                Rectangle() // The black stage background
                        .fill(.black)
                        .frame(height: stageHeight)
                        .padding(10)
                        .overlay(alignment: .topTrailing) {  // The heart button
                            if let selectedPokemonDetail = selectedPokemon {
                                Image(systemName: likedPokemons.contains(selectedPokemonDetail.name) ? "heart.fill" : "heart")
                                        .resizable()
                                        .padding(30)
                                        .frame(width: 90.0, height: 85.0)
                                        .foregroundColor(.white)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if likedPokemons.contains(selectedPokemonDetail.name) {
                                                if let index = likedPokemons.firstIndex(of: selectedPokemonDetail.name) {
                                                    likedPokemons.remove(at: index)
                                                }
                                            } else {
                                                likedPokemons.append(selectedPokemonDetail.name)
                                            }
                                        }
                            }
                        }

                // The selected pokemon
                if let selectedPokemonDetail = selectedPokemon {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("#\(selectedPokemonDetail.id)")
                            Text(selectedPokemonDetail.name.capitalized)
                        }
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .heavy, design: .default))
                                .padding(.leading, 10)
                        AsyncImage(
                                url: URL(string: stageImageIsShiny ? selectedPokemonDetail.sprites.front_shiny : selectedPokemonDetail.sprites.front_default),
                                content: { image in
                                    image.resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxHeight: stageHeight)
                                },
                                placeholder: {
                                    ProgressView()
                                }
                        )
                                .onReceive(imageSwitchTimer) { _ in
                                    stageImageIsShiny.toggle()
                                }
                    }
                }
            }
            
            // The list of pokemons
            GeometryReader { geo in
                ScrollViewReader { scrollView in
                    ScrollView {
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
                    URLCache.shared.diskCapacity = 10_000_000 // configure ~10 MB disk cache space
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
