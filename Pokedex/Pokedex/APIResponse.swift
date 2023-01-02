//
//  APIResponse.swift
//  Pokedex
//
//  Created by Yuying Fan on 1/2/23.
//

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
