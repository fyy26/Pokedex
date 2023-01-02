//
//  APIResponse.swift
//  Pokedex
//
//  Created by Yuying Fan on 1/2/23.
//

import SwiftUI

struct PokemonPage: Codable {
    var results: [Pokemon]
    var previous: String?
    var next: String?
}

struct Pokemon: Identifiable, Codable, Equatable {
    var name: String
    var url: String
    var id: String {
        name
    }
}

struct PokemonDetail: Identifiable, Codable {
    var id: Int
    var name: String
    var sprites: Sprites

    struct Sprites: Codable {
        var front_default: String
    }
}

class APIRequests: Any {

    static func loadPokemons(nextPageURL: String?, onCompletion: @escaping (PokemonPage) -> ()) {
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
                        onCompletion(pokemonPage)
                    } catch let error {
                        print("Decoding error: ", error)
                    }
                }
            }
        }
        dataTask.resume()
    }

    static func loadPokemonDetails(url: String, onCompletion: @escaping ((PokemonDetail) -> ())) {
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
                        onCompletion(pokemonDetail)
                    } catch let error {
                        print("Decoding error: ", error)
                    }
                }
            }
        }
        dataTask.resume()
    }
}
