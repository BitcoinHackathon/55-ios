//
//  SendUtility.swift
//  BitcoinKit-HandsOn
//
//  Created by Akifumi Fujita on 2018/09/20.
//  Copyright © 2018年 Yenom. All rights reserved.
//

import Foundation
import BitcoinKit

class SendUtility {
    
    static func locationHashTransactionBuild(to: (address: Address, amount: UInt64), change: (address: Address, amount: UInt64), utxos: [UnspentTransaction]) throws -> (UnsignedTransaction, String) {
        let lockLocationScript = try! Script()
            .appendData(LocationData.destinationLocation.data(using: String.Encoding.utf8)!)
            .append(.OP_EQUAL)
        
        let locationHashScript = try! Script()
            .append(.OP_IF)
                .append(.OP_DUP)
                .append(.OP_HASH160)
                .appendData(to.address.data)
                .append(.OP_EQUALVERIFY)
                .append(.OP_CHECKSIG)
            .append(.OP_ELSE)
                .append(.OP_HASH160)
                .appendData(Crypto.sha256ripemd160(lockLocationScript.data))
                .append(.OP_EQUAL)
            .append(.OP_ENDIF)
            .toP2SH()
        
//        let addr = locationHashScriptTo.standardAddress(network: .testnet)

        let locationHashScriptChange = Script(address: change.address)!
        
        let toOutput = TransactionOutput(value: to.amount, lockingScript: locationHashScript.data)
        let changeOutput = TransactionOutput(value: change.amount, lockingScript: locationHashScriptChange.data)
        
        let outputs = [toOutput, changeOutput]
        
        let unsignedInputs = utxos.map { TransactionInput(previousOutput: $0.outpoint, signatureScript: Data(), sequence: UInt32.max) }
        let tx = Transaction(version: 1, inputs: unsignedInputs, outputs: outputs, lockTime: 0)
        return (UnsignedTransaction(tx: tx, utxos: utxos), locationHashScript.hex)
    }
    
    static func locationHashTransactionSign(_ unsignedTransaction: UnsignedTransaction, with keys: [PrivateKey]) throws -> Transaction {
        // Define Transaction
        var signingInputs: [TransactionInput]
        var signingTransaction: Transaction {
            let tx: Transaction = unsignedTransaction.tx
            return Transaction(version: tx.version, inputs: signingInputs, outputs: tx.outputs, lockTime: tx.lockTime)
        }
        
        // Sign
        signingInputs = unsignedTransaction.tx.inputs
        let hashType = SighashType.BCH.ALL
        for (i, utxo) in unsignedTransaction.utxos.enumerated() {
            // Select key
            let pubkeyHash: Data = Script.getPublicKeyHash(from: utxo.output.lockingScript)
            
            let keysOfUtxo: [PrivateKey] = keys.filter { $0.publicKey().pubkeyHash == pubkeyHash }
            guard let key = keysOfUtxo.first else {
                continue
            }
            
            // Sign transaction hash
            let sighash: Data = signingTransaction.signatureHash(for: utxo.output, inputIndex: i, hashType: SighashType.BCH.ALL)
            let signature: Data = try Crypto.sign(sighash, privateKey: key)
            let txin = signingInputs[i]
            let pubkey = key.publicKey()
            
            // Create Signature Script
            let sigWithHashType: Data = signature + UInt8(hashType)
            let unlockingScript: Script = try Script()
                .appendData(sigWithHashType)
                .appendData(pubkey.data)
            
            // Update TransactionInput
            signingInputs[i] = TransactionInput(previousOutput: txin.previousOutput, signatureScript: unlockingScript.data, sequence: txin.sequence)
        }
        return signingTransaction
    }
    
    static func serverLockUntilTransactionBuild(to: (address: Address, amount: UInt64), change: (address: Address, amount: UInt64), utxos: [UnspentTransaction]) throws -> UnsignedTransaction {
        
        let locationHashScriptTo = try! Script()
            .appendData(SendUtility.string2ExpiryTime(dateString: "2018-09-25 14:45:00"))
            .append(.OP_CHECKLOCKTIMEVERIFY)
            .append(.OP_DROP)
            .append(.OP_DUP)
            .append(.OP_HASH160)
            .appendData(to.address.data)
            .append(.OP_EQUALVERIFY)
            .append(.OP_CHECKSIG)
            .toP2SH()

        let locationHashScriptChange = Script(address: change.address)!
        
        let toOutput = TransactionOutput(value: to.amount, lockingScript: locationHashScriptTo.data)
        let changeOutput = TransactionOutput(value: change.amount, lockingScript: locationHashScriptChange.data)
        
        let outputs = [toOutput, changeOutput]
        
        let unsignedInputs = utxos.map { TransactionInput(previousOutput: $0.outpoint, signatureScript: Data(), sequence: 0) }
        let tx = Transaction(version: 1, inputs: unsignedInputs, outputs: outputs, lockTime: 0)
        return UnsignedTransaction(tx: tx, utxos: utxos)
    }
    
    static func serverLockUntilTransactionSign(_ unsignedTransaction: UnsignedTransaction, to address: Address, with keys: [PrivateKey]) throws -> Transaction {
        // Define Transaction
        var signingInputs: [TransactionInput]
        var signingTransaction: Transaction {
            let tx: Transaction = unsignedTransaction.tx
            return Transaction(version: tx.version, inputs: signingInputs, outputs: tx.outputs, lockTime: tx.lockTime)
        }
        
        // Sign
        signingInputs = unsignedTransaction.tx.inputs
        let hashType = SighashType.BCH.ALL
        for (i, utxo) in unsignedTransaction.utxos.enumerated() {
            // Select key
            let pubkeyHash: Data = (keys.first?.publicKey().pubkeyHash)!
            
            let keysOfUtxo: [PrivateKey] = keys.filter { $0.publicKey().pubkeyHash == pubkeyHash }
            guard let key = keysOfUtxo.first else {
                continue
            }
            
            let lockLocationScript = try! Script()
                .appendData(LocationData.destinationLocation.data(using: String.Encoding.utf8)!)
                .append(.OP_EQUAL)
            
            let locationHashScript = try! Script()
                .append(.OP_IF)
                .append(.OP_DUP)
                .append(.OP_HASH160)
                .appendData(address.data)
                .append(.OP_EQUALVERIFY)
                .append(.OP_CHECKSIG)
                .append(.OP_ELSE)
                .append(.OP_HASH160)
                .appendData(Crypto.sha256ripemd160(lockLocationScript.data))
                .append(.OP_EQUAL)
                .append(.OP_ENDIF)
            
            let output = TransactionOutput(value: utxo.output.value, lockingScript: locationHashScript.data)
            
            // Sign transaction hash
            let sighash: Data = signingTransaction.signatureHash(for: output, inputIndex: i, hashType: SighashType.BCH.ALL)
            let signature: Data = try Crypto.sign(sighash, privateKey: key)
            let txin = signingInputs[i]
            let pubkey = key.publicKey()
            
            // Create Signature Script
            let sigWithHashType: Data = signature + UInt8(hashType)

            let unlockingScript: Script = try Script()
                .appendData(sigWithHashType)
                .appendData(pubkey.data)
                .append(.OP_TRUE)
                .appendData(locationHashScript.data)

            // Update TransactionInput
            signingInputs[i] = TransactionInput(previousOutput: txin.previousOutput, signatureScript: unlockingScript.data, sequence: txin.sequence)
        }
        return signingTransaction
    }
    
    static func userTransactionBuild(to: (address: Address, amount: UInt64), change: (address: Address, amount: UInt64), utxos: [UnspentTransaction]) throws -> UnsignedTransaction {
        
        let locationHashScriptTo = try! Script()
            .append(.OP_DUP)
            .append(.OP_HASH160)
            .appendData(to.address.data)
            .append(.OP_EQUALVERIFY)
            .append(.OP_CHECKSIG)
        
        let lockScriptChange = Script(address: change.address)!

        let toOutput = TransactionOutput(value: to.amount, lockingScript: locationHashScriptTo.data)
        let changeOutput = TransactionOutput(value: change.amount, lockingScript: lockScriptChange.data)
        
        let outputs = [toOutput, changeOutput]
        
        let unsignedInputs = utxos.map { TransactionInput(previousOutput: $0.outpoint, signatureScript: Data(), sequence: UInt32.max) }
        let tx = Transaction(version: 1, inputs: unsignedInputs, outputs: outputs, lockTime: 0)
        return UnsignedTransaction(tx: tx, utxos: utxos)
    }
    
    static func userTransactionSign(_ unsignedTransaction: UnsignedTransaction, to address: Address, with keys: [PrivateKey], locationString: String) throws -> Transaction {
        // Define Transaction
        var signingInputs: [TransactionInput]
        var signingTransaction: Transaction {
            let tx: Transaction = unsignedTransaction.tx
            return Transaction(version: tx.version, inputs: signingInputs, outputs: tx.outputs, lockTime: tx.lockTime)
        }
        
        // Sign
        signingInputs = unsignedTransaction.tx.inputs
        for (i, _) in unsignedTransaction.utxos.enumerated() {
            let lockLocationScript = try! Script()
                .appendData(locationString.data(using: String.Encoding.utf8)!)
                .append(.OP_EQUAL)
            
            let locationHashScript = try! Script()
                .append(.OP_IF)
                .append(.OP_DUP)
                .append(.OP_HASH160)
                .appendData(address.data)
                .append(.OP_EQUALVERIFY)
                .append(.OP_CHECKSIG)
                .append(.OP_ELSE)
                .append(.OP_HASH160)
                .appendData(Crypto.sha256ripemd160(lockLocationScript.data))
                .append(.OP_EQUAL)
                .append(.OP_ENDIF)            
            
            let txin = signingInputs[i]
            
            let unlockingScript: Script = try Script()
                .appendData(lockLocationScript.data)
                .append(.OP_FALSE)
                .appendData(locationHashScript.data)

            // Update TransactionInput
            signingInputs[i] = TransactionInput(previousOutput: txin.previousOutput, signatureScript: unlockingScript.data, sequence: txin.sequence)
        }
        return signingTransaction
    }
    
    static func string2ExpiryTime(dateString: String) -> Data {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let date = formatter.date(from: dateString)!
        let dateUnix: TimeInterval = date.timeIntervalSince1970
        return Data(from: Int32(dateUnix).littleEndian)
    }    
}
