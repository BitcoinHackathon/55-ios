//
//  ViewController.swift
//  BitcoinKit-HandsOn
//
//  Created by Akifumi Fujita on 2018/09/20.
//  Copyright © 2018年 Yenom. All rights reserved.
//

import UIKit
import BitcoinKit

class ViewController: UIViewController {
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var lockingScriptHexLabel: UILabel!
    @IBOutlet weak var txidLabel: UILabel!
    
    private var wallet: Wallet?  = Wallet()
    
    var lockingScriptHex : String? = "a91498eb28475bb64283a9fb194a1514d3ae0682235987"
    var txid : String? = "85be95aa2d943a51ee7aa2474deeccc862ab9b5940979c24c908f9eb28ec91b1"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createWalletIfNeeded()
        updateLabels()
        
        testMockScript()
    }
    
    func createWalletIfNeeded() {
        if wallet == nil {
            let privateKey = PrivateKey(network: .testnet)
            wallet = Wallet(privateKey: privateKey)
            wallet?.save()
        }
    }
    
    func updateLabels() {
        print(wallet?.address.cashaddr)
        addressLabel.text = wallet?.address.cashaddr
        
        if let balance = wallet?.balance() {
            balanceLabel.text = "Balance : \(balance) satoshi"
        }
        
        if let hex = self.lockingScriptHex {
            lockingScriptHexLabel.text = "Locking Script Hex: \(hex)"
        }
        
        if let txid = self.txid {
            txidLabel.text = "txid: \(txid)"
        }
    }
    
    func reloadBalance() {
        wallet?.reloadBalance(completion: { [weak self] (utxos) in
            DispatchQueue.main.async {
                self?.updateLabels()
            }
        })
    }
    
    @IBAction func didTapReloadBalanceButton(_ sender: UIButton) {
        reloadBalance()
    }
    
    // Location Hash Transactionを送信する
    @IBAction func didTapSendLocationHashTransactionButton(_ sender: UIButton) {
        do {
            // 送金する
            try locationHashSend(amount: 1000) { [weak self] (response) in
                print("送金完了 txid : ", response ?? "")
                print("https://www.blocktrail.com/tBCC/tx/\(response ?? "")")
                self?.txid = response
                self?.reloadBalance()
            }
        } catch {
            print(error)
        }
    }
    
    func locationHashSend(amount: UInt64, completion: ((String?) -> Void)?) throws {
        guard let wallet = wallet else {
            return
        }
        let utxos = wallet.utxos()
        let (utxosToSpend, fee) = try StandardUtxoSelector().select(from: utxos, targetValue: amount)
        let totalAmount: UInt64 = utxosToSpend.reduce(UInt64()) { $0 + $1.output.value }
        let change: UInt64 = totalAmount - amount - fee
        
        // ここがカスタム！
        let (unsignedTx, scriptHex) = try SendUtility.locationHashTransactionBuild(to: (wallet.address, amount), change: (wallet.address, change), utxos: utxosToSpend)
        print("hex : ", scriptHex)
        self.lockingScriptHex = scriptHex
        let signedTx = try SendUtility.locationHashTransactionSign(unsignedTx, with: [wallet.privateKey])
        
        let rawtx = signedTx.serialized().hex
        BitcoinComTransactionBroadcaster(network: .testnet).post(rawtx, completion: completion)
    }
    
    // server向けにLock Until Scriptを送信する
    @IBAction func didTapSendLockScriptTransactionButton(_ sender: UIButton) {
        do {
            // 送金する
            try serverLockUntilSend(amount: 500) { [weak self] (response) in
                print("送金完了 txid : ", response ?? "")
                print("https://www.blocktrail.com/tBCC/tx/\(response ?? "")")
                self?.reloadBalance()
            }
        } catch {
            print(error)
        }
    }
    
    func serverLockUntilSend(amount: UInt64, completion: ((String?) -> Void)?) throws {
        guard let wallet = wallet else {
            return
        }

        let transactionOutput = TransactionOutput(value: 1000, lockingScript: Data(hex: self.lockingScriptHex!)!)
        let txid: Data = Data(hex: self.txid!)!
        let txHash: Data = Data(txid.reversed())
        let transactionOutpoint = TransactionOutPoint(hash: txHash, index: 0)
        let utxo = UnspentTransaction(output: transactionOutput, outpoint: transactionOutpoint)

        let utxos = [utxo]
        var (utxosToSpend, fee) = try StandardUtxoSelector().select(from: utxos, targetValue: amount)
        fee *= 2
        let totalAmount: UInt64 = utxosToSpend.reduce(UInt64()) { $0 + $1.output.value }
        let change: UInt64 = totalAmount - amount - fee

        // ここがカスタム！
        let unsignedTx = try SendUtility.serverLockUntilTransactionBuild(to: (wallet.address, amount), change: (wallet.address, change), utxos: utxosToSpend)
        let signedTx = try SendUtility.serverLockUntilTransactionSign(unsignedTx, to: wallet.address, with: [wallet.privateKey])
        
        let rawtx = signedTx.serialized().hex
        BitcoinComTransactionBroadcaster(network: .testnet).post(rawtx, completion: completion)
    }
    
    // ユーザが場所に到達した時に位置情報を利用してトランザクションを送信する
    @IBAction func didTapUserSendTransactionButton(_ sender: UIButton) {
        do {
            try userSend(amount: 500) { [weak self] (response) in
                print("送金完了 txid : ", response ?? "")
                print("https://www.blocktrail.com/tBCC/tx/\(response ?? "")")
                self?.reloadBalance()
            }
        } catch {
            print(error)
        }

    }
    
    func userSend(amount: UInt64, completion: ((String?) -> Void)?) throws {
        guard let wallet = wallet else {
            return
        }
        
        let transactionOutput = TransactionOutput(value: 1000, lockingScript: Data(hex: self.lockingScriptHex!)!)
        let txid: Data = Data(hex: self.txid!)!
        let txHash: Data = Data(txid.reversed())
        let transactionOutpoint = TransactionOutPoint(hash: txHash, index: 0)
        let utxo = UnspentTransaction(output: transactionOutput, outpoint: transactionOutpoint)
        
        let utxos = [utxo]
        var (utxosToSpend, fee) = try StandardUtxoSelector().select(from: utxos, targetValue: amount)
        fee *= 2
        let totalAmount: UInt64 = utxosToSpend.reduce(UInt64()) { $0 + $1.output.value }
        let change: UInt64 = totalAmount - amount - fee
        
        let toAddress: Address = try AddressFactory.create("bchtest:qpytf7xczxf2mxa3gd6s30rthpts0tmtgyw8ud2sy3")
        
        // ここがカスタム！
        let unsignedTx = try SendUtility.userTransactionBuild(to: (toAddress, amount), change: (wallet.address, change), utxos: utxosToSpend)
        let signedTx = try SendUtility.userTransactionSign(unsignedTx, to: wallet.address, with: [wallet.privateKey])
        
        let rawtx = signedTx.serialized().hex
        BitcoinComTransactionBroadcaster(network: .testnet).post(rawtx, completion: completion)
    }
    
}

// MARK: - Hello, Bitcoin Script!以降で使用します
func testMockScript() {
    do {
        // ロケーションを使ったP2SH Script
        print("==========================================================================================")
        print("ロケーションを使ったP2SH Script")
        print("==========================================================================================")
        let result6 = try MockHelper.verifySingleKey(lockScript: LocationHash.lockScript, unlockScriptBuilder: LocationHash.UnlockScriptBuilder(), key: MockKey.keyA, verbose: true)
        print("Mock result5: \(result6)")

        // Lock Until Script
//        print("==========================================================================================")
//        print("Lock Until Script")
//        print("==========================================================================================")
//        let result7 = try MockHelper.verifySingleKey(lockScript: LockUntil.lockScript, unlockScriptBuilder: LockUntil.UnlockScriptBuilder(), key: MockKey.keyA, verbose: true)
//        print("Mock result5: \(result7)")
    } catch let error {
        print("Mock Script Error: \(error)")
    }
}
