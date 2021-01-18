//
// Things URL generator
// 2021 Alexey Korolev <alphatroya@gmail.com>
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
        discussion: """
        Command receives data from the stdin channel and sends add-project Things deeplink URL to stdout.

        EXAMPLE:
        > echo '# Test project\\nNotes\\n- [ ] first item\\n- [ ] second item' | things-url-generator
        things:///add-project?title=Test%20project&notes=Notes&to-dos=%20first%20item%0A%20second%20item&reveal=true

        By opening that link, a new project named "Test project" will be added and revealed in the Things app.
        The created project will contain a note description "Notes" and two to-do items.
        """,
        version: "0.0.1"
    )

    mutating func run() throws {
        var title: String?
        var noteLines: [String] = []
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
            if !line.deletingPrefix("- [ ]") {
                if todo.isEmpty {
                    noteLines.append(line)
                    continue
                }
                print("todo item should begin with - [ ]", to: &stdErr)
                throw ExitCode.failure
            }
            todo.append(line)
        }

        guard title != nil else {
            print("empty buffer passed to stdin", to: &stdErr)
            throw ExitCode.failure
        }

        var components = URLComponents()
        components.scheme = "things"
        components.host = ""
        components.path = "/add-project"
        var query = [URLQueryItem(name: "title", value: title)]
        if !noteLines.isEmpty {
            query.append(URLQueryItem(name: "notes", value: noteLines.joined(separator: "\n")))
        }
        if !todo.isEmpty {
            query.append(URLQueryItem(name: "to-dos", value: todo.joined(separator: "\n")))
        }
        query.append(URLQueryItem(name: "reveal", value: "true"))
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
