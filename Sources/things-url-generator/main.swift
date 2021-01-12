//
// Things URL generator
// 2020 Alexey Korolev <alphatroya@gmail.com>
//

import ArgumentParser
import Foundation

private var stdErr = StandardErrorOutputStream()

private struct StandardErrorOutputStream: TextOutputStream {
    let stderr = FileHandle.standardError

    func write(_ string: String) {
        guard let data = string.data(using: .utf8) else {
            return // encoding failure
        }
        stderr.write(data)
    }
}

struct ThingsUrlGenerator: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate add-project url from a markdown file",
        discussion: "Command receives data from the stdin channel and sends Things URL to stdout",
        version: "0.0.1"
    )

    mutating func run() throws {
        var title: String?
        var todo = [String]()
        while var line = readLine()?.trimmingCharacters(in: .whitespaces) {
            if line.isEmpty {
                if title != nil, !todo.isEmpty {
                    break
                }
                continue
            }
            if title == nil {
                guard line.deletingPrefix("# ") else {
                    print("title should begin with #", to: &stdErr)
                    throw ExitCode.failure
                }
                title = line
                continue
            }
            guard line.deletingPrefix("- [ ]") else {
                print("todo item should begin with - [ ]", to: &stdErr)
                throw ExitCode.failure
            }
            todo.append(line)
        }

        var components = URLComponents()
        components.scheme = "things"
        components.host = ""
        components.path = "/add-project"
        let query = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "to-dos", value: todo.joined(separator: "\n")),
            URLQueryItem(name: "reveal", value: "true"),
        ]

        components.queryItems = query

        if let result = components.string {
            print(result)
        }
    }
}

private extension String {
    mutating func deletingPrefix(_ prefix: String) -> Bool {
        guard hasPrefix(prefix) else {
            return false
        }
        self = String(dropFirst(prefix.count))
        return true
    }
}

ThingsUrlGenerator.main()
