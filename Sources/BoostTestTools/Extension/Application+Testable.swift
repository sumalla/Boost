//
//  Application+Testable.swift
//  BoostTestTools
//
//  Created by Ondrej Rafaj on 27/02/2018.
//

import Foundation
import ApiCore
import BoostCore
import Vapor
import FileCore
import VaporTestTools
import ApiCoreTestTools
import DbCore


extension TestableProperty where TestableType: Application {
    
    public static func newBoostTestApp() throws -> Application {
        let app = try newApiCoreTestApp({ (config, env, services) in
            let fileHandler = try! Filesystem(config: Filesystem.Config(homeDir: "/tmp/Boost/Tests"))
            var boostConfig = BoostConfig(fileHandler: fileHandler)
            boostConfig.database = DbCore.config(hostname: "localhost", user: "test", password: "aaaaaa", database: "boost-test")
            try! Boost.configure(boostConfig: &boostConfig, &config, &env, &services)
        }) { (router) in
            try? Boost.boot(router: router)
        }
        return app
    }
    
}