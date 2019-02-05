//
//  MIDIDestination.swift
//  Gong
//
//  Created by Daniel Clelland on 26/04/17.
//  Copyright © 2017 Daniel Clelland. All rights reserved.
//

import Foundation
import CoreMIDI

public class MIDIDestination: MIDIEndpoint {
    
    public convenience init?(named name: String) {
        guard let destination = MIDIDestination.all.first(where: { $0.name == name }) else {
            return nil
        }
        
        self.init(destination.reference)
    }
    
    public static var all: [MIDIDestination] {
        let count = MIDIGetNumberOfDestinations()
        return (0..<count).lazy.map { index in
            return MIDIDestination(MIDIGetDestination(index))
        }
    }
    
}

extension MIDIDestination {
    
    public func flushOutput() throws {
        try MIDIFlushOutput(reference).midiError("Flushing MIDIDestination output")
    }
    
}

extension MIDIDestination {
    
    public typealias SystemExclusiveEventCompletion = () -> Void
    
    // Disclaimer: I'm fairly certain this doesn't work, though I haven't really tested it yet.
    // This function is what I would expect you would use if sending very SysEx messages with more than 256 bytes;
    // otherwise, consider just using `MIDIMessage(bytes:)` instead.
    public func send(systemExclusiveEvent bytes: [UInt8], completion: @escaping SystemExclusiveEventCompletion = {}) throws {
        let completionProcedure: MIDICompletionProc = { _ in }
        
        let data = Data(bytes: bytes)
        var request = data.withUnsafeBytes { pointer in
            return MIDISysexSendRequest(
                destination: reference,
                data: pointer,
                bytesToSend: UInt32(bytes.count),
                complete: false,
                reserved: (0, 0, 0),
                completionProc: completionProcedure,
                completionRefCon: nil
            )
        }
        
        try MIDISendSysex(&request).midiError("Sending system exclusive event")
		while request.complete == false {}
		completion()
    }
    
}
