//
//  MockScripts.swift
//  BitcoinKit-HandsOn
//
//  Created by Akifumi Fujita on 2018/09/20.
//  Copyright © 2018年 Yenom. All rights reserved.
//

import Foundation
import BitcoinKit

struct LocationHash {
    // lock script
    static let lockLocationScript = try! Script()
        // TODO: ロケーションデータを入れる
        .appendData(String(12345).data(using: String.Encoding.utf8)!)
        .append(.OP_EQUAL)
    
    static let lockScript = try! Script()
        .append(.OP_IF)
            .append(.OP_DUP)
            .append(.OP_HASH160)
            .appendData(MockKey.keyA.pubkeyHash)
            .append(.OP_EQUALVERIFY)
            .append(.OP_CHECKSIG)
        .append(.OP_ELSE)
            .append(.OP_HASH160)
            .appendData(Crypto.sha256ripemd160(lockLocationScript.data))
            .append(.OP_EQUAL)
        .append(.OP_ENDIF)
    
    // unlock script builder
    struct UnlockScriptBuilder: MockUnlockScriptBuilder {
        func build(pairs: [SigKeyPair]) -> Script {
            guard let sigKeyPair = pairs.first else {
                return Script()
            }

            // ロケーションデータでアンロックする場合はこちらを使う
//            let script = try! Script()
//                .append(.OP_0)
//                // TODO: ロケーションデータを入れる
//                .appendData(String(12345).data(using: String.Encoding.utf8)!)
//                .appendData(lockLocationScript.data)
//                .append(.OP_FALSE)
            // 秘密鍵でアンロックする場合はこちらを使う
            let script = try! Script()
                .appendData(sigKeyPair.signature)
                .appendData(sigKeyPair.key.data)
                .append(.OP_TRUE)

            return script
        }
    }
}

struct LockUntil {
    static let lockScript = try! Script()
        .appendData(SendUtility.string2ExpiryTime(dateString: "2018-09-21 14:45:00"))
        .append(.OP_CHECKLOCKTIMEVERIFY)
        .append(.OP_DROP)
        .append(.OP_DUP)
        .append(.OP_HASH160)
        .appendData(MockKey.keyA.pubkeyHash)
        .append(.OP_EQUALVERIFY)
        .append(.OP_CHECKSIG)
    
    // unlock script builder
    struct UnlockScriptBuilder: MockUnlockScriptBuilder {
        func build(pairs: [SigKeyPair]) -> Script {
            guard let sigKeyPair = pairs.first else {
                return Script()
            }
            
            let script = try! Script()
                .appendData(sigKeyPair.signature)
                .appendData(sigKeyPair.key.data)
            return script
        }
    }
}
