//
//  FlashcardVM.swift
//  Talking Fingers
//
//  Created by Isha Jain on 2/9/26.
//
//
//import Foundation
//import Combine
//
//@Observable
//class FlashcardVM {
//    var flashcards: [FlashcardModel] = []
//    
//    func searchFlashCard(input: String) -> [String] {
//        var results = [String]()
//        for card in flashcards {
//            if card.term.lowercased().contains(input.lowercased()) {
//                results.append(card.term)
//            }
//        }
//        return results
//    }    
//  
//    func filterByCategory(from flashcards: [FlashcardModel], category: String) -> [FlashcardModel] {
//        flashcards.filter { $0.category == category }
//    }    
//  
//    func filterStarred(from flashcards: [FlashcardModel]) -> [FlashcardModel] {
//        flashcards.filter { $0.starred }
//   
//    func returnProgress(flashcards: [FlashcardModel]) -> Float {
//        guard !flashcards.isEmpty else { return 0.0 }
//        var progressTotal: Float = 0.0
//        
//        for flashcard in flashcards {
//            switch flashcard.progress {
//            case .new:
//                progressTotal += 0
//            case .learning:
//                progressTotal += 40
//            case .polishing:
//                progressTotal += 70
//            case .mastered:
//                progressTotal += 100
//            }
//        }
//        return progressTotal / Float(flashcards.count)
//    }
//    
//    func filterByCategory(from flashcards: [FlashcardModel], category: String) -> [FlashcardModel] {
//          flashcards.filter { $0.category == category }
//      }    
//    
//    func filterStarred(from flashcards: [FlashcardModel]) -> [FlashcardModel] {
//          flashcards.filter { $0.starred }
//      }
//}
