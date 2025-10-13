//
//  MPKitAdobeTests.swift
//  mParticle-Adobe
//
//  Created by Denis Chilik on 10/9/25.
//
@testable import mParticle_Adobe
import Foundation
import XCTest

import Foundation

extension URLSessionConfiguration {
    @objc class func mockDefaultSessionConfiguration() -> URLSessionConfiguration {
        let config = self.mockDefaultSessionConfiguration()
        config.protocolClasses = [URLProtocolMock.self]
        return config
    }

    static func swizzleDefaultConfiguration() {
        let original = class_getClassMethod(URLSessionConfiguration.self, #selector(getter: URLSessionConfiguration.default))
        let mock = class_getClassMethod(URLSessionConfiguration.self, #selector(URLSessionConfiguration.mockDefaultSessionConfiguration))
        method_exchangeImplementations(original!, mock!)
    }
}

final class URLProtocolMock: URLProtocol {
    static var testData: Data?
    static var testResponse: HTTPURLResponse?
    static var testError: Error?
    
    static var canInitRequestParam: URLRequest?
    static var canonicalReceivedRequestParam: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool {
        canInitRequestParam = request
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        canonicalReceivedRequestParam = request
        return request
    }

    override func startLoading() {
        if let error = URLProtocolMock.testError {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            if let response = URLProtocolMock.testResponse {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = URLProtocolMock.testData {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}


final class MPAdobeTests: XCTestCase {
    override func setUp() {
        super.setUp()

        URLSessionConfiguration.swizzleDefaultConfiguration()
        let config = URLSessionConfiguration.default
        config.protocolClasses = [URLProtocolMock.self]
    }
    
    func testSendRequestMocked() {
        let json = [
            "d_mid": "mock_mid",
            "d_blob": "mock_blob",
            "dcs_region": "mock_region"
        ]
        let data = try! JSONSerialization.data(withJSONObject: json, options: [])
        
        URLProtocolMock.testData = data
        URLProtocolMock.testResponse = HTTPURLResponse(
            url: URL(string: "https://dpm.demdex.net")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let expectation = XCTestExpectation(description: "completion called")
        let sut = MPIAdobe()
        sut.sendRequest(
            withMarketingCloudId: "",
            advertiserId: "",
            pushToken: "",
            organizationId: "",
            userIdentities: [:],
            audienceManagerServer: ""
        ) { marketingCloudId, blob, locationHint, error in
            XCTAssertEqual(marketingCloudId, "mock_mid")
            XCTAssertEqual(blob, "mock_region")
            XCTAssertEqual(locationHint, "mock_blob")
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
        let expectedRequest = URLRequest(url: URL(string: "https://dpm.demdex.net/id?d_mid=&d_cid=20915%2501&d_cid=20920%2501&d_orgid=&d_ptfm=ios&d_ver=2")!)
        XCTAssertEqual(URLProtocolMock.canInitRequestParam, expectedRequest)
        XCTAssertEqual(URLProtocolMock.canonicalReceivedRequestParam, expectedRequest)
    }
}
