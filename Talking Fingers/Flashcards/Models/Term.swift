//
//  Term.swift
//  Talking Fingers
//
//  Created by Krish Prasad on 3/2/26.
//

import Foundation

enum TermCategory: String, CaseIterable, Codable, Hashable {
    case alphabet = "alphabet"
    case numbers = "numbers"
    case greetings = "greetings"
    case personalInformation = "personal information"
    case family = "family"
    case verbs = "verbs"
    case dateTime = "date/time"
    case feelingsEmotions = "feelings/emotions"
    case locations = "locations"
    case commonDescriptors = "common descriptors"
    case commonObjects = "common objects"
    
    var displayName: String {
        self.rawValue.capitalized
    }
}

enum Term: String, CaseIterable, Codable {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case e = "E"
    case f = "F"
    case g = "G"
    case h = "H"
    case i = "I"
    case j = "J"
    case k = "K"
    case l = "L"
    case m = "M"
    case n = "N"
    case o = "O"
    case p = "P"
    case q = "Q"
    case r = "R"
    case s = "S"
    case t = "T"
    case u = "U"
    case v = "V"
    case w = "W"
    case x = "X"
    case y = "Y"
    case z = "Z"


    // MARK: - Numbers
    case zero = "0"
    case one = "1"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"
    case ten = "10"
    case fifteen = "15"
    case twenty = "20"
    case hundred = "100"

    // MARK: - Greetings
    case hello = "HELLO"
    case hi = "HI"
    case goodMorning = "GOOD-MORNING"
    case goodAfternoon = "GOOD-AFTERNOON"
    case goodNight = "GOOD-NIGHT"
    case bye = "BYE"
    case seeYouLater = "SEE-YOU-LATER"
    case niceMeetYou = "NICE-MEET-YOU"
    case howYou = "HOW-YOU"
    case whatUp = "WHAT-UP"

    // MARK: - Personal Information
    case name = "NAME"
    case my = "MY"
    case me = "ME"
    case you = "YOU"
    case they = "THEY"
    case we = "WE"
    case he = "HE"
    case she = "SHE"
    case it = "IT"
    case their = "THEIR"
    case our = "OUR"
    case age = "AGE"
    case live = "LIVE"
    case from = "FROM"
    case student = "STUDENT"
    case work = "WORK"
    case like = "LIKE"
    case favorite = "FAVORITE"
    case goNot = "GO-NOT"
    case who = "WHO"
    case what = "WHAT"
    case when = "WHEN"
    case `where` = "WHERE"
    case why = "WHY"
    case how = "HOW"

    // MARK: - Family
    case family = "FAMILY"
    case mother = "MOTHER"
    case father = "FATHER"
    case mom = "MOM"
    case dad = "DAD"
    case sister = "SISTER"
    case brother = "BROTHER"
    case grandmother = "GRANDMOTHER"
    case grandfather = "GRANDFATHER"
    case husband = "HUSBAND"
    case wife = "WIFE"
    case child = "CHILD"

    // MARK: - Verbs
    case go = "GO"
    case come = "COME"
    case want = "WANT"
    case dontLike = "DON’T-LIKE"
    case eat = "EAT"
    case drink = "DRINK"
    case study = "STUDY"
    case finish = "FINISH"
    case help = "HELP"
    case play = "PLAY"
    case watch = "WATCH"
    case learn = "LEARN"
    case teach = "TEACH"
    case visit = "VISIT"
    case talk = "TALK"
    case see = "SEE"
    case make = "MAKE"
    case take = "TAKE"
    case give = "GIVE"
    case get = "GET"
    case know = "KNOW"
    case think = "THINK"
    case feel = "FEEL"
    case say = "SAY"
    case tell = "TELL"

    // MARK: - Date / Time
    case today = "TODAY"
    case tomorrow = "TOMORROW"
    case yesterday = "YESTERDAY"
    case now = "NOW"
    case later = "LATER"
    case morning = "MORNING"
    case afternoon = "AFTERNOON"
    case night = "NIGHT"
    case week = "WEEK"
    case month = "MONTH"
    case year = "YEAR"
    case monday = "MONDAY"
    case friday = "FRIDAY"

    // MARK: - Feelings / Emotions
    case happy = "HAPPY"
    case sad = "SAD"
    case angry = "ANGRY"
    case excited = "EXCITED"
    case tired = "TIRED"
    case bored = "BORED"
    case scared = "SCARED"
    case surprised = "SURPRISED"
    case nervous = "NERVOUS"
    case confused = "CONFUSED"
    case love = "LOVE"
    case frustrated = "FRUSTRATED"

    // MARK: - Locations
    case home = "HOME"
    case school = "SCHOOL"
    case job = "JOB"
    case college = "COLLEGE"
    case `class` = "CLASS"
    case office = "OFFICE"
    case store = "STORE"
    case hospital = "HOSPITAL"
    case restaurant = "RESTAURANT"
    case library = "LIBRARY"
    case park = "PARK"
    
    // MARK: - Common Descriptors
    case good = "GOOD"
    case bad = "BAD"
    case new = "NEW"
    case old = "OLD"
    case big = "BIG"
    case small = "SMALL"
    case together = "TOGETHER"
    case alone = "ALONE"
    case more = "MORE"
    case less = "LESS"
    case same = "SAME"
    case different = "DIFFERENT"

    // MARK: - Common Objects
    case food = "FOOD"
    case water = "WATER"
    case book = "BOOK"
    case phone = "PHONE"
    case computer = "COMPUTER"
    case car = "CAR"
    case house = "HOUSE"
    case dog = "DOG"
    case cat = "CAT"
    case movie = "MOVIE"
    case music = "MUSIC"

    // MARK: - Category Mapping
    var category: TermCategory {
        switch self {

        case .a, .b, .c, .d, .e, .f, .g, .h, .i, .j,
             .k, .l, .m, .n, .o, .p, .q, .r, .s, .t,
             .u, .v, .w, .x, .y, .z:
            return .alphabet


        case .zero, .one, .two, .three, .four,
                .five, .six, .seven, .eight, .nine, .ten, .fifteen, .twenty, .hundred:
            return .numbers

        case .hello, .hi, .goodMorning, .goodAfternoon, .goodNight,
             .bye, .seeYouLater, .niceMeetYou, .howYou, .whatUp:
            return .greetings

        case .name, .my, .me, .you, .they, .we, .he, .she, .it, .their,
             .our, .age, .live, .from, .student, .work, .like, .favorite,
             .goNot, .who, .what, .when, .where, .why, .how:
            return .personalInformation

        case .family, .mother, .father, .mom, .dad, .sister,
             .brother, .grandmother, .grandfather, .husband,
             .wife, .child:
            return .family

        case .go, .come, .want, .dontLike, .eat, .drink,
             .study, .finish, .help, .play, .watch,
             .learn, .teach, .visit, .talk, .see, .make, .take,
             .give, .get, .know, .think, .feel, .say, .tell:
            return .verbs

        case .today, .tomorrow, .yesterday, .now, .later,
             .morning, .afternoon, .night, .week,
             .month, .year, .monday, .friday:
            return .dateTime

        case .happy, .sad, .angry, .excited, .tired,
             .bored, .scared, .surprised, .nervous,
             .confused, .love, .frustrated:
            return .feelingsEmotions

        case .home, .school, .job, .college, .class,
             .office, .store, .hospital, .restaurant,
             .library, .park:
            return .locations
            
        case .good, .bad, .new, .old, .big, .small,
             .together, .alone, .more, .less, .same, .different:
            return .commonDescriptors
            
        case .food, .water, .book, .phone, .computer, .car,
                .house, .dog, .cat, .movie, .music:
            return .commonObjects
        }
    }
    
    static func words(for category: TermCategory) -> [Term] {
        return Self.allCases.filter { $0.category == category }
    }
    
    static func from(_ string: String) -> Term? {
        let normalized = string.uppercased().trimmingCharacters(in: .whitespaces)
        return Term(rawValue: normalized)
    }
    
    static func fromStrings(_ strings: [String]) -> [Term] {
        return strings.compactMap { Term.from($0) }
    }
    
    var displayName: String {
        return self.rawValue
                  .replacingOccurrences(of: "-", with: " ")
                  .capitalized
    }
}
