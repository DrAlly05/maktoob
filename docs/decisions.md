# Decisions

One line per decision. Read this file before proposing anything new.
Status is PROPOSED until Dr. Ally Said confirms it, then CONFIRMED with the date. Replaced lines stay in the file, marked REPLACED, so the history is honest.

| Date | Decision | Reason | Status |
|---|---|---|---|
| 2026-05-25 | Project started as "Maktoob", a Swahili reader: Flutter, EPUB upload, translation and voice on the phone | First three commits in the repository | CONFIRMED (in the code) |
| 2026-11-18 | Working name is "Fahamu" | Named the outcome (understanding) | REPLACED 2026-11-18 |
| 2026-11-18 | Name is "Maarifa" | Knowledge as a well anyone can draw from | REPLACED 2026-11-18 by Maktoob |
| 2026-11-18 | Name is "Maktoob" again. Line under it: "Kisima cha maarifa" | The project, the repository and the Firebase project already carry this name. No app with this exact name surfaced on the stores | CONFIRMED 2026-11-19 |
| 2026-11-18 | Store title is "Maktoob: Kisima cha Maarifa" | The name is Arabic. The Swahili line explains the app to a Swahili reader | PROPOSED |
| 2026-11-18 | Android package name and iOS bundle ID are both `com.lunomj.maktoob` | Permanent after first upload. Replaced `com.example.maktoob` on Android and `com.maktoob.app.maktoob` on iOS. Matches `com.lunomj.zerotofive` | CONFIRMED 2026-11-19, done in code |
| 2026-11-19 | Register the Android and iOS apps again in Firebase project `maktoob-app` under `com.lunomj.maktoob` | The Firebase config files still carry the old IDs | PROPOSED |
| 2026-11-18 | Check Yahoo's old MAKTOOB trademark before the first store upload | Yahoo owned a portal of this name until January 2023 and registered the mark in the United States | PROPOSED |
| 2026-11-18 | Move the repository from `DrAlly05/maktoob` to `Luno-MJ-Tech/maktoob` | Same home as the other products. History and commit credit are kept | PROPOSED |
| 2026-11-18 | One version number for Android and iOS, MAJOR.MINOR.PATCH, starting at 1.0.0 | Platforms of one product never drift apart | PROPOSED |
| 2026-11-18 | Bring your own book stays switched off until a lawyer's opinion | Caution about an open legal question | REPLACED 2026-11-18 by the next line |
| 2026-11-18 | Uploading your own book (file or camera scan) is the core feature and is on at launch | Ally's decision. A person holding a book should be able to hear it in their own language | CONFIRMED 2026-11-18 |
| 2026-11-18 | Two quality levels. Papo hapo: translation and voice on the phone, no cost, no internet. Bora: cloud translation and natural voice | The May code already does Papo hapo. It gives every upload a zero cost path, and leaves cloud spend for where quality matters | PROPOSED |
| 2026-11-18 | An uploaded book is visible to its uploader only. Storage is locked per user and tested automatically | Keeps each person's library their own. The open shelf (Kisima) is filled separately | PROPOSED |
| 2026-11-18 | Bora parts are made part by part, when the listener reaches each part | Cost follows real listening instead of whole books nobody finishes | PROPOSED |
| 2026-11-18 | Page photos are read on the phone. Only text leaves the device | No cost per page, less personal data in the cloud | PROPOSED |
| 2026-11-18 | No cloned voice of any real narrator without a signed contract | Voice providers refuse it | PROPOSED |
| 2026-11-18 | The Flutter project stays at the repository root. `pipeline/`, `functions/`, `content/` and `docs/` are added beside `lib/` | Nothing that exists has to move | PROPOSED |
| 2026-11-18 | Source language is detected per book | The May code is fixed to Arabic as the source. Books will arrive in English, Arabic and others | PROPOSED |
| 2026-11-18 | No vector database. Questions are answered from the current chapter plus the book summary | Simpler, cheaper, more accurate for passage questions | PROPOSED |
| 2026-11-18 | Bora voice and translation model are chosen by blind test with a native listener | The product fails if the voice does not sound right | PROPOSED |
| 2026-11-18 | Every Kisima edition is reviewed by a named human. Uploaded books are labelled "Imetafsiriwa na AI" | Honest about what a human has and has not checked | PROPOSED |
| 2026-11-18 | Reading circles show progress only, no chat | Avoids moderation duties in both app stores | PROPOSED |
| 2026-11-18 | About screen carries the founder credit (Dr. Ally Said) with his social and website links | Standing rule for every app | CONFIRMED 2026-11-18 |
| 2026-11-18 | Website and legal pages at maktoob.lunomj.com | Same pattern as zerotofive.lunomj.com | PROPOSED |
| 2026-11-19 | Android build uses Gradle 9.9.1, Android Gradle Plugin 9.3.3 and Kotlin 2.4.20 | Required by the installed Flutter. Same as Zero to Five | CONFIRMED (in the code) |
| 2026-11-19 | Syncfusion PDF viewer and the demo reader screen removed. Home opens the real EPUB reader | Only the demo used them, and the demo loaded a file that did not exist. A PDF reader is still to be chosen | CONFIRMED (in the code) |
| 2026-11-19 | file_picker raised from version 11 to 13 | Version 11 does not compile on the current Android tooling | CONFIRMED (in the code), build passes |
| 2026-11-19 | The reader translates and speaks one paragraph at a time (pieces of at most 1,200 characters), with the original shown above the Swahili | A whole chapter in one piece is too long for the phone's voice. Paragraph steps also give exact resume | PROPOSED until tested on a phone |
| 2026-11-19 | Book language is guessed from the script: Arabic script is Arabic, anything else is treated as English | Enough for the first books. Other Latin script languages (Italian, German, French) need real language detection later | PROPOSED, temporary |
| 2026-11-19 | Language packs may download over mobile data | Many readers have no Wi-Fi | PROPOSED |
