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

struct AddProject: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate add-project url from a markdown file",
        version: "0.0.1"
    )

    @Argument(help: "Path to markdown tasks file")
    var file: String

    mutating func run() throws {
        let file = try String(contentsOfFile: self.file)
        var lines = file.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard !lines.isEmpty else {
            print("empty file given", to: &stdErr)
            throw ExitCode.failure
        }

        var title = lines[0]
        guard title.deletingPrefix("# ") else {
            print("title should begin with #", to: &stdErr)
            throw ExitCode.failure
        }
        lines = Array(lines.dropFirst())

        var todo = [String]()
        for line in lines {
            var line = line
            guard line.deletingPrefix("- [ ]") else {
                print("title should begin with #", to: &stdErr)
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

AddProject.main()
