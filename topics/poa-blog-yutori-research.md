# Yutori — zweryfikowane podstawy artykułu PL/EN

Karta: `t_f66c29d3`. Opracowanie: 2026-10-12. Zakres użytkownika: **tylko gotowy, otwarty PR; bez merge, deployu i Actions**.

Teksty docelowe: `templates/blog/yutori.html.erb` i `yutori_en.html.erb`. Ta nota zastępuje dla tego PR wcześniejszy research/draft z `wt/t_74cd1f1e`. Tamtego worktree nie zmieniono. Nie utrzymujemy rozbieżnej drugiej kopii tekstu publikacyjnego.

## Argument i forma

Margines to warunki pozwalające obu partnerom zauważyć błąd i odpowiedzieć na korektę. Yutori daje język do pytań o tempo, ustawienie, liczbę elementów zadania i dostępne możliwości. Zapas nie jest gwarancją bezpieczeństwa ani nagrodą wyłącznie za silną wolę.

Forma: otwarcie od konkretnej uwagi „wolniej”, jeden ilustracyjny przypadek w parze, kolejne korekty warunków. Nie kopiujemy narracji Kakugo o decyzji przed ruchem ani sceny Awase z chwytem. Oddech jest obserwacją, nie medycznym wyjaśnieniem i nie „paliwem” gwarantującym korektę.

PL: „Yutori (ゆとり) — zostaw miejsce na korektę”. EN: „Yutori (ゆとり) — room to adjust”.
- PL: `/blog/yutori-zostaw-miejsce-na-korekte.html`
- EN: `/en/blog/yutori-room-to-adjust.html`
- Data w kandydacie: 2026-10-12 (dzień przygotowania; do aktualizacji przed późniejszą publikacją).
- Kategoria: `:practice`.

PR samodzielny na `origin/master=0046cdfa9717828d66b7ce8dfa121b57c51a7693`; brak linków do jeszcze nieopublikowanego Heijōshin. Istniejące Kakugo i Awase zachowujemy bez zmian.

## Sprawdzone źródła

Pobrano i przeczytano hasła 2026-10-12. Źródła japońskie są podstawą znaczeń, nie dowodami skuteczności metod treningu.

1. https://kotobank.jp/word/%E3%82%86%E3%81%A8%E3%82%8A-652015
   - **Digital Daijisen (Shōgakukan):** `物事に余裕があり窮屈でないこと。余裕。` — zapas/swoboda, brak ciasnoty. Przykłady `経済的にゆとりがない` i `心にゆとりを持つ` potwierdzają zakres materialny i psychiczny.
   - **Seisenban Nihon Kokugo Daijiten:** `精神的なことについてもいう` — również w odniesieniu do spraw umysłowych; `余裕。くつろぎ。` Nie wykluczamy odpoczynku z zakresu słowa. Data 1773 dotyczy pierwszego przykładu w tym słowniku, nie ustalonego pochodzenia słowa; nie pojawia się w artykule.
2. https://jisho.org/search/%E3%82%86%E3%81%A8%E3%82%8A
   - Dokładny wpis API: https://jisho.org/api/v1/search/words?keyword=%E3%82%86%E3%81%A8%E3%82%8A ; wybrano slug `ゆとり`, nie homonim `湯取り`.
   - `elbowroom; leeway; room; reserve; margin; allowance; latitude; time (to spare)`; dane JMdict.
   - **Elbowroom to angielski odpowiednik, nie etymologia japońska.** Wcześniejsze „dosłownie miejsce na łokcie” nie miało podstaw. Artykuł wyraźnie odróżnia obraz od znaczenia i unika tytułu będącego kalką EN.
3. https://kotobank.jp/word/%E3%82%86%E3%81%A8%E3%82%8A%E6%95%99%E8%82%B2-155065
   - **Digital Daijisen** i **Nihon Daihyakka Zensho (Nipponica):** redukcja obciążenia materiałem/godzinami i reforma nauki szkolnej. Artykuł korzysta tylko z tego ogólnego kontekstu.
   - Usunięto niezweryfikowaną tezę „od 2016” i uogólnienie, że wielu Japończyków uważa samo słowo za lenistwo. Nie oceniamy pokolenia ani reformy.

## Lokalne granice praktyki

- `templates/blog/uke-i-nage-relacja-ktora-uczy.html.erb`: instruktor ustala formę i intensywność dla obu partnerów; każda osoba może zwolnić lub przerwać.
- `templates/blog/ukemi.html.erb`: przyjęcie techniki, bezpieczeństwo, współodpowiedzialność. Sam „zapas” nage nie wystarcza, gdy uke nie ma umiejętności przyjąć ruchu.
- Opublikowane `templates/blog/kakugo.html.erb`: zaangażowanie nie oznacza siły ani prędkości; podjęta decyzja nie wyłącza oceny ryzyka.

Te materiały są standardem dydaktycznym projektu, nie badaniem urazowości. Artykuł nie przypisuje O-Senseiowi ani całej tradycji nowej zasady bezpieczeństwa.

## Usunięte błędy starego draftu

- Brak tezy „mistrz nie jest szybszy, ma więcej zapasu” jako uniwersalnego prawa.
- Brak rady „zawsze pół kroku wcześniej”; timing i dystans zależą od zadania i instrukcji.
- Brak związków deterministycznych „kakugo produkuje yutori”, „pełne wejście zostawia zapas” i „brak dystansu skazuje na siłowanie”.
- Brak fizjologicznych metafor przedstawianych jako dowód: pełny oddech nie „finansuje” każdej korekty.
- Nie utożsamiamy odpoczynku z lenistwem ani małego zapasu z wadą charakteru. Zdrowie, obciążenia i ograniczenia zewnętrzne są ważne.
- Scena z maty oraz kalendarz są ilustracjami autora. Zastosowanie pojęcia do treningu to jawna interpretacja dydaktyczna.
- Nie obiecujemy bezpieczeństwa, leczenia stresu ani rozwiązania wszystkich problemów przez dyscyplinę.

## Gate PR

Regeneracja pełnego SEO snapshotu (dwie ścieżki artykułu oraz automatycznie dodana szósta strona indeksu PL/EN, stare wpisy bez zmian). Docker `bin/test` i `bin/build`, kontrola lokalnych linków/cytowań, lang-switch, metadanych, schema i sitemap. Niezależne review PL/EN, dowodowe z własnym pobraniem źródeł oraz integracyjne. Dopiero po zamknięciu uwag PR ma być oznaczony ready. **Nie scalać i nie wdrażać.**
