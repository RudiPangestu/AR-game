import Foundation

/// Maps words that Vision's on-device classifier produces onto archetypes.
///
/// Kept as Swift rather than a bundled JSON file: it is only a few hundred
/// entries, it can never fail to parse at runtime, and the test target does not
/// need any resource wiring to exercise it.
public enum LabelMap {

    /// Vocabulary per archetype. Entries are single words, lowercased.
    public static let vocabulary: [Archetype: [String]] = [
        .aqua: [
            "mug", "cup", "bottle", "glass", "tumbler", "flask", "jug", "kettle",
            "teapot", "faucet", "tap", "sink", "shower", "bathtub", "pool",
            "water", "juice", "aquarium", "watering", "hydrant", "canteen",
            "thermos", "pitcher", "straw", "bucket"
        ],
        .verdant: [
            "plant", "houseplant", "flower", "leaf", "leaves", "tree", "cactus",
            "succulent", "fern", "moss", "grass", "bonsai", "wood", "wooden",
            "log", "branch", "bamboo", "table", "chair", "desk", "shelf",
            "cabinet", "drawer", "stool", "bench", "broom", "seedling"
        ],
        .ember: [
            "candle", "lamp", "light", "lantern", "bulb", "fire", "flame",
            "stove", "oven", "burner", "grill", "toaster", "heater", "match",
            "lighter", "torch", "fireplace", "sun", "sunlight", "iron",
            "hairdryer", "kettle"
        ],
        .ferro: [
            "key", "knife", "fork", "spoon", "scissors", "hammer", "wrench",
            "screwdriver", "nail", "screw", "bolt", "chain", "lock", "padlock",
            "tool", "pliers", "drill", "coin", "can", "tin", "pan", "pot",
            "kettlebell", "dumbbell", "bicycle", "handle", "hinge", "razor",
            "stapler", "clip", "ladder", "pipe"
        ],
        .textil: [
            "shirt", "tshirt", "clothing", "cloth", "fabric", "towel", "sock",
            "sweater", "jacket", "coat", "scarf", "hat", "cap", "glove",
            "pillow", "cushion", "blanket", "curtain", "carpet", "rug", "mat",
            "sofa", "couch", "bed", "mattress", "bag", "backpack", "purse",
            "wallet", "shoe", "sneaker", "sandal", "boot", "slipper", "jeans",
            "trousers", "dress", "hoodie"
        ],
        .glass: [
            "window", "mirror", "jar", "lens", "spectacles", "eyeglasses",
            "goggles", "sunglasses", "screen", "windshield", "vase", "prism",
            "crystal", "ice", "bulb", "aquarium", "picture"
        ],
        .paper: [
            "book", "notebook", "magazine", "newspaper", "paper", "page",
            "envelope", "letter", "card", "poster", "map", "calendar", "box",
            "carton", "cardboard", "package", "receipt", "ticket", "sticker",
            "folder", "menu", "banknote", "money", "diary", "comic", "pen",
            "pencil", "marker", "eraser", "ruler"
        ],
        .fauna: [
            "cat", "dog", "puppy", "kitten", "bird", "fish", "hamster",
            "rabbit", "turtle", "lizard", "person", "face", "hand", "foot",
            "child", "baby", "bear", "teddy", "doll", "plush", "toy", "figurine",
            "statue", "insect", "spider", "butterfly", "chicken", "duck"
        ],
        .snack: [
            "food", "fruit", "apple", "banana", "orange", "grape", "mango",
            "strawberry", "bread", "cake", "cookie", "biscuit", "candy",
            "chocolate", "chips", "crisps", "snack", "noodle", "noodles",
            "rice", "pizza", "burger", "sandwich", "egg", "cheese", "meat",
            "vegetable", "tomato", "onion", "sausage", "donut", "coffee",
            "tea", "milk", "cereal", "popcorn", "sugar", "salt", "sauce"
        ],
        .tech: [
            "phone", "smartphone", "iphone", "laptop", "computer", "keyboard",
            "mouse", "monitor", "television", "tv", "remote", "controller",
            "console", "camera", "headphone", "headphones", "earphone",
            "earbuds", "speaker", "microphone", "cable", "charger", "adapter",
            "battery", "router", "tablet", "printer", "watch", "smartwatch",
            "calculator", "radio", "drone", "usb", "socket", "switch", "clock"
        ],
        .ceramic: [
            "plate", "bowl", "dish", "saucer", "tile", "brick", "ceramic",
            "porcelain", "pottery", "clay", "stone", "rock", "concrete",
            "wall", "floor", "toilet", "basin", "planter", "urn", "ashtray"
        ]
    ]

    /// Flattened word → archetype index.
    ///
    /// Where two archetypes claim the same word, the one earlier in
    /// `Archetype.allCases` keeps it, so the mapping stays deterministic
    /// regardless of dictionary ordering.
    public static let wordIndex: [String: Archetype] = {
        var index: [String: Archetype] = [:]
        for archetype in Archetype.allCases {
            guard let words = vocabulary[archetype] else { continue }
            for word in words where index[word] == nil {
                index[word] = archetype
            }
        }
        return index
    }()
}
