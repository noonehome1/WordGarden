//
//  ContentView.swift
//  WordGarden
//
//  Created by Paul Wagstaff on 2025-11-19.
//

import SwiftUI
import AVFAudio

struct ContentView: View {
    // Initialize based on number of images indicating progression
    private static let maxNumberOfGuesses: Int = 8 // Need to refer to this variable as self.maxNumberOfGueses
    
    @State private var wordsGuessed: Int = 0
    @State private var wordsMissed: Int = 0
    @State private var currentLevel: Int = 0
    @State private var currentGame: Int = 0
    @State private var wordsToGuess: [String] = []
    @State private var wordArrayLevelGame: [[[String]]] = [[["CAT", "DOG", "PIG", "BAT", "COW"],[ "SHEEP", "LION", "TIGER", "BEAR", "GOAT"]],[["ACCIDENT", "BALANCE", "BRAIN", "CHEER", "CORNER", "DEMOLISH", "ENEMY", "FLAP", "GIFT", "ISLAND", "MOTOR"],["AGREE", "BANNER", "BRANCH", "CHEW", "COUPLE", "DESIGN", "EXACTLY", "FLOAT", "GRAVITY", "LEADER", "NERVOUS"]],[["ABILITY", "AMBITION", "BORDER", "COAST", "DECAY", "DRIFT", "FRAIL", "INDIVIDUAL", "METHOD", "OPPOSITE", "PREDICT"],["ABSORB", "ANCIENT", "BRIEF", "CONFESS", "DEED", "ELEGANT", "GASP", "INTELLIGENT", "MISERY", "ORDEAL", "PREVENT"]]]
    @State private var wordToGuess: String = ""
    @State private var lettersGuessed: String = ""
    @State private var gameStatusMessage: String = "How Many Guesses to Uncover the Hidden Word?"
    @State private var guessedLetter: String = ""
    @State private var guessesRemaining: Int = 8
    @State private var currentWordIndex: Int = 0
    @State private var imageName: String = "flower8"
    @State private var playAgainHidden: Bool = true
    @State private var playAgainButtonLabel: String = "Another Word?"
    @State private var imageNumber: Int = 8
    @State private var revealedWord: String = ""
    @State private var audioPlayer: AVAudioPlayer!
    
    @FocusState private var textFieldIsFocused: Bool
    
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
                            // As long as the guessedLetter is not an empty string continue else return
                            guard guessedLetter != "" else { return }
                            letterGuess()
                            updateGamePlay()
                        }
                    
                    Button("Guess a Letter") {
                        letterGuess()
                        updateGamePlay()
                    }
                    .buttonStyle(.bordered)
                    .tint(.mint)
                    .disabled(guessedLetter.isEmpty)
                }
            } else {
                Button(playAgainButtonLabel) {
                    // Reset game for "Play Again?"
                    if (currentWordIndex == wordsToGuess.count) {
                        currentWordIndex = 0
                        wordsGuessed = 0
                        wordsMissed = 0
                        playAgainButtonLabel = "Another Word?"
                     }
                    // Reset game after word was guessed or missed (also if "Play Again?")
                    wordToGuess = wordsToGuess[currentWordIndex]
                    revealedWord = "_" + String(repeating: " _", count: wordToGuess.count - 1)
                    lettersGuessed = ""
                    guessesRemaining = Self.maxNumberOfGuesses
                    imageName = "flower\(guessesRemaining)"
                    gameStatusMessage = "How Many Guesses to Uncover the Hidden Word?"
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
            wordsToGuess = wordArrayLevelGame[currentLevel][currentGame]
            wordToGuess = wordsToGuess[currentWordIndex]
            revealedWord = "_" + String(repeating: " _", count: wordToGuess.count - 1)
        }
    }
    
    func letterGuess() {
        // Update the list of guessed letters
        textFieldIsFocused = false
        lettersGuessed += guessedLetter
        revealedWord = wordToGuess.map{ letter in
            lettersGuessed.contains(letter) ? "\(letter)" : "_" }.joined(separator: " ")
    }
    
    func updateGamePlay() { // Updates the game with the status of the latest guess
        // Guess a letter, update image based on missed guesses
        if !wordToGuess.contains(guessedLetter) {
            guessesRemaining -= 1
            // Animate the crumbling leaf and play the incorrect guess sound
            imageName = "wilt\(guessesRemaining)"
            playSound(soundName: "incorrect")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                imageName = "flower\(guessesRemaining)"
            }
        } else {
            playSound(soundName: "correct")
        }
        guessedLetter = ""
        
        // When can we play another word?
        if !revealedWord.contains("_") { // Guessed the word correctly if no "_" remain in the work
            gameStatusMessage = "You Guessed It!, It took you \(lettersGuessed.count) guess\(lettersGuessed.count == 1 ? "" : "es")"
            wordsGuessed += 1
            currentWordIndex += 1
            playAgainHidden = false
            playSound(soundName: "word-guessed")
        } else if guessesRemaining == 0 { // Word Missed
            gameStatusMessage = "Game Over, You Lost! The word was \(wordToGuess)"
            wordsMissed += 1
            currentWordIndex += 1
            playAgainHidden = false
            playSound(soundName: "word-not-guessed")
        } else { // Keep Guessing
            //TODO: Redo this with LocalizedStringKey and Inflect
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
