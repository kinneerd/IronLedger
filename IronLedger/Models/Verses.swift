//
//  Verses.swift
//  GymTracker
//
//  Curated Bible verses for rest timer motivation
//

import Foundation

struct BibleVerse: Identifiable {
    let id = UUID()
    let reference: String
    let text: String
}

struct Verses {
    static let motivational: [BibleVerse] = [
        // Strength
        BibleVerse(
            reference: "Philippians 4:13",
            text: "I can do all things through Christ who strengthens me."
        ),
        BibleVerse(
            reference: "Isaiah 40:31",
            text: "Those who hope in the Lord will renew their strength."
        ),
        BibleVerse(
            reference: "Psalm 18:32",
            text: "It is God who arms me with strength and keeps my way secure."
        ),
        BibleVerse(
            reference: "Ephesians 6:10",
            text: "Be strong in the Lord and in his mighty power."
        ),
        BibleVerse(
            reference: "2 Samuel 22:33",
            text: "It is God who arms me with strength and makes my way perfect."
        ),

        // Perseverance
        BibleVerse(
            reference: "Hebrews 12:1",
            text: "Let us run with perseverance the race marked out for us."
        ),
        BibleVerse(
            reference: "James 1:12",
            text: "Blessed is the one who perseveres under trial."
        ),
        BibleVerse(
            reference: "Galatians 6:9",
            text: "Let us not become weary in doing good, for at the proper time we will reap a harvest if we do not give up."
        ),
        BibleVerse(
            reference: "Romans 5:3-4",
            text: "We also glory in our sufferings, because we know that suffering produces perseverance."
        ),
        BibleVerse(
            reference: "1 Corinthians 15:58",
            text: "Stand firm. Let nothing move you. Always give yourselves fully to the work of the Lord."
        ),

        // Discipline
        BibleVerse(
            reference: "1 Corinthians 9:24",
            text: "Run in such a way as to get the prize."
        ),
        BibleVerse(
            reference: "1 Corinthians 9:25",
            text: "Everyone who competes in the games goes into strict training."
        ),
        BibleVerse(
            reference: "1 Timothy 4:8",
            text: "Physical training is of some value, but godliness has value for all things."
        ),
        BibleVerse(
            reference: "Proverbs 12:24",
            text: "Diligent hands will rule, but laziness ends in forced labor."
        ),
        BibleVerse(
            reference: "Colossians 3:23",
            text: "Whatever you do, work at it with all your heart, as working for the Lord."
        ),

        // Endurance
        BibleVerse(
            reference: "2 Timothy 2:3",
            text: "Endure hardship with us like a good soldier of Christ Jesus."
        ),
        BibleVerse(
            reference: "James 1:2-3",
            text: "Consider it pure joy when you face trials, because the testing of your faith produces perseverance."
        ),
        BibleVerse(
            reference: "Romans 8:37",
            text: "In all these things we are more than conquerors through him who loved us."
        ),
        BibleVerse(
            reference: "Hebrews 10:36",
            text: "You need to persevere so that when you have done the will of God, you will receive what he has promised."
        ),
        BibleVerse(
            reference: "Psalm 73:26",
            text: "My flesh and my heart may fail, but God is the strength of my heart and my portion forever."
        ),

        // Victory
        BibleVerse(
            reference: "1 Corinthians 15:57",
            text: "Thanks be to God! He gives us the victory through our Lord Jesus Christ."
        ),
        BibleVerse(
            reference: "Psalm 18:39",
            text: "You armed me with strength for battle; you humbled my adversaries before me."
        ),
        BibleVerse(
            reference: "Philippians 3:14",
            text: "I press on toward the goal to win the prize for which God has called me."
        ),
        BibleVerse(
            reference: "2 Corinthians 4:16",
            text: "Though outwardly we are wasting away, yet inwardly we are being renewed day by day."
        ),
        BibleVerse(
            reference: "Joshua 1:9",
            text: "Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you."
        ),

        // Faith & Trust
        BibleVerse(
            reference: "Proverbs 3:5-6",
            text: "Trust in the Lord with all your heart and lean not on your own understanding."
        ),
        BibleVerse(
            reference: "Psalm 37:5",
            text: "Commit your way to the Lord; trust in him and he will do this."
        ),
        BibleVerse(
            reference: "Isaiah 41:10",
            text: "Do not fear, for I am with you; do not be dismayed, for I am your God."
        ),
        BibleVerse(
            reference: "Psalm 46:1",
            text: "God is our refuge and strength, an ever-present help in trouble."
        ),
        BibleVerse(
            reference: "Nehemiah 8:10",
            text: "The joy of the Lord is your strength."
        )
    ]

    static func random() -> BibleVerse {
        motivational.randomElement() ?? motivational[0]
    }
}
