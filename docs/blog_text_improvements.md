# Propozycje poprawek tekstów wpisów blogowych (dokument)

**Status:** PROPOZYCJA — do zatwierdzenia przez właściciela. Nic nie zostało wdrożone.
**Data:** sierpień 2026
**Kontekst:** lekcja z odrzuconego PR #41 (karta `t_e0e2075b`) — tam agent zastąpił cały szablon
`templates/blog_page_2_en.html.erb` komentarzami-placeholderami i usunąłby żywą stronę z serwisu.
Dlatego ten dokument **tylko opisuje** konkretne poprawki; żaden plik `templates/`, `lib/`, `assets/`
ani `test/` nie został zmieniony.

## Zakres

- Wyłącznie ten dokument (`docs/blog_text_improvements.md`).
- Źródło prawdy o tytułach/URL-ach: `lib/site/view/context.rb` → `BLOG_POSTS_PL`.
- Treść wpisów: `templates/blog/*.html.erb` (wersja PL; pliki `*_en.html.erb` to tłumaczenia PL).
- 4 wpisy, każdy z: (a) tytułem, (b) obecnym fragmentem, (c) proponowanym fragmentem, (d) uzasadnieniem.

---

## 1. „Linia Toyoda–Germanov: jak ćwiczymy i czym wyróżnia się nasza szkoła"

Plik: `templates/blog/linia_toyoda_germanov.html.erb`

### 1a. Pisownia nazwiska: „Edvard" → „Edward"

**Obecny fragment (wiersz 17):**
> Jeśli nauczanie Shihana **Edvarda** Germanova odczytać jako kontynuację osi Toyody,

**Proponowany fragment:**
> Jeśli nauczanie Shihana **Edwarda** Germanova odczytać jako kontynuację osi Toyody,

**Obecny fragment (wiersz 162, przypis 8):**
> Materiały środowiskowe dot. nauczania **Edvarda** Germanova (biogramy, opisy seminariów, relacje uczniów).

**Proponowany fragment:**
> Materiały środowiskowe dot. nauczania **Edwarda** Germanova (biogramy, opisy seminariów, relacje uczniów).

**Uzasadnienie (faktografia / spójność):** kanoniczna pisownia na całej stronie to **Edward Germanov**
— tak jest w biografii `templates/germanov.html.erb`, w FAQ (`faq.html.erb`: „Shihana Edwarda Germanova (7 dan)"),
we wpisie o misogi (`misogi.html.erb`: „Biografia Shihan Edwarda Germanova") oraz w biografii Ostrowskiego.
Forma „Edvard" to pojedyncza, niespójna odmiana. Poprawka dotyczy także wersji EN (patrz sekcja o EN).

---

## 2. „Styl Aikido Fumio Toyody: technika i Zen jako jeden system"

Plik: `templates/blog/styl_toyody.html.erb`

### 2a. Niejasne sformułowanie „moment utraty równowagi decyzji uke"

**Obecny fragment (wiersz 69, sekcja „Co znaczy Aikido + Zen na macie"):**
> **Dystans i timing:** wejście w moment utraty równowagi decyzji uke.

**Proponowany fragment:**
> **Dystans i timing:** wejście w momencie, w którym uke traci równowagę i pewność decyzji.

**Uzasadnienie (czytelność):** obecna fraza to dosłowne, kalekowe tłumaczenie angielskiego
„decisional balance" — „równowagi decyzji" jest w polszczyźnie dwuznaczne (równowaga *czego*? decyzji?).
Wersja EN (`styl_toyody_en.html.erb`) mówi wprost: „entering at the moment uke loses decisional balance",
czyli chodzi o to, że uke traci **zarówno równowagę, jak i pewność decyzji**. Proponowany zapis usuwa
dwuznaczność i jest naturalniejszy.

---

## 3. „Dlaczego w aikido nosi się hakamę?"

Plik: `templates/blog/dlaczego_w_aikido_nosi_sie_hakame.html.erb`

### 3a. Ogólnikowe „w części dojo" → konkret POA (hakama od 2 kyu)

**Obecny fragment (wiersz 152, sekcja „Najczęstsze uproszczenia"):**
> **„Hakama jest tylko oznaką stopnia":** w części dojo rzeczywiście wiąże się z etapem zaawansowania,
> ale to nie wyjaśnia jej sensu treningowego.

**Proponowany fragment:**
> **„Hakama jest tylko oznaką stopnia":** w naszym dojo nosi się ją od 2 kyu,
> ale to nie wyjaśnia jej sensu treningowego.

**Uzasadnienie (faktografia / konkret):** to jest strona POA, więc ogólnik „w części dojo" można zastąpić
własnym, sprawdzalnym faktem organizacji: hakama obowiązuje od 2 kyu
(por. `aikido/dla_poczatkujacych.html.erb`: „2 Kyu — biały pas + hakama"; `faq.html.erb`: „od 2 Kyu lub 1 Kyu").
Zamiana uogólnienia na konkret wzmacnia wiarygodność wpisu i spójność z resztą serwisu.

---

## 4. „Bushido (武士道) — droga wojownika"

Plik: `templates/blog/bushido.html.erb`

### 4a. Niespójna latynizacja siedmiu cnót (Yu/Chugi → Yū/Chūgi)

**Obecny fragment (wiersz 32):**
> **Yu (勇) — odwaga:** działanie mimo lęku i niepewności.

**Proponowany fragment:**
> **Yū (勇) — odwaga:** działanie mimo lęku i niepewności.

**Obecny fragment (wiersz 37):**
> **Chugi (忠義) — lojalność:** wierność zobowiązaniom i wspólnocie.

**Proponowany fragment:**
> **Chūgi (忠義) — lojalność:** wierność zobowiązaniom i wspólnocie.

**Uzasadnienie (spójność / styl):** te same siedem cnót pojawia się we wpisie o hakamie
(`dlaczego_w_aikido_nosi_sie_hakame.html.erb`) z makronami: **Yū (勇)** i **Chūgi (忠義)**. Konwencja
przyjęta na całej stronie używa makronów tam, gdzie oddają one długie samogłoski
(por. `Fudōshin`, `Hyōshi`, `Yūgen`, `Ensō`, a także „budō"/„bushidō" używane z makronem w innych wpisach).
Wpis o bushidō jako jedyny je pomija. Poprawka dotyczy też wersji EN (patrz sekcja o EN).

**Uwaga dodatkowa (do rozważenia, niższy priorytet):** opis cnoty Jin różni się lekko między wpisami —
hakama: „Jin (仁) — życzliwość i współczucie", bushido: „Jin (仁) — życzliwość". Warto ujednolicić
(nie ma to wpływu na fakty; decyzja stylistyczna właściciela).

---

## Uwagi o wersji EN

Zasada projektu: **PL jest źródłem prawdy, EN jest tłumaczeniem PL** (nie odwrotnie). Dlatego każda
zaakceptowana poprawka PL powinna zostać odzwierciedlona w odpowiadającym pliku `*_en.html.erb`:

1. **Edvard → Edward** — `linia_toyoda_germanov_en.html.erb` (wiersze 17 i 166) zawiera ten sam błąd
   („Shihan Edvard Germanov's teaching", „Community materials on Edvard Germanov's teaching") i powinien
   zostać poprawiony na „Edward Germanov" — tak jak w `misogi_en.html.erb` („Shihan Edward Germanov").

2. **Hakama od 2 kyu** — `dlaczego_w_aikido_nosi_sie_hakame_en.html.erb` (sekcja „Common simplifications",
   wiersz ~145) ma ten sam ogólnik „in some dojo it is indeed tied to level"; po akceptacji PL analogicznie
   doprecyzować na „in our dojo it is worn from 2 kyu".

3. **Yu/Yū, Chugi/Chūgi** — `bushido_en.html.erb` (wiersze 31 i 36) ma tę samą latynizację bez makronów;
   ujednolicić z wersją PL (i z wpisem o hakamie EN, gdzie wartości już są pisane z makronami).

4. **Punkt 2a** (styl Toyody) — wersja EN jest już poprawna („entering at the moment uke loses decisional
   balance"); to wersja PL wymaga doprecyzowania. Nie ma tu zmiany w EN.

---

## Weryfikacja (po ewentualnym wdrożeniu — NIE w tym kroku)

Gdy właściciel zatwierdzi wybrane propozycje, dopiero wtedy należy je wdrożyć w osobnym worktree/karcie,
a następnie zweryfikować:

- `sg docker -c 'docker run --rm -v "$PWD:/app" -w /app poa-dev:local ./bin/test'`
- `sg docker -c 'docker run --rm -v "$PWD:/app" -w /app poa-dev:local ./bin/build'`
- `git diff --check`

Ten dokument sam w sobie nie zmienia żadnego szablonu i nie ma wpływu na build/testy.
