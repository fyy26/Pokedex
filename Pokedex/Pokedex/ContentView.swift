//
//  ContentView.swift
//  Pokedex
//
//  Created by Yuying Fan on 1/2/23.
//

import SwiftUI

struct ContentView: View {
    @State private var pokemons = [Pokemon]()
    @State private var pokemonDetails = [PokemonDetail]()
    @State private var previousPageURL: String? = nil
    @State private var nextPageURL: String? = "https://pokeapi.co/api/v2/pokemon?limit=20&offset=0"
    @State private var selectedPokemon: PokemonDetail? = nil

    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]

    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                        .fill(.black)
                        .frame(height: 200)
                        .padding(10)
                if let selectedPokemonDetail = selectedPokemon {
                    AsyncImage(
                            url: URL(string: selectedPokemonDetail.sprites.front_default),
                            content: { image in
                                image.resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 200)
                            },
                            placeholder: {
                                ProgressView()
                            }
                    )
                }
            }
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(pokemonDetails) { pokemonDetail in
                        AsyncImage(url: URL(string: pokemonDetail.sprites.front_default))
                            .onTapGesture {
                                selectedPokemon = pokemonDetail
                            }
                    }
                }
                        .padding(.horizontal)
            }
        }
                .onAppear(perform: {
                    loadPokemons()
                })
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
                        pokemons = pokemonPage.results
                    } catch let error {
                        print("Decoding error: ", error)
                    }
                    // Load the image of each pokemon
                    pokemonDetails = [PokemonDetail]()
                    for pokemon in pokemons {
                        loadPokemonDetails(url: pokemon.url)
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
