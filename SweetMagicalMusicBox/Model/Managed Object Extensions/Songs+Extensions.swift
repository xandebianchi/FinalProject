//
//  Songs+Extensions.swift
//  SweetMagicalMusicBox
//
//  Created by Alexandre Bianchi on 10/03/21.
//

import CoreData

extension Song {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
