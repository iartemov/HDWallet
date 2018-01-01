//
//  MnemonicManager.swift
//  WalletKit
//
//  Created by yuzushioh on 2018/01/01.
//  Copyright © 2018 yuzushioh. All rights reserved.
//

import Foundation
import CryptoSwift

final class MnemonicManager: MnemonicManagerType {
    fileprivate let wordList: WordList
    
    init(wordList: WordList) {
        self.wordList = wordList
    }
    
    func createMnemonic(fromEntropyString entropyString: String) -> String {
        let initialEntropy = entropyString.mnemonicData
        
        let acceptableEntropyLengthList = [16, 20, 24, 28, 32]
        guard acceptableEntropyLengthList.contains(initialEntropy.count) else {
            fatalError("Initial entropy data length should be one of the following: \(acceptableEntropyLengthList). It is \(initialEntropy.count)")
        }
        
        let initialEntropyBits = initialEntropy.toBits
        let checkSumDistance = 0..<(initialEntropyBits.count / 32)
        let checkSum = initialEntropy.sha256().toBits[checkSumDistance]
        
        let entropyBits = initialEntropyBits + checkSum
        let splittingInterval = 11
        guard entropyBits.count % splittingInterval == 0 else {
            fatalError("Entropy data length mush be in a multiple of \(splittingInterval).")
        }
        
        let words = wordList.words
        let estimatedWordCount = entropyBits.count / splittingInterval
        
        var mnemonic: [String] = []
        for index in 0..<estimatedWordCount {
            let startIndex = index * splittingInterval
            let endIndex = startIndex + splittingInterval
            let subArray = entropyBits[startIndex..<endIndex]
            let subString = subArray.joined(separator: "")
            
            let wordIndex = Int(strtoul(subString, nil, 2))
            mnemonic.append(words[wordIndex])
        }
        
        return mnemonic.joined(separator: " ")
    }
    
    func createSeedString(fromMnemonic mnemonic: String, withPassphrase passphrase: String) -> String {
        func normalize(string: String) -> Data? {
            return string.data(using: .utf8, allowLossyConversion: true)
        }
        
        guard let password = normalize(string: mnemonic)?.bytes else {
            fatalError("Nomalizing password failed in \(self)")
        }
        
        guard let salt = normalize(string: "mnemonic" + passphrase)?.bytes else {
            fatalError("Nomalizing salt failed in \(self)")
        }
        
        do {
            let seedData = try PKCS5.PBKDF2(password: password, salt: salt, iterations: 2048, variant: .sha512).calculate()
            return seedData.toHexString()
        } catch let error {
            fatalError("PKCS5.PBKDF2 faild: \(error.localizedDescription)")
        }
    }
}
