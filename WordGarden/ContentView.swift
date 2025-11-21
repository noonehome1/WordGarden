//
//  ContentView.swift
//  WordGarden
//
//  Created by Paul Wagstaff on 2025-11-19.
//

import SwiftUI
import AVFAudio

struct ContentView: View {
    // Set based on number of images indicating game progression. Maximum number of missed guesses allowed. refer to as Self.maxNumberOfGuesses
    private static let maxNumberOfGuesses: Int = 8
    private static let maxNumberOfLevelsInstalled = 3
    private static let messageHowManyGuesses: String = "How Many Guesses to Uncover the Hidden Word?"
    
    private static let playAgainButtonLabelGuessALetter: String = "Guess a Letter"
    private static let playAgainButtonLabelAnotherWord: String = "Another Word?"
    private static let playAgainButtonLabelNextLevel: String = "Next Level?"

    // Game Scoring
    @State private var wordsGuessed: Int = 0
    @State private var wordsMissed: Int = 0
    @State private var currentLevel: Int = 0
    @State private var currentGame: Int = 0
    // Level Working Set
    @State private var gameStatusMessage: String = ""
    @State private var wordsToGuess: [String] = []
    @State private var wordToGuess: String = ""
    @State private var lettersGuessed: String = ""
    @State private var guessedLetter: String = ""
    @State private var guessesRemaining: Int = 0
    @State private var currentWordIndex: Int = 0
    @State private var revealedWord: String = ""
    @State private var numberOfGamesAtThisLevel: Int = 0
    // Button Controls
    @State private var playAgainButtonLabel: String = ""
    @State private var playAgainHidden: Bool = true
    // Image Names
    @State private var imageName: String = "flower8"
    // Audio Player
    @State private var audioPlayer: AVAudioPlayer!

    // State Change
    @FocusState private var textFieldIsFocused: Bool

    fileprivate func setClearSlate() {
        (wordsToGuess, numberOfGamesAtThisLevel) = loadWordsFor(level: currentLevel, game: currentGame)
        wordToGuess = wordsToGuess[currentWordIndex]
        gameStatusMessage = Self.messageHowManyGuesses
        revealedWord = "_" + String(repeating: " _", count: wordToGuess.count - 1)
        playAgainButtonLabel = Self.playAgainButtonLabelGuessALetter
        playAgainHidden = true
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Words Guessed: \(wordsGuessed)")
                    Text("Words Missed: \(wordsMissed)")
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Words to Guess: \(wordsToGuess.count - (wordsGuessed+wordsMissed))")
                    Text("Words in Game: \(wordsToGuess.count)")
                }
            }
            .padding(.horizontal)
            Text("Level: \(currentLevel+1)   Game: \(currentGame+1)")

            Spacer()

            Text(gameStatusMessage)
                .font(.title)
                .multilineTextAlignment(.center)
                .frame(height: 80)
                .minimumScaleFactor(0.5)
                .padding()

            Text(revealedWord)
                .font(.title)

            // Normal Play or Completion Processing
            if playAgainHidden {
                HStack {
                    TextField("", text: $guessedLetter)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 30)
                        .overlay {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.gray, lineWidth: 2)
                        }
                        .keyboardType(.asciiCapable)
                        .submitLabel(.done)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.characters)
                        .onChange(of: guessedLetter) {
                            guessedLetter = guessedLetter.trimmingCharacters(in: .letters.inverted)
                            guard let lastChar =  guessedLetter.last else { return }
                            guessedLetter = String(lastChar).uppercased()
                            letterGuess()
                            updateGamePlay()
                        }
                        .focused($textFieldIsFocused)
                        .onSubmit {
                            guard guessedLetter != "" else { return }
                            letterGuess()
                            updateGamePlay()
                        }

                    // Normal Play
                    Button(playAgainButtonLabel) {
                        letterGuess()
                        updateGamePlay()
                    }
                    .buttonStyle(.bordered)
                    .tint(.mint)
                    .disabled(guessedLetter.isEmpty)
                }
            } else {
                // Completion Process
                Button(playAgainButtonLabel) {
//                    if (currentWordIndex < wordsToGuess.count && currentLevel < Self.maxNumberOfLevelsInstalled && currentGame <  numberOfGamesAtThisLevel) {
//                        playAgainButtonLabel = Self.playAgainButtonLabelAnotherWord
//                        print("\nAre We Going to the Next LEVEL? \(currentLevel).\(currentGame)")
//                    }
                    // Reset game for "Play Again?"
                    if (currentWordIndex == wordsToGuess.count) {
                        currentWordIndex = 0
                        wordsGuessed = 0
                        wordsMissed = 0
                        playAgainButtonLabel = "Another Word?"
                     }
                    // Reload the words for the current level/game in case they changed
                    (wordsToGuess, numberOfGamesAtThisLevel) = loadWordsFor(level: currentLevel, game: currentGame)
                    // Reset game after word was guessed or missed (also if "Play Again?")
                    wordToGuess = wordsToGuess[currentWordIndex]
                    revealedWord = "_" + String(repeating: " _", count: wordToGuess.count - 1)
                    lettersGuessed = ""
                    guessesRemaining = Self.maxNumberOfGuesses
                    imageName = "flower\(guessesRemaining)"
                    gameStatusMessage = Self.messageHowManyGuesses
                    playAgainHidden = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
            }

            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: .infinity)
                .animation(.easeIn(duration: 0.75), value: imageName)

            Spacer()
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            setClearSlate()
        }
    }
    
    struct LevelWordList: Decodable {
        let games: [[String]]
    }
    func loadWordsFor(level: Int, game: Int) -> ([String], Int) {
        let fileName = "WordsLevel\(level)"
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let levelData = try? JSONDecoder().decode(LevelWordList.self, from: data) else {
            print("Could not load \(fileName).json")
            return ([], 0)
        }
        // Defensive: if requested game index is out of bounds, return an empty list
        let words = game < levelData.games.count ? levelData.games[game] : []
        return (words, levelData.games.count)
    }

    func letterGuess() {
        textFieldIsFocused = false
        lettersGuessed += guessedLetter
        revealedWord = wordToGuess.map { letter in
            lettersGuessed.contains(letter) ? "\(letter)" : "_" }.joined(separator: " ")
    }

    func updateGamePlay() {
        if !wordToGuess.contains(guessedLetter) {
            guessesRemaining -= 1
            imageName = "wilt\(guessesRemaining)"
            playSound(soundName: "incorrect")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                imageName = "flower\(guessesRemaining)"
            }
        } else {
            playSound(soundName: "correct")
        }
        guessedLetter = ""

        if !revealedWord.contains("_") {
            gameStatusMessage = "You Guessed It!, It took you \(lettersGuessed.count) guess\(lettersGuessed.count == 1 ? "" : "es")"
            wordsGuessed += 1
            currentWordIndex += 1
            playAgainHidden = false
            playSound(soundName: "word-guessed")
        } else if guessesRemaining == 0 {
            gameStatusMessage = "Game Over, You Lost! The word was \(wordToGuess)"
            wordsMissed += 1
            currentWordIndex += 1
            playAgainHidden = false
            playSound(soundName: "word-not-guessed")
        } else {
            gameStatusMessage = "You've made \(lettersGuessed.count) guess\(lettersGuessed.count == 1 ? "" : "es")"
        }
        if (currentWordIndex == wordsToGuess.count) {
            playAgainButtonLabel = "Restart Game?"
            gameStatusMessage += "\nYou've tried all the words! Restart?"
        }
    }

    func playSound(soundName: String) {
        if (audioPlayer != nil && audioPlayer.isPlaying) {
            audioPlayer.stop()
        }
        guard let soundFile = NSDataAsset(name: soundName) else {
            print("😡 Could not read file named \(soundName)")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(data: soundFile.data)
            audioPlayer.play()
        } catch {
            print("😡 ERROR: \(error.localizedDescription) creating audioPlayer")
        }
    }
}

#Preview {
    ContentView()
}
