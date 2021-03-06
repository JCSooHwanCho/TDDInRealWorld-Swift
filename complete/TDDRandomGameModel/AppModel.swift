import Foundation

public final class AppModel {
    private static let selectModeMessage =
        """
    1: Single player game
    2: Multiplayer game
    3: Exit
    """ + "\n" + "Enter selection: "

    public var isCompleted: Bool = false

    private let generator: PositiveIntegerGeneratable
    private var outputBuffer: [String]
    private var isSinglePlayerMode: Bool = false
    private lazy var processor: Processor = {
        return Processor(closure: self.processModeSelection(_:))
    }()

    public init(generator: PositiveIntegerGeneratable) {
        self.generator = generator
        self.outputBuffer = [Self.selectModeMessage]
    }

    public func flushOutput() -> String {
        defer {
            self.outputBuffer.removeAll()
        }

        return self.outputBuffer.joined()
    }

    public func processInput(_ input: String) {
        self.processor = self.processor(input: input)
    }

    private func print(_ message: String) {
        self.outputBuffer.append(message)
    }

    private func println(_ message: String) {
        self.outputBuffer.append(message + "\n")
    }

    private func processModeSelection(_ input: String) -> Processor {
        if input == "1" {
            self.println("Single player game")
            self.println("I'm thinking of a number between 1 and 100")
            self.print("Enter your guess: ")
            self.isSinglePlayerMode = true

            return self.getSinglePlayerGameProcessor(answer: self.generator.generateLessThanOrEqualToHundread(),
                                                     tries: 1)
        } else if input == "2" {
            self.println("Multiplayer game")
            self.print("Enter player names separated with commas: ")
            return self.startMultiPlayerGameProcessor(answer: self.generator.generateLessThanOrEqualToHundread())
        }else {
            self.isCompleted = true

            return .none
        }
    }

    private func getSinglePlayerGameProcessor(answer: Int, tries: Int) -> Processor {
        return Processor { [weak self] input in
            guard let self = self,
                  let guess = Int(input)
            else { return .none }

            if guess < answer {
                self.println("Your guess is too low.")
                self.print("Enter your guess: ")
                return self.getSinglePlayerGameProcessor(answer: answer, tries: tries + 1)
            } else if guess > answer {
                self.println("Your guess is too high.")
                self.print("Enter your guess: ")
                return self.getSinglePlayerGameProcessor(answer: answer, tries: tries + 1)
            } else {
                let guessLiteral = tries == 1 ? "guess." : "guesses."
                self.println("Correct! \(tries) \(guessLiteral)")
                self.print(Self.selectModeMessage)
                self.isSinglePlayerMode = false

                return Processor(closure: self.processModeSelection(_:))
            }
        }
    }

    private func startMultiPlayerGameProcessor(answer: Int) -> Processor {
        return Processor { [weak self] input in
            guard let self = self else { return .none }
            let players = input.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            self.println("I'm thinking of a number between 1 and 100.")
            return self.getMultiPlayerGameProcessor(players, answer: answer, tries: 1)
        }
    }

    private func getMultiPlayerGameProcessor(_ players: [String], answer: Int, tries: Int) -> Processor {
        let player = players[(tries - 1) % players.count]
        self.print("Enter \(player)'s guess: ")

        return Processor { [weak self] input in
            guard let self = self,
                  let guess = Int(input) else { return .none }

            if guess < answer {
                self.println("\(player)'s guess is too low.")
                return self.getMultiPlayerGameProcessor(players, answer: answer, tries: tries + 1)
            } else if guess > answer {
                self.println("\(player)'s guess is too high.")
                return self.getMultiPlayerGameProcessor(players, answer: answer, tries: tries + 1)
            } else {
                self.println("Correct! \(player) wins.")
                self.print(Self.selectModeMessage)

                return Processor(closure: self.processModeSelection(_:))
            }
        }
    }
}

fileprivate final class Processor {
    static let none: Processor = Processor(closure: nil)

    init(closure: ((String) -> Processor)?) {
        self.closure = closure
    }

    private let closure: ((String) -> Processor)?

    func run(input: String) -> Processor {
        return closure?(input) ?? .none
    }

    func callAsFunction(input: String) -> Processor {
        self.run(input: input)
    }
}


