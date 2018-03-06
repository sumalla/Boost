//
//  UploadKeyTests.swift
//  BoostCoreTests
//
//  Created by Ondrej Rafaj on 04/03/2018.
//

import XCTest
import Vapor
import VaporTestTools
import FluentTestTools
import ApiCoreTestTools
import BoostTestTools
@testable import ApiCore
@testable import BoostCore


class UploadKeysControllerTests: XCTestCase, UploadKeyTestCaseSetup, LinuxTests {
    
    var app: Application!
    
    var user1: User!
    var user2: User!
    
    var team1: Team!
    var team2: Team!
    
    var key1: UploadKey!
    var key2: UploadKey!
    var key3: UploadKey!
    var key4: UploadKey!
    
    var team4: Team!
    
    
    // MARK: Linux
    
    static let allTests: [(String, Any)] = [
        ("testGetUploadKeysForUser", testGetUploadKeysForUser),
        ("testGetUploadKeysForTeam", testGetUploadKeysForTeam),
        ("testCreateUploadKey", testCreateUploadKey),
        ("testChangeUploadKeyName", testChangeUploadKeyName),
        ("testDeleteUploadKey", testDeleteUploadKey),
        ("testGetOneUploadKey", testGetOneUploadKey),
        ("testLinuxTests", testLinuxTests)
    ]
    
    func testLinuxTests() {
        doTestLinuxTestsAreOk()
    }
    
    // MARK: Setup
    
    override func setUp() {
        super.setUp()
        
        app = Application.testable.newBoostTestApp()
        
        app.testable.delete(allFor: Token.self)
        
        setupUploadKeys()
    }
    
    // MARK: Tests
    
    func testGetUploadKeysForUser() {
        let req = HTTPRequest.testable.get(uri: "/keys", authorizedUser: user1, on: app)
        let res = app.testable.response(to: req)
        
        res.testable.debug()
        
        let keys = res.testable.content(as: [UploadKey.Display].self)!
        
        XCTAssertEqual(keys.count, 3, "There should be right amount of keys for the user")
        
        XCTAssertTrue(res.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(res.testable.has(contentType: "application/json; charset=utf-8"), "Missing content type")
    }
    
    func testGetUploadKeysForTeam() {
        let req = try! HTTPRequest.testable.get(uri: "/teams/\(team1.id!.uuidString)/keys".makeURI(), authorizedUser: user1, on: app)
        let res = app.testable.response(to: req)
        
        res.testable.debug()
        
        let keys = res.testable.content(as: [UploadKey.Display].self)!
        
        XCTAssertEqual(keys.count, 2, "There should be right amount of keys for the team")
        
        keys.forEach { (key) in
            XCTAssertEqual(key.teamId, team1.id!, "Team ID doesn't match")
        }
        
        XCTAssertTrue(res.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(res.testable.has(contentType: "application/json; charset=utf-8"), "Missing content type")
    }
    
    func testCreateUploadKey() {
        // Test setup
        var count = app.testable.count(allFor: UploadKey.self)
        XCTAssertEqual(count, 4, "There should be two team entries in the db at the beginning")
        
        // Execute request
        let expiryDate = Date()
        let post = UploadKey.New(name: "new key", expires: expiryDate)
        let postData = try! post.asJson()
        let req = try! HTTPRequest.testable.post(uri: "/teams/\(team1.id!.uuidString)/keys".makeURI(), data: postData, headers: [
            "Content-Type": "application/json; charset=utf-8"
            ] , authorizedUser: user1, on: app
        )
        let res = app.testable.response(to: req)
        
        res.testable.debug()
        
        let key = res.testable.content(as: UploadKey.self)!
        let privateKey = UUID(uuidString: key.token)
        
        XCTAssertNotNil(privateKey, "Token should have been created properly")
        XCTAssertEqual(key.teamId, team1.id!, "Team ID doesn't match")
        XCTAssertEqual(key.expires, expiryDate, "Team ID doesn't match")
        
        XCTAssertTrue(res.testable.has(statusCode: .created), "Wrong status code")
        XCTAssertTrue(res.testable.has(contentType: "application/json; charset=utf-8"), "Missing content type")
        
        count = app.testable.count(allFor: UploadKey.self)
        XCTAssertEqual(count, 5, "There should be two team entries in the db at the beginning")
    }
    
    func testChangeUploadKeyName() {
        let expiryDate = Date()
        let post = UploadKey.New(name: "updated key", expires: expiryDate)
        let postData = try! post.asJson()
        let req = try! HTTPRequest.testable.put(uri: "/keys/\(key1.id!.uuidString)".makeURI(), data: postData, headers: [
            "Content-Type": "application/json; charset=utf-8"
            ] , authorizedUser: user1, on: app
        )
        let res = app.testable.response(to: req)
        
        res.testable.debug()
        
        let key = app.testable.one(for: UploadKey.Display.self, id: key1.id!)!
        
        XCTAssertEqual(key.name, post.name, "Name hasn't been updated")
        
        let formatter = DateFormatter()
        
        XCTAssertEqual(formatter.string(from: key.expires!), formatter.string(from: post.expires!), "Expiry date hasn't been updated")
        
        XCTAssertTrue(res.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(res.testable.has(contentType: "application/json; charset=utf-8"), "Missing content type")
    }
    
    func testDeleteUploadKey() {
        var count = app.testable.count(allFor: UploadKey.self)
        XCTAssertEqual(count, 4, "There should be two team entries in the db at the beginning")
        
        let req = try! HTTPRequest.testable.delete(uri: "/keys/\(key2.id!.uuidString)".makeURI(), authorizedUser: user1, on: app)
        let res = app.testable.response(to: req)
        
        res.testable.debug()
        
        XCTAssertTrue(res.testable.has(statusCode: .noContent), "Wrong status code")
        
        app.testable.all(for: UploadKey.self).forEach { (key) in
            XCTAssertNotEqual(key.id!, key2.id!, "Key has not been deleted")
        }
        
        count = app.testable.count(allFor: UploadKey.self)
        XCTAssertEqual(count, 3, "There should be two team entries in the db at the end")
    }
    
    func testGetOneUploadKey() {
        let req = try! HTTPRequest.testable.get(uri: "/keys/\(key4.id!.uuidString)".makeURI(), authorizedUser: user1, on: app)
        let res = app.testable.response(to: req)
        
        res.testable.debug()
        
        let key = res.testable.content(as: UploadKey.Display.self)!
        
        XCTAssertEqual(key.id!, key4.id!, "Key has not been retrieved")
        
        XCTAssertTrue(res.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(res.testable.has(contentType: "application/json; charset=utf-8"), "Missing content type")
    }
    
}

