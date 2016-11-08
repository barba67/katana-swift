//
//  CodingLoveState.swift
//  Katana
//
//  Created by Alain Caltieri on 07/11/16.
//  Copyright © 2016 Bending Spoons. All rights reserved.
//
import Katana

struct CodingLoveState: State {
    var posts = [Post]()
    var loading = false
    var allPostsFetched = false
    
    var page = 0
}
