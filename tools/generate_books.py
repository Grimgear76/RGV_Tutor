import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BOOKS_PATH = ROOT / "assets" / "books.json"


def slugify(value: str) -> str:
    value = value.lower()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    return value.strip("-")


def mk(title: str, author: str, gid: int) -> dict:
    return {
        "id": f"gutenberg-{slugify(title)}-{gid}",
        "title": title,
        "author": author,
        "format": "epub",
        "remoteUrl": f"https://www.gutenberg.org/ebooks/{gid}.epub.noimages",
        "coverUrl": f"https://www.gutenberg.org/cache/epub/{gid}/pg{gid}.cover.medium.jpg",
        "source": "gutenberg",
    }


NEW_BOOKS = [
    mk("A Doll's House", "Henrik Ibsen", 2542),
    mk("A Journey to the Center of the Earth", "Jules Verne", 18857),
    mk("A Modest Proposal", "Jonathan Swift", 1080),
    mk("A Midsummer Night's Dream", "William Shakespeare", 1514),
    mk("A Room with a View", "E. M. Forster", 2641),
    mk("A Study in Scarlet", "Arthur Conan Doyle", 244),
    mk("Aesop's Fables", "Aesop", 21),
    mk("After London; Or, Wild England", "Richard Jefferies", 13944),
    mk("Agnes Grey", "Anne Brontë", 767),
    mk("Anna Karenina", "Leo Tolstoy", 1399),
    mk("Anthem", "Ayn Rand", 1250),
    mk("Around the World in Eighty Days", "Jules Verne", 103),
    mk("Autobiography of Benjamin Franklin", "Benjamin Franklin", 20203),
    mk("Bartleby, the Scrivener", "Herman Melville", 11231),
    mk("Beowulf", "Anonymous", 16328),
    mk("Beyond Good and Evil", "Friedrich Nietzsche", 4363),
    mk("Candide", "Voltaire", 19942),
    mk("Carmilla", "J. Sheridan Le Fanu", 10007),
    mk("Common Sense", "Thomas Paine", 147),
    mk("Crime and Punishment", "Fyodor Dostoyevsky", 2554),
    mk("David Copperfield", "Charles Dickens", 766),
    mk("De Profundis", "Oscar Wilde", 921),
    mk("Demian", "Hermann Hesse", 5200),
    mk("Dr. Syn", "Russell Thorndike", 24854),
    mk("Dracula's Guest", "Bram Stoker", 10150),
    mk("Don Quixote", "Miguel de Cervantes Saavedra", 996),
    mk("Dubliners", "James Joyce", 2814),
    mk("Erewhon; Or, Over the Range", "Samuel Butler", 1906),
    mk("Ethan Frome", "Edith Wharton", 4517),
    mk("Eugene Onegin", "Alexander Pushkin", 23997),
    mk("Far from the Madding Crowd", "Thomas Hardy", 107),
    mk("Gulliver's Travels", "Jonathan Swift", 829),
    mk("Heart of Darkness", "Joseph Conrad", 219),
    mk("Hedda Gabler", "Henrik Ibsen", 4093),
    mk("Herland", "Charlotte Perkins Gilman", 32),
    mk("Iliad", "Homer", 6130),
    mk("Incidents in the Life of a Slave Girl", "Harriet A. Jacobs", 11030),
    mk("Kidnapped", "Robert Louis Stevenson", 421),
    mk("Kim", "Rudyard Kipling", 2226),
    mk("Leaves of Grass", "Walt Whitman", 1322),
    mk("Les Misérables", "Victor Hugo", 135),
    mk("Leviathan", "Thomas Hobbes", 3207),
    mk("Little Lord Fauntleroy", "Frances Hodgson Burnett", 479),
    mk("Madame Bovary", "Gustave Flaubert", 2413),
    mk("Meditations", "Marcus Aurelius", 2680),
    mk("Metamorphoses", "Ovid", 21765),
    mk("Narrative of the Life of Frederick Douglass", "Frederick Douglass", 23),
    mk("Notes from the Underground", "Fyodor Dostoyevsky", 600),
    mk("O Pioneers!", "Willa Cather", 24),
    mk("On the Origin of Species", "Charles Darwin", 2009),
    mk("Paradise Lost", "John Milton", 26),
    mk("Peter Pan", "J. M. Barrie", 16),
    mk("Phantom of the Opera", "Gaston Leroux", 175),
    mk("Pinocchio", "Carlo Collodi", 500),
    mk("Pygmalion", "George Bernard Shaw", 3825),
    mk("Rebecca of Sunnybrook Farm", "Kate Douglas Wiggin", 498),
    mk("Red Badge of Courage", "Stephen Crane", 73),
    mk("Sense and Sensibility", "Jane Austen", 161),
    mk("Siddhartha", "Hermann Hesse", 2500),
    mk("Silas Marner", "George Eliot", 550),
    mk("Sister Carrie", "Theodore Dreiser", 233),
    mk("Swiss Family Robinson", "Johann David Wyss", 11703),
    mk("Tarzan of the Apes", "Edgar Rice Burroughs", 78),
    mk("The Aeneid", "Virgil", 228),
    mk("The Age of Innocence", "Edith Wharton", 541),
    mk("The Art of War", "Sun Tzu", 132),
    mk("The Awakening", "Kate Chopin", 160),
    mk("The Brothers Karamazov", "Fyodor Dostoyevsky", 28054),
    mk("The Call of the Wild", "Jack London", 215),
    mk("The Canterbury Tales", "Geoffrey Chaucer", 2383),
    mk("The Communist Manifesto", "Karl Marx, Friedrich Engels", 61),
    mk("The Federalist Papers", "Alexander Hamilton, James Madison, John Jay", 1404),
    mk("The Great God Pan", "Arthur Machen", 389),
    mk("The Hound of the Baskervilles", "Arthur Conan Doyle", 2852),
    mk("The Hunchback of Notre-Dame", "Victor Hugo", 2610),
    mk("The Jungle Book", "Rudyard Kipling", 236),
    mk("The Last of the Mohicans", "James Fenimore Cooper", 940),
    mk("The Legend of Sleepy Hollow", "Washington Irving", 41),
    mk("The Lost World", "Arthur Conan Doyle", 139),
    mk("The Mysterious Affair at Styles", "Agatha Christie", 863),
    mk("The Republic", "Plato", 1497),
    mk("The Secret Garden", "Frances Hodgson Burnett", 113),
    mk("The Turn of the Screw", "Henry James", 209),
    mk("The Woman in White", "Wilkie Collins", 583),
    mk("The Yellow Wallpaper", "Charlotte Perkins Gilman", 1952),
    mk("Through the Looking-Glass", "Lewis Carroll", 12),
    mk("Three Men in a Boat", "Jerome K. Jerome", 308),
    mk("Twenty Thousand Leagues Under the Seas", "Jules Verne", 164),
    mk("Uncle Tom's Cabin", "Harriet Beecher Stowe", 203),
    mk("Walden", "Henry David Thoreau", 205),
    mk("War and Peace", "Leo Tolstoy", 2600),
    mk("White Fang", "Jack London", 910),
    mk("Works of Edgar Allan Poe — Volume 1", "Edgar Allan Poe", 2147),
]


def main() -> None:
    books = json.loads(BOOKS_PATH.read_text(encoding="utf-8"))

    existing_ids = {b.get("id") for b in books}
    existing_key = {(b.get("title", "").strip(), b.get("author", "").strip()) for b in books}

    filtered = []
    for book in NEW_BOOKS:
        if book["id"] in existing_ids:
            continue
        key = (book["title"].strip(), book["author"].strip())
        if key in existing_key:
            continue
        filtered.append(book)
        existing_ids.add(book["id"])
        existing_key.add(key)

    merged = books + filtered
    merged.sort(key=lambda b: b.get("title", "").casefold())

    BOOKS_PATH.write_text(json.dumps(merged, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{len(books)} -> {len(merged)}")


if __name__ == "__main__":
    main()
