# Heijōshin — zweryfikowane podstawy artykułu PL/EN

Karta: `t_8ac13e1c`. Opracowanie: 2026-10-12. Zakres użytkownika: **gotowy, otwarty PR; bez merge, deployu i Actions**.

Teksty docelowe: `templates/blog/heijoshin.html.erb` i `heijoshin_en.html.erb`. Ta nota zastępuje podstawy lokalnego draftu `wt/t_74cd1f1e` dla tego PR. Nie zmieniono oryginalnego worktree. Nie utrzymujemy drugiej, rozbieżnej kopii tekstu publikacyjnego.

## Argument i forma

Zwykłe nawyki pracy mogą być punktem powrotu w ważnym dniu. Heijōshin nie usuwa tremy, nie zastępuje przygotowania i nie oznacza niewrażliwości na zmianę warunków. Powrót do zadania po błędzie jest konkretnym dydaktycznym celem; pozory spokoju nie są oceną charakteru.

Forma: sytuacja pomyłki na egzaminie i usłyszenia kolejnego polecenia, kontekst leksykalny/koan, powrót do tej sytuacji, przygotowania w zwykłym treningu. PL i EN dzielą tezę i przykłady, nie muszą dzielić szyku zdań. Inspiracja zen oddzielona od technicznego aikido.

PL: „Heijōshin (平常心) — zwykły umysł w dniu próby”. EN: „Heijōshin (平常心) — an ordinary mind under pressure”.
- `/blog/heijoshin-zwykly-umysl-w-dniu-proby.html`
- `/en/blog/heijoshin-an-ordinary-mind-under-pressure.html`
- Data w kandydacie: 2026-10-12 (przygotowanie; do aktualizacji przed późniejszą publikacją).
- Kategoria `:practice`.

Samodzielny PR na `origin/master=0046cdfa9717828d66b7ce8dfa121b57c51a7693`. Nie zawiera linku do nieopublikowanego Yutori. Nie wymaga merge innego PR. Istniejące Kakugo i Awase pozostają bez zmian.

## Źródła leksykalne

1. https://kotobank.jp/word/%E5%B9%B3%E5%B8%B8%E5%BF%83-624095
   - **Digital Daijisen (Shōgakukan):** `ふだんと変わらない心。揺れ動くことのない心理状態。` — zwykły, niezmieniony umysł, stan nieulegający rozchwianiu.
   - **Seisenban Nihon Kokugo Daijiten:** odczyt `びょうじょうしん`, znaczenie buddyjskie: `日常ふつうの心。ふだんの気持。あたりまえの生き方。`; wskazuje Dōgena i *Mumonkan* 19. Dla `へいじょうしん`: codzienny spokojny umysł. Nie twierdzimy, że oba odczytania są obowiązkowymi częściami jednego stanu.
2. https://jisho.org/search/%E5%B9%B3%E5%B8%B8%E5%BF%83
   - API: https://jisho.org/api/v1/search/words?keyword=%E5%B9%B3%E5%B8%B8%E5%BF%83
   - Wpis `平常心`, `へいじょうしん`: self-possession; presence of mind.
   - Wpis `平常心-1`, `びょうじょうしん`: everyday feelings; usual feelings.
   - JMdict. Artykuł unika wyprowadzania teorii z izolowanych odczytań znaków (`hira`, `tsune`, `kokoro` nie są romanizacją całego wyrazu).

## Tekst pierwotny w wskazanym przekładzie: Mumonkan, przypadek 19

Strona wydawcy: https://www.bdkamerica.org/product/three-chan-classics/

Jej link DOWNLOAD prowadzi do https://bdkamerica.org/download/1862 — pobrano PDF i sprawdzono strony tytułowe, copyright, autora przekładu oraz cały przypadek 19 z komentarzem i wierszem.

**Ważna rozbieżność bibliograficzna:** strona produktu podaje 1995, ale rzeczywiście udostępniony PDF ma tytułową datę i copyright **1999**, „First Printing, 1999”, oraz okładkę „dBET Alpha PDF Version © 2017”. Artykuł cytuje wydanie w pobranym pliku, a nie zgaduje daty z katalogu.

*Three Chan Classics*, Numata Center for Buddhist Translation and Research, ISBN 1-886439-07-9. Sekcja *Wumen’s Gate* jest przekładem **J. C. Cleary’ego** (nie tłumaczeniem Osamu Yoshidy, który odpowiada za inny tekst w tym tomie).

**Przypadek 19, drukowane s. 85–86:** Zhaozhou pyta **Nanquana**, nie Mazu. Dokładne zdanie odpowiedzi:

> The ordinary mind is the Path.

PL oznacza własny przekład z angielskiego: „Zwykły umysł jest Drogą”. Nie przypisujemy sobie przekładu z chińskiego. Dalszy dialog mówi o dążeniu i poznaniu; niewiedza nie jest przedstawiona jako odpowiedź. Komentarz Wumena dodaje trzydzieści dalszych lat studiów Zhaozhou nawet po przebudzeniu. Podajemy to jako treść komentarza, nie niezależnie potwierdzony fakt biograficzny.

Tekst pochodzi z tradycji chan, a jego pytanie dotyczy Drogi/przebudzenia, nie sukcesu egzaminacyjnego. Nie wykazaliśmy historycznego przekazu „Mazu → Takuan → aikido”, dlatego artykuł nie tworzy takiego łańcucha ani nie przypisuje Takuanowi obecnej metody ćwiczeń.

## Opracowanie filozoficzne

https://plato.stanford.edu/entries/buddhism-chan/ — **Peter D. Hershock, Chan Buddhism**, Stanford Encyclopedia of Philosophy, publikacja 2015, rewizja 2019.

Część **4. Truth and the Nature of Knowledge and Language in Chan**: wypowiedzi chan jako odpowiedź na sytuacyjne potrzeby, nie zawsze ostateczne i uniwersalne twierdzenia. Przykład Mazu pokazuje zmianę odpowiedzi w zależności od pytającego. To podstawa ograniczenia interpretacji koanu, nie dowód psychologicznej skuteczności szkolenia.

Nie twierdzimy, że sam spokój lub codzienność jest wystarczającym warunkiem przebudzenia. Nie przypisujemy autorowi współczesnego podręcznika jedynej poprawnej wykładni zen.

## Standard praktyki POA i zmiany wobec draftu

- Egzamin: przygotowanie materiału, ukemi, korekty, partner, uzgodnienie gotowości z nauczycielem (`egzamin_w_budo.html.erb`). Spokój nie gwarantuje zaliczenia.
- Uke/nage: forma i intensywność dobrane do obu osób, obserwacja przez całe ćwiczenie, prawo do zwolnienia i przerwania. Publiczność nie uzasadnia zwiększania siły.
- Usunięto „tryb jest zawsze maską”, „tylko maska przeszkadza”, diagnozę charakteru po oddechu/ukłonie oraz obietnicę „zwykłe zawsze wystarcza”.
- Nie przedstawiamy heijōshin jako wyższego stopnia fudōshin. Porównania pojęć są jawnie dydaktyczne, nakładające się, nie wyłączne.
- Krótkie pokazanie zadania przed grupą i zmiana poleceń są propozycją do uzgodnienia z nauczycielem, nie wykazaną metodą leczenia lęku ani zgodą na nieuzgodnione ataki.
- Przykłady egzaminu/prezentacji są ilustracjami autora. Notatki, próba i wsparcie nie są „maską”. Hasło filozoficzne nie zastępuje odpowiedniej pomocy przy utrwalonym lęku.

## Gate PR

Pełny SEO snapshot: dwa nowe adresy artykułu oraz automatycznie dodana szósta strona indeksu PL/EN, wszystkie dotychczasowe wpisy bez zmian. Docker testy/build, weryfikacja wygenerowanych odnośników/SEO/schema/hreflang/sitemap. Niezależne recenzje PL/EN, źródeł z własnymi pobraniami i integracji. **PR pozostaje otwarty: nie scalać, nie wdrażać.**
