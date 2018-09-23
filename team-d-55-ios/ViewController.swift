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
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet private weak var destinationAddressTextField: UITextField!
    
    private var wallet: Wallet?  = Wallet()
    
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
        qrCodeImageView.image = wallet?.address.qrImage()
        
        if let balance = wallet?.balance() {
            balanceLabel.text = "Balance : \(balance) satoshi"
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
    
    @IBAction func didTapSendButton(_ sender: UIButton) {
        guard let addressString = destinationAddressTextField.text else {
            return
        }

        do {
            // 送金する
            let address: Address = try AddressFactory.create(addressString)
            
//            try locationHashSend(amount: 1000) { [weak self] (response) in
            try serverLockUntilSend(amount: 1000) { [weak self] (response) in
                print("送金完了 txid : ", response ?? "")
                print("https://www.blocktrail.com/tBCC/tx/\(response ?? "")")
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
        let unsignedTx = try SendUtility.locationHashTransactionBuild(amount: amount, change: (wallet.address, change), utxos: utxosToSpend)
        let signedTx = try SendUtility.locationHashTransactionSign(unsignedTx, with: [wallet.privateKey])

        let rawtx = signedTx.serialized().hex
        BitcoinComTransactionBroadcaster(network: .testnet).post(rawtx, completion: completion)
    }
    
    func serverLockUntilSend(amount: UInt64, completion: ((String?) -> Void)?) throws {
        guard let wallet = wallet else {
            return
        }

        let transactionOutput = TransactionOutput(value: 20000, lockingScript: Data(hex: "a9141d31fa817808cfd658a551a340f7d6a19570a98387")!)
        let txid: Data = Data(hex: "7c7acd5a341f2886d31c80be4da229e1a240cd182f0c22b1cebe8b95f7676966")!
        let txHash: Data = Data(txid.reversed())
        let transactionOutpoint = TransactionOutPoint(hash: txHash, index: 0)
        let utxo = UnspentTransaction(output: transactionOutput, outpoint: transactionOutpoint)

        let utxos = [utxo]
        let (utxosToSpend, fee) = try StandardUtxoSelector().select(from: utxos, targetValue: amount)
        let totalAmount: UInt64 = utxosToSpend.reduce(UInt64()) { $0 + $1.output.value }
        let change: UInt64 = totalAmount - amount - fee

        // ここがカスタム！
        let unsignedTx = try SendUtility.serverLockUntilTransactionBuild(amount: amount, change: (wallet.address, change), utxos: utxosToSpend)
        let signedTx = try SendUtility.serverLockUntilTransactionSign(unsignedTx, with: [MockKey.keyA.privkey])
        
        let rawtx = signedTx.serialized().hex
        BitcoinComTransactionBroadcaster(network: .testnet).post(rawtx, completion: completion)
    }
}

// MARK: - Hello, Bitcoin Script!以降で使用します
func testMockScript() {
    do {
        // ロケーションを使ったP2SH Script
//        print("==========================================================================================")
//        print("ロケーションを使ったP2SH Script")
//        print("==========================================================================================")
//        let result6 = try MockHelper.verifySingleKey(lockScript: LocationHash.lockScript, unlockScriptBuilder: LocationHash.UnlockScriptBuilder(), key: MockKey.keyA, verbose: true)
//        print("Mock result5: \(result6)")

        // Lock Until Script
        print("==========================================================================================")
        print("Lock Until Script")
        print("==========================================================================================")
        let result7 = try MockHelper.verifySingleKey(lockScript: LockUntil.lockScript, unlockScriptBuilder: LockUntil.UnlockScriptBuilder(), key: MockKey.keyA, verbose: true)
        print("Mock result5: \(result7)")
    } catch let error {
        print("Mock Script Error: \(error)")
    }
}
