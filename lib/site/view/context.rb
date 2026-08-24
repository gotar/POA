require "uri"
require "json"
require "cgi"
require "digest"
require "dry/core/constants"
require "dry/view/context"
require "forwardable"
require "site/import"
require "site/view/seo_data"

module Site
  module View
    class Context < Dry::View::Context
      extend Forwardable

      include Dry::Core::Constants

      include Import["assets", "settings"]

      def_delegators :settings, :site_name, :site_author, :site_url

      attr_accessor :current_path
      attr_accessor :seo_description, :seo_keywords
      attr_accessor :root

      def initialize(current_path: nil, render_env: nil, root: nil, **deps)
        super(render_env: render_env)

        @current_path = current_path
        @root = root
        @page_title = deps[:page_title]
        @_assets = deps[:assets]
        @_settings = deps[:settings]
      end

      def for_render_env(render_env)
        self.class.new(
          current_path: @current_path,
          render_env: render_env,
          root: @root,
          assets: @_assets,
          settings: @_settings,
          page_title: @page_title
        )
      end

      def initialize_copy(source)
        super
        @current_path = source.instance_variable_get(:@current_path)
        @root = source.instance_variable_get(:@root)
        @page_title = source.instance_variable_get(:@page_title)
        @_assets = source.instance_variable_get(:@_assets)
        @_settings = source.instance_variable_get(:@_settings)
      end

      def assets
        @_assets || super
      end

      def settings
        @_settings || super
      end

      def page_title(new_title = Undefined)
        if new_title == Undefined
          title = @page_title || default_title_for_path(current_path)
          return site_name if title.nil? || title.to_s.strip.empty?

          title_str = title.to_s
          site_name_str = site_name.to_s

          return title_str if title_str.downcase.include?(site_name_str.downcase)

          [title_str, site_name_str].join(" | ")
        else
          @page_title = new_title
        end
      end

      def default_title_for_path(path)
        Site::View::SeoData.lookup(
          Site::View::SeoData::DEFAULT_TITLES,
          Site::View::SeoData::DEFAULT_TITLES_PATTERNS,
          site_name,
          path
        )
      end
      def page_description(path_or_new_description = Undefined)
        if path_or_new_description == Undefined
          @seo_description || @page_description || default_description_for_path(current_path)
        elsif path_or_new_description.is_a?(String)
          @seo_description || @page_description || default_description_for_path(path_or_new_description)
        else
          @page_description = path_or_new_description
        end
      end

      def page_keywords(path_or_new_keywords = Undefined)
        if path_or_new_keywords == Undefined
          @seo_keywords || @page_keywords || default_keywords_for_path(current_path)
        elsif path_or_new_keywords.is_a?(String)
          @seo_keywords || @page_keywords || default_keywords_for_path(path_or_new_keywords)
        else
          @page_keywords = path_or_new_keywords
        end
      end

      def default_description_for_path(path)
        Site::View::SeoData.lookup(
          Site::View::SeoData::DEFAULT_DESCRIPTIONS,
          Site::View::SeoData::DEFAULT_DESCRIPTIONS_PATTERNS,
          page_title,
          path
        )
      end
      def default_keywords_for_path(path)
        Site::View::SeoData.lookup(
          Site::View::SeoData::DEFAULT_KEYWORDS,
          Site::View::SeoData::DEFAULT_KEYWORDS_PATTERNS,
          Site::View::SeoData::DEFAULT_KEYWORDS_FALLBACK,
          path
        )
      end
      def default_description
        default_description_for_path(@current_path)
      end

      def default_keywords
        default_keywords_for_path(@current_path)
      end

      BLOG_POSTS_PER_PAGE = 10

      BLOG_POSTS_PL = [
        { date: "24 sierpnia 2026", title: "Tessen (鉄扇) w aikido — miecz bez miecza, który porządkuje ruch", url: "/blog/tessen-miecz-bez-miecza-ktory-porzadkuje-ruch.html", summary: "Tessen nie jest osobnym systemem walki. Żelazny wachlarz z przekazu O-Sensei porządkuje to, co ćwiczymy bez narzędzi: krawędź, atemi, dystans i intencję — na macie i poza nią." },
        { date: "13 czerwca 2026", title: "Egzamin w budō — pokaz drogi, nie występ przed komisją", url: "/blog/egzamin-w-budo-pokaz-drogi-nie-wystep.html", summary: "Egzamin w budō nie tworzy jakości. Odsłania drogę, którą uczeń naprawdę przeszedł: regularność, korektę, oddech, kontakt, błędy i odpowiedzialność za dalszy trening." },
        { date: "11 czerwca 2026", title: "Ukemi (受け身) — jak bezpiecznie upadać i wracać do działania", url: "/blog/ukemi-bezpiecznie-upasc-zachowac-strukture-wrocic-do-dzialania.html", summary: "Ukemi to sztuka bezpiecznego padania: chronić ciało, zostać miękkim, ale zbudowanym, i wrócić do działania także poza dojo." },
        { date: "8 czerwca 2026", title: "Genkikai (元気会) — ciało, które wraca na miejsce", url: "/blog/genkikai-cialo-ktore-wraca-na-miejsce.html", summary: "O trzeciej praktyce systemu Ikedy: jak Genkikai uzupełnia aikido i Hojo, dając ciału metodę powrotu po intensywnym treningu." },
        { date: "4 czerwca 2026", title: "Inna ścieżka na ten sam szczyt", url: "/blog/inna-sciezka-na-ten-sam-szczyt.html", summary: "Jak zmiany, kontuzje, utrata dawnego rytmu, praca i relacje mogą stać się inną ścieżką budō bez utraty kierunku." },
        { date: "3 czerwca 2026", title: "Yūgen (幽玄) — głębia, której nie da się spłaszczyć do instrukcji", url: "/blog/yugen-glebia-ktorej-nie-da-sie-splaszczyc.html", summary: "O tym, dlaczego dobra technika ma warstwę widoczną i niewidoczną: wyczucie czasu, dystans, intencję, ciszę i kontakt z partnerem." },
        { date: "31 maja 2026", title: "Ikkyo (一教) — pierwsza nauka, która nie kończy się nigdy", url: "/blog/ikkyo-pierwsza-nauka-ktora-nie-konczy-sie-nigdy.html", summary: "Dlaczego prosta kontrola łokcia odsłania całe aikido: postawę, centrum, oddech, riai i prowadzenie bez siłowania się." },
        { date: "30 maja 2026", title: "Mono no aware (物の哀れ) — czułość wobec przemijania", url: "/blog/mono-no-aware-czulosc-wobec-przemijania.html", summary: "Jak świadomość przemijania wyostrza uwagę, porządkuje relację uke–tori i pomaga podejmować decyzje na macie oraz poza nią." },
        { date: "25 maja 2026", title: "Ikigai (生き甲斐) — sens, który wytrzymuje zwykły tydzień", url: "/blog/ikigai-sens-regularnej-praktyki.html", summary: "Dlaczego zwykły powrót na matę mówi więcej o sensie praktyki niż chwilowa motywacja i wielkie deklaracje." },
        { date: "22 maja 2026", title: "Mottainai (もったいない) — nie marnuj tego, z czego możesz się uczyć", url: "/blog/mottainai-nie-marnuj-tego-co-moze-cie-nauczyc.html", summary: "O tym, jak nie przepuścić przez palce korekty, błędu, partnera i zwykłego powtórzenia, gdy mogą stać się realną zmianą." },
        { date: "18 maja 2026", title: "Droga i mistrzostwo", url: "/blog/droga-i-mistrzostwo.html", summary: "Co naprawdę zaczyna się wtedy, gdy techniki są już opanowane, i dlaczego mistrz mówi: 'nic nie wiem'." },
        { date: "16 maja 2026", title: "Nemawashi (根回し) — przygotowanie gruntu przed działaniem", url: "/blog/nemawashi-przygotowanie-gruntu-przed-dzialaniem.html", summary: "Dlaczego dobra technika, korekta i rozwój dojo wymagają przygotowania gruntu przed widocznym ruchem." },
        { date: "9 maja 2026", title: "Omotenashi (おもてなし) — gościnność na macie", url: "/blog/omotenashi-goscinnosc-ktora-buduje-dojo.html", summary: "Jak jakość ataku, sposób przyjmowania korekty i stosunek do mniej zaawansowanego partnera kształtują kulturę dojo od środka." },
        { date: "1 maja 2026", title: "Ninjō (人情) — ludzkie uczucia bez utraty kierunku", url: "/blog/ninjo-ludzkie-uczucia-bez-utraty-kierunku.html", summary: "Jak nie wypierać emocji w dojo, ale też nie pozwalać, by nastrój, ego albo sympatia prowadziły trening zamiast odpowiedzialności." },
        { date: "28 kwietnia 2026", title: "Giri (義理) — obowiązek bez wymówek", url: "/blog/giri-obowiazek-bez-wymowek.html", summary: "Dlaczego obowiązek w dojo nie jest ślepym posłuszeństwem, lecz odpowiedzialnością za partnera, korektę, linię przekazu i własny rozwój." },
        { date: "25 kwietnia 2026", title: "Wa (和) — harmonia bez uległości", url: "/blog/wa-harmonia-bez-uleglosci.html", summary: "Dlaczego harmonia w dojo nie oznacza świętego spokoju, lecz porządek relacji, korekty i odpowiedzialności pod presją." },
        { date: "20 kwietnia 2026", title: "Aikido dla nastolatków", url: "/blog/aikido-dla-nastolatkow.html", summary: "Jak aikido może wspierać dyscyplinę, sprawność, samokontrolę, relacje i rozwój młodego człowieka bez sportowej presji wyniku." },
        { date: "20 kwietnia 2026", title: "Dla kogo jest aikido?", url: "/blog/dla-kogo-jest-aikido.html", summary: "Dla początkujących, dorosłych, osób po przerwie i tych, którzy szukają regularnej praktyki bez sportowej rywalizacji — ale nie dla każdego celu." },
        { date: "20 kwietnia 2026", title: "Czy warto ćwiczyć aikido?", url: "/blog/czy-warto-cwiczyc-aikido.html", summary: "Uczciwa odpowiedź o korzyściach, ograniczeniach i o tym, kiedy trening aikido naprawdę ma sens." },
        { date: "20 kwietnia 2026", title: "Aikido w każdym wieku", url: "/blog/aikido-w-kazdym-wieku.html", summary: "Jak zacząć rozsądnie mając 20, 40 albo 60 lat i dlaczego wiek rzadko jest największą przeszkodą sam w sobie." },
        { date: "16 kwietnia 2026", title: "Dlaczego w aikido nosi się hakamę?", url: "/blog/dlaczego-w-aikido-nosi-sie-hakame.html", summary: "Skąd w aikido bierze się hakama, co ma wspólnego z heifuku, jak wpływa na ruch i dlaczego siedem plis łączy się z siedmioma cnotami." },
        { date: "11 kwietnia 2026", title: "5 zasad każdej techniki", url: "/blog/5-zasad-kazdej-techniki.html", summary: "Praktyczny model techniki w Aikido: centrum, oś, timing, wybranie luzu i kuzushi oraz podzasady, które pozwalają im działać razem." },
        { date: "4 kwietnia 2026", title: "Misogi (禊) — oczyszczenie przez praktykę", url: "/blog/misogi-oczyszczenie-przez-praktyke.html", summary: "Dlaczego misogi w stylu Toyody porządkuje oddech, uwagę i intencję oraz pozostaje żywą praktyką w linii przekazu." },
        { date: "2 kwietnia 2026", title: "Aiki (合気) — harmonia w działaniu, nie w deklaracji", url: "/blog/aiki-harmonia-w-dzialaniu.html", summary: "Dlaczego Aiki w Aikido zaczyna się przed techniką i oznacza przejęcie timingu, dystansu oraz balansu bez siłowego zderzenia." },
        { date: "26 marca 2026", title: "Ichi-go ichi-e (一期一会) — każde spotkanie zdarza się tylko raz", url: "/blog/ichi-go-ichi-e-kazde-spotkanie-zdarza-sie-tylko-raz.html", summary: "Dlaczego każda chwila treningu, korekta i spotkanie z partnerem są niepowtarzalne i wymagają pełnej obecności zamiast rutyny." },
        { date: "26 marca 2026", title: "Hansei (反省) — uczciwa autorefleksja bez wymówek", url: "/blog/hansei-uczciwa-autorefleksja-bez-wymowek.html", summary: "Dlaczego bez uczciwego zobaczenia własnego błędu trening zamienia się w obronę ego zamiast realnej korekty." },
        { date: "18 marca 2026", title: "Jeden nauczyciel, jeden przekaz", url: "/blog/jeden-nauczyciel-jeden-przekaz.html", summary: "Dlaczego jeden spójny przekaz chroni naukę przed chaosem, a starszy uczeń najlepiej wspiera trening jako dobry uke." },
        { date: "18 marca 2026", title: "Shuhari (守破離) — etapy dojrzewania w treningu", url: "/blog/shuhari-etapy-dojrzewania-w-treningu.html", summary: "Jak wiernie przepracowana forma dojrzewa w zrozumienie i swobodę, zamiast rozpadać się w chaos lub ego." },
        { date: "15 marca 2026", title: "Shoshin (初心) — umysł początkującego", url: "/blog/shoshin-umysl-poczatkujacego.html", summary: "Dlaczego prawdziwy rozwój zaczyna się tam, gdzie doświadczenie nie zamienia się jeszcze w pychę i rutynę." },
        { date: "14 marca 2026", title: "Fudōshin (不動心) — niewzruszony umysł", url: "/blog/fudoshin-niewzruszony-umysl.html", summary: "Jak zachować stabilność decyzji, oddechu i postawy wtedy, gdy presja najbardziej chce rozbić technikę." },
        { date: "7 marca 2026", title: "Styl Aikido Fumio Toyody: technika i Zen jako jeden system", url: "/blog/styl-aikido-fumio-toyody-technika-i-zen.html", summary: "Jak w linii Toyody łączy się precyzję techniki, oddech i dyscyplinę Zen w jednej metodyce treningowej." },
        { date: "7 marca 2026", title: "Linia Toyoda–Germanov: jak ćwiczymy i czym wyróżnia się nasza szkoła", url: "/blog/linia-toyoda-germanov-jak-cwiczymy.html", summary: "Profil naszej praktyki: precyzja techniczna, praca wewnętrzna i odpowiedzialny przekaz instruktorski." },
        { date: "6 marca 2026", title: "Hyōshi (拍子) — rytm i timing jedności", url: "/blog/hyoshi-rytm-timing-jednosci-ruchu.html", summary: "Cięcie ruchu albo jego rozlanie natychmiast ujawnia jakość jedności ciała, oddechu i decyzji." },
        { date: "6 marca 2026", title: "Ensō (円相) — krąg obecności", url: "/blog/enso-krag-obecnosci.html", summary: "Jeden ruch pędzla, który bezlitośnie pokazuje jakość umysłu i decyzji pod presją." },
        { date: "25 lutego 2026", title: "Zanshin (残心) — czujność po technice", url: "/blog/zanshin-czujnosc-po-technice.html", summary: "Dlaczego najwięcej błędów pojawia się po ruchu i jak utrzymać uwagę do końca działania." },
        { date: "24 lutego 2026", title: "Sesshin (接心) — głęboka praktyka i skupienie", url: "/blog/sesshin-gleboka-praktyka.html", summary: "Dlaczego Sesshin to fundament naszej metody pracy i kluczowy element tożsamości Sesshinkan Dojo." },
        { date: "23 lutego 2026", title: "Bushido (武士道) — droga wojownika", url: "/blog/bushido-droga-wojownika.html", summary: "Kodeks samuraja i siedem cnót, które można stosować dziś: na macie, w pracy i w codziennych decyzjach." },
        { date: "23 lutego 2026", title: "Kaizen (改善) — ciągłe doskonalenie", url: "/blog/kaizen-ciagle-doskonalenie.html", summary: "Małe, codzienne kroki prowadzą do trwałego postępu i mocnych fundamentów techniki." },
        { date: "23 lutego 2026", title: "Gaman (我慢) — wytrwałość i opanowanie", url: "/blog/gaman-wytrwalosc.html", summary: "Sztuka znoszenia trudności z godnością, spokojem i dojrzałością." },
        { date: "23 lutego 2026", title: "Kintsugi (金継ぎ) — złota naprawa", url: "/blog/kintsugi-zlota-naprawa.html", summary: "Pęknięcia nie muszą być ukrywane — mogą stać się źródłem siły i nowego znaczenia." },
        { date: "23 lutego 2026", title: "Wabi-Sabi (侘寂) — piękno niedoskonałości", url: "/blog/wabi-sabi-piekno-niedoskonalosci.html", summary: "Akceptacja prostoty, przemijania i niedoskonałości jako części naturalnego rozwoju." },
        { date: "23 lutego 2026", title: "Mushin (無心) — umysł bez umysłu", url: "/blog/mushin-umysl-bez-umyslu.html", summary: "Stan pełnej obecności: bez napięcia, bez przywiązania, z jasnym działaniem." },
        { date: "23 lutego 2026", title: "Zenshin (前進) — pełne zaangażowanie", url: "/blog/zenshin-pelne-zaangazowanie.html", summary: "Konsekwentny ruch naprzód z całą uwagą i odpowiedzialnością za proces." },
        { date: "23 lutego 2026", title: "Omoiyari (思いやり) — uważna troska", url: "/blog/omoiyari-uwazna-troska.html", summary: "Empatia w praktyce: rozumienie potrzeb drugiej osoby zanim zostaną wypowiedziane." },
        { date: "23 lutego 2026", title: "Jiko Sekinin (自己責任) — odpowiedzialność osobista", url: "/blog/jiko-sekinin-odpowiedzialnosc-osobista.html", summary: "Branie odpowiedzialności za decyzje, błędy i konsekwencje bez szukania wymówek." },
        { date: "23 lutego 2026", title: "Kuzushi (崩し) — kontrolowana nierównowaga", url: "/blog/kuzushi-kontrolowana-nierownowaga.html", summary: "W Aikido i poza matą: jak świadomie zmieniać układ sił, by otworzyć przestrzeń na transformację." }
      ].freeze

      BLOG_POSTS_EN = [
        { date: "August 24, 2026", title: "Tessen (鉄扇) in Aikido — the sword that is not a sword", url: "/en/blog/tessen-the-sword-that-is-not-a-sword.html", summary: "The tessen is not a separate fighting system. The iron fan from O-Sensei's transmission puts in order what we already train without tools: the edge, atemi, distance, and intent — on and off the mat." },
        { date: "June 13, 2026", title: "Exams in Budō — showing the road, not performing for the panel", url: "/en/blog/exams-in-budo-showing-the-road-not-performing.html", summary: "A budō exam does not create quality. It reveals the road already walked: regular practice, correction, breath, contact, mistakes, and responsibility for what comes next." },
        { date: "June 11, 2026", title: "Ukemi (受け身) — falling safely, keeping structure, returning to action", url: "/en/blog/ukemi-falling-safely-keeping-structure-returning-to-action.html", summary: "Ukemi is not a flashy roll. It is an essential Aikido skill: falling safely, staying soft but structured, and returning to action." },
        { date: "June 8, 2026", title: "Genkikai (元気会) — the body that returns to order", url: "/en/blog/genkikai-the-body-that-returns-to-order.html", summary: "On the third practice in Ikeda's system: how Genkikai completes Aikido and Hojo by giving the body a method of return after intense training." },
        { date: "June 4, 2026", title: "Another path to the same summit", url: "/en/blog/another-path-to-the-same-summit.html", summary: "How change, injury, the loss of an old rhythm, work, and relationships can become another path in budō without losing direction." },
        { date: "June 3, 2026", title: "Yūgen (幽玄) — depth that cannot be flattened into instruction", url: "/en/blog/yugen-depth-that-cannot-be-flattened.html", summary: "Why good technique has a visible and an invisible layer: timing, distance, intent, quiet, and contact with a partner." },
        { date: "May 31, 2026", title: "Ikkyo (一教) — the first teaching that never ends", url: "/en/blog/ikkyo-the-first-teaching-that-never-ends.html", summary: "Why simple elbow control reveals the whole of Aikido: posture, center, breath, riai, and leading without force." },
        { date: "May 30, 2026", title: "Mono no aware (物の哀れ) — sensitivity to impermanence", url: "/en/blog/mono-no-aware-sensitivity-to-impermanence.html", summary: "How awareness of impermanence sharpens attention, improves partner work, and clarifies decisions on and off the mat." },
        { date: "May 25, 2026", title: "Ikigai (生き甲斐) — meaning that survives an ordinary week", url: "/en/blog/ikigai-the-reason-to-return-to-practice.html", summary: "Why returning to the mat in an ordinary week says more about the meaning of practice than temporary motivation or grand declarations." },
        { date: "May 22, 2026", title: "Mottainai (もったいない) — do not waste what can teach you", url: "/en/blog/mottainai-do-not-waste-what-can-teach-you.html", summary: "How not to waste correction, partners, time, and energy on the mat, but turn them into real learning." },
        { date: "May 18, 2026", title: "The Path and Mastery", url: "/en/blog/the-path-and-mastery.html", summary: "What truly begins once techniques have been mastered, and why a master says, 'I know nothing'." },
        { date: "May 16, 2026", title: "Nemawashi (根回し) — laying the groundwork before action", url: "/en/blog/nemawashi-laying-groundwork-before-action.html", summary: "Why good technique, correction, and dojo development require groundwork before visible movement." },
        { date: "May 9, 2026", title: "Omotenashi (おもてなし) — hospitality on the mat", url: "/en/blog/omotenashi-hospitality-that-builds-the-dojo.html", summary: "How the quality of your attack, openness to correction, and conduct with less advanced partners shape dojo culture from within." },
        { date: "May 1, 2026", title: "Ninjō (人情) — human feeling without losing direction", url: "/en/blog/ninjo-human-feeling-without-losing-direction.html", summary: "How not to repress emotion in the dojo, while also refusing to let mood, ego, or preference steer training instead of responsibility." },
        { date: "April 28, 2026", title: "Giri (義理) — duty without excuses", url: "/en/blog/giri-duty-without-excuses.html", summary: "Why duty in the dojo is not blind obedience, but responsibility toward the partner, correction, transmission line, and one's own development." },
        { date: "April 25, 2026", title: "Wa (和) — harmony without submission", url: "/en/blog/wa-harmony-without-submission.html", summary: "Why harmony in the dojo is not polite peace, but ordered relationship, correction, and responsibility under pressure." },
        { date: "April 20, 2026", title: "Aikido for teenagers", url: "/en/blog/aikido-for-teenagers.html", summary: "How Aikido can support discipline, fitness, self-control, relationships, and youth development without sport-result pressure." },
        { date: "April 20, 2026", title: "Who is Aikido for?", url: "/en/blog/who-is-aikido-for.html", summary: "For beginners, adults, people returning after a break, and anyone seeking regular practice without sport competition—but not for every goal." },
        { date: "April 20, 2026", title: "Is Aikido worth practicing?", url: "/en/blog/is-aikido-worth-practicing.html", summary: "An honest answer about benefits, limits, and when Aikido training is actually worth your time and attention." },
        { date: "April 20, 2026", title: "Aikido at every age", url: "/en/blog/aikido-at-every-age.html", summary: "How to begin intelligently in your 20s, 40s, or 60s and why age itself is rarely the biggest obstacle." },
        { date: "April 16, 2026", title: "Why do Aikido practitioners wear hakama?", url: "/en/blog/why-aikido-practitioners-wear-hakama.html", summary: "Where hakama in Aikido comes from, what it has to do with heifuku, how it shapes movement, and why seven pleats are linked to seven virtues." },
        { date: "April 11, 2026", title: "Five principles behind every technique", url: "/en/blog/five-principles-behind-every-technique.html", summary: "A practical Aikido model: center, axis, timing, taking the slack out, and kuzushi plus the sub-principles that let them work together." },
        { date: "April 4, 2026", title: "Misogi (禊) — purification through practice", url: "/en/blog/misogi-purification-through-practice.html", summary: "Why misogi in Toyoda’s style orders breath, attention, and intention and remains a living practice in the transmission line." },
        { date: "April 2, 2026", title: "Aiki (合気) — harmony in action, not in slogans", url: "/en/blog/aiki-harmony-in-action.html", summary: "Why Aiki in Aikido begins before technique and means taking timing, distance, and balance without clashing force against force." },
        { date: "March 26, 2026", title: "Ichi-go ichi-e (一期一会) — every encounter happens only once", url: "/en/blog/ichi-go-ichi-e-every-encounter-happens-only-once.html", summary: "Why every training moment, correction, and encounter with a partner is unrepeatable and deserves full presence instead of routine." },
        { date: "March 26, 2026", title: "Hansei (反省) — honest self-reflection without excuses", url: "/en/blog/hansei-honest-self-reflection-without-excuses.html", summary: "Why training without honest recognition of your own mistakes becomes ego defense instead of real correction." },
        { date: "March 18, 2026", title: "One teacher, one transmission", url: "/en/blog/one-teacher-one-transmission.html", summary: "Why one coherent transmission protects learning from confusion, and why senior students support training best by being good uke." },
        { date: "March 18, 2026", title: "Shuhari (守破離) — stages of maturation in training", url: "/en/blog/shuhari-stages-of-maturation-in-training.html", summary: "How faithfully trained form matures into understanding and freedom instead of collapsing into chaos or ego." },
        { date: "March 15, 2026", title: "Shoshin (初心) — beginner's mind", url: "/en/blog/shoshin-beginners-mind.html", summary: "Why real growth begins where experience still refuses to harden into ego, certainty, and routine." },
        { date: "March 14, 2026", title: "Fudōshin (不動心) — immovable mind", url: "/en/blog/fudoshin-immovable-mind.html", summary: "How to preserve stability of decision, breath, and posture when pressure is most likely to break technique." },
        { date: "March 7, 2026", title: "Fumio Toyoda’s Aikido style: technique and Zen as one system", url: "/en/blog/toyoda-aikido-style-technique-and-zen.html", summary: "How Toyoda lineage integrates technical precision, breath work, and Zen discipline into one training method." },
        { date: "March 7, 2026", title: "Toyoda–Germanov lineage: how we train and what sets our school apart", url: "/en/blog/toyoda-germanov-lineage-how-we-train.html", summary: "Our training profile: technical precision, inner discipline, and responsible instructor-led transmission." },
        { date: "March 6, 2026", title: "Hyōshi (拍子) — rhythm and timing of unity", url: "/en/blog/hyoshi-timing-reveals-unity-of-movement.html", summary: "Cutting movement or letting it spill immediately reveals the quality of unity between body, breath, and intent." },
        { date: "March 6, 2026", title: "Ensō (円相) — circle of presence", url: "/en/blog/enso-circle-of-presence.html", summary: "One brushstroke that exposes the quality of mind and decision-making under pressure." },
        { date: "February 25, 2026", title: "Zanshin (残心) — awareness after execution", url: "/en/blog/zanshin-awareness-after-execution.html", summary: "Why many errors happen after action and how to maintain awareness until the process is truly complete." },
        { date: "February 24, 2026", title: "Sesshin (接心) — deep practice and focused mind", url: "/en/blog/sesshin-deep-practice.html", summary: "Why Sesshin is a core training method and a central identity element of Sesshinkan Dojo." },
        { date: "February 23, 2026", title: "Bushido (武士道) — way of the warrior", url: "/en/blog/bushido-way-of-the-warrior.html", summary: "The samurai code and seven virtues that remain practical on the mat, at work, and in daily decisions." },
        { date: "February 23, 2026", title: "Kaizen (改善) — continuous improvement", url: "/en/blog/kaizen-continuous-improvement.html", summary: "Small daily steps that produce durable progress and stronger technical foundations." },
        { date: "February 23, 2026", title: "Gaman (我慢) — endurance and composure", url: "/en/blog/gaman-endurance-and-composure.html", summary: "The art of carrying pressure with dignity, calm, and mature self-control." },
        { date: "February 23, 2026", title: "Kintsugi (金継ぎ) — golden repair", url: "/en/blog/kintsugi-golden-repair.html", summary: "Cracks do not need to be hidden — they can become a source of strength and meaning." },
        { date: "February 23, 2026", title: "Wabi-Sabi (侘寂) — beauty of imperfection", url: "/en/blog/wabi-sabi-beauty-of-imperfection.html", summary: "Accepting simplicity, impermanence, and imperfection as part of authentic growth." },
        { date: "February 23, 2026", title: "Mushin (無心) — no mind", url: "/en/blog/mushin-no-mind.html", summary: "A state of clear presence: no fixation, no noise, and natural action under pressure." },
        { date: "February 23, 2026", title: "Zenshin (前進) — full commitment", url: "/en/blog/zenshin-full-commitment.html", summary: "Consistent forward movement with full attention and ownership of the process." },
        { date: "February 23, 2026", title: "Omoiyari (思いやり) — considerate compassion", url: "/en/blog/omoiyari-considerate-compassion.html", summary: "Empathy in practice: understanding your partner's needs before they are spoken." },
        { date: "February 23, 2026", title: "Jiko Sekinin (自己責任) — personal responsibility", url: "/en/blog/jiko-sekinin-personal-responsibility.html", summary: "Owning decisions, mistakes, and consequences without excuses or blame-shifting." },
        { date: "February 23, 2026", title: "Kuzushi (崩し) — controlled imbalance", url: "/en/blog/kuzushi-controlled-imbalance.html", summary: "On and off the mat: changing force relationships consciously to create room for transformation." }
      ].freeze

      def canonical_url
        path = current_path || ""
        separator = path.empty? || path.start_with?("/") ? "" : "/"
        "#{site_url}#{separator}#{path}"
      end

      def blog_current_page
        path = current_path.to_s
        return 1 if path == "blog.html" || path == "en/blog.html"

        match = path.match(%r{\A(?:en/)?blog-(\d+)\.html\z})
        page = match ? match[1].to_i : 1
        page.positive? ? page : 1
      end

      def blog_posts(language: current_lang)
        language == "en" ? BLOG_POSTS_EN : BLOG_POSTS_PL
      end

      def blog_total_pages(language: current_lang)
        total = (blog_posts(language: language).size.to_f / BLOG_POSTS_PER_PAGE).ceil
        total.positive? ? total : 1
      end

      def blog_posts_for_current_page
        offset = (blog_current_page - 1) * BLOG_POSTS_PER_PAGE
        blog_posts.slice(offset, BLOG_POSTS_PER_PAGE) || []
      end

      def blog_page_numbers(language: current_lang)
        (1..blog_total_pages(language: language)).to_a
      end

      def blog_page_path(page, language: current_lang)
        normalized_page = page.to_i
        normalized_page = 1 if normalized_page < 1

        if language == "en"
          normalized_page == 1 ? "/en/blog.html" : "/en/blog-#{normalized_page}.html"
        else
          normalized_page == 1 ? "/blog.html" : "/blog-#{normalized_page}.html"
        end
      end

      # The visible call to action stays concise; its accessible name names
      # the destination article and is safe for an HTML attribute.
      def read_more_aria_label(title)
        prefix = current_path.to_s.start_with?("en/") ? "Read more" : "Czytaj więcej"

        ::CGI.escapeHTML("#{prefix}: #{title}")
      end

      def blog_article_page?
        path = current_path.to_s
        return false if path.empty?

        (path.start_with?("blog/") || path.start_with?("en/blog/")) && !path.match?(%r{\A(?:en/)?blog(?:-\d+)?\.html\z})
      end

      def social_image_for_path(path)
        case path.to_s
        when "blog/enso-krag-obecnosci.html", "en/blog/enso-circle-of-presence.html"
          "images/blog/enso-featured.png"
        when "blog/jeden-nauczyciel-jeden-przekaz.html", "en/blog/one-teacher-one-transmission.html"
          "images/blog/one-teacher-one-transmission-featured.jpeg"
        else
          "images/toyoda.svg"
        end
      end

      def page_social_image_url
        "#{site_url}#{asset_path(social_image_for_path(current_path))}"
      end

      def blog_article_entry
        return nil unless blog_article_page?

        path = "/#{current_path.to_s.sub(%r{\A/+}, "")}".downcase
        blog_posts.find { |entry| entry[:url].to_s.downcase == path }
      end

      def page_social_title
        entry = blog_article_entry
        return entry[:title] if entry && entry[:title].to_s.strip != ""

        page_title
      end

      def page_social_description
        entry = blog_article_entry
        return entry[:summary] if entry && entry[:summary].to_s.strip != ""

        page_description
      end

      def article_schema_for_current_path
        entry = Site::View::SeoData::ARTICLE_SCHEMA_DATA[current_path.to_s]
        return "" unless entry

        article_schema(
          name: entry[:name],
          description: page_description,
          image: page_social_image_url,
          lang: entry.fetch(:lang, "pl"),
          date_published: entry[:date_published],
          date_modified: entry.fetch(:date_modified, entry[:date_published])
        )
      end
      LANG_URL_MAP = {
        "index.html" => "en/",
        "" => "en/",
        "kontakt.html" => "en/contact.html",
        "aikido/czym_jest.html" => "en/aikido/what_is.html",
        "aikido/historia.html" => "en/aikido/history.html",
        "aikido/korzysci.html" => "en/aikido/benefits.html",
        "aikido/dla_poczatkujacych.html" => "en/aikido/beginners.html",
        "aikido/aiki_taiso.html" => "en/aikido/aiki_taiso.html",
        "aikido/reishiki.html" => "en/aikido/reishiki.html",
        "aikido/budo_zen.html" => "en/aikido/budo_zen.html",
        "aikido/ki_kokyu.html" => "en/aikido/ki_kokyu.html",
        "slowniczek.html" => "en/glossary.html",
        "wymagania_egzaminacyjne/kyu.html" => "en/requirements/kyu.html",
        "wymagania_egzaminacyjne/dan.html" => "en/requirements/dan.html",
        "lineage.html" => "en/lineage.html",
        "biografie/o-sensei.html" => "en/biographies/o-sensei.html",
        "biografie/kisshomaru.html" => "en/biographies/kisshomaru.html",
        "biografie/moriteru.html" => "en/biographies/moriteru.html",
        "biografie/mitsuteru.html" => "en/biographies/mitsuteru.html",
        "biografie/toyoda.html" => "en/biographies/toyoda.html",
        "biografie/germanov.html" => "en/biographies/germanov.html",
        "biografie/ostrowski.html" => "en/biographies/ostrowski.html",
        "biografie/szrajer.html" => "en/biographies/szrajer.html",
        "wydarzenia/2026.html" => "en/events/2026.html",
        "faq.html" => "en/faq.html",
        "gdynia.html" => "en/gdynia.html",
        "yudansha.html" => "en/yudansha.html",
        "blog.html" => "en/blog.html",
        "blog-2.html" => "en/blog-2.html",
        "blog-3.html" => "en/blog-3.html",
        "blog-4.html" => "en/blog-4.html",
        "blog-5.html" => "en/blog-5.html",
        "blog/bushido-droga-wojownika.html" => "en/blog/bushido-way-of-the-warrior.html",
        "blog/kaizen-ciagle-doskonalenie.html" => "en/blog/kaizen-continuous-improvement.html",
        "blog/gaman-wytrwalosc.html" => "en/blog/gaman-endurance-and-composure.html",
        "blog/kintsugi-zlota-naprawa.html" => "en/blog/kintsugi-golden-repair.html",
        "blog/wabi-sabi-piekno-niedoskonalosci.html" => "en/blog/wabi-sabi-beauty-of-imperfection.html",
        "blog/mushin-umysl-bez-umyslu.html" => "en/blog/mushin-no-mind.html",
        "blog/sesshin-gleboka-praktyka.html" => "en/blog/sesshin-deep-practice.html",
        "blog/zenshin-pelne-zaangazowanie.html" => "en/blog/zenshin-full-commitment.html",
        "blog/zanshin-czujnosc-po-technice.html" => "en/blog/zanshin-awareness-after-execution.html",
        "blog/enso-krag-obecnosci.html" => "en/blog/enso-circle-of-presence.html",
        "blog/hyoshi-rytm-timing-jednosci-ruchu.html" => "en/blog/hyoshi-timing-reveals-unity-of-movement.html",
        "blog/fudoshin-niewzruszony-umysl.html" => "en/blog/fudoshin-immovable-mind.html",
        "blog/shoshin-umysl-poczatkujacego.html" => "en/blog/shoshin-beginners-mind.html",
        "blog/shuhari-etapy-dojrzewania-w-treningu.html" => "en/blog/shuhari-stages-of-maturation-in-training.html",
        "blog/hansei-uczciwa-autorefleksja-bez-wymowek.html" => "en/blog/hansei-honest-self-reflection-without-excuses.html",
        "blog/aiki-harmonia-w-dzialaniu.html" => "en/blog/aiki-harmony-in-action.html",
        "blog/wa-harmonia-bez-uleglosci.html" => "en/blog/wa-harmony-without-submission.html",
        "blog/giri-obowiazek-bez-wymowek.html" => "en/blog/giri-duty-without-excuses.html",
        "blog/ninjo-ludzkie-uczucia-bez-utraty-kierunku.html" => "en/blog/ninjo-human-feeling-without-losing-direction.html",
        "blog/omotenashi-goscinnosc-ktora-buduje-dojo.html" => "en/blog/omotenashi-hospitality-that-builds-the-dojo.html",
        "blog/nemawashi-przygotowanie-gruntu-przed-dzialaniem.html" => "en/blog/nemawashi-laying-groundwork-before-action.html",
        "blog/mottainai-nie-marnuj-tego-co-moze-cie-nauczyc.html" => "en/blog/mottainai-do-not-waste-what-can-teach-you.html",
        "blog/mono-no-aware-czulosc-wobec-przemijania.html" => "en/blog/mono-no-aware-sensitivity-to-impermanence.html",
        "blog/ikkyo-pierwsza-nauka-ktora-nie-konczy-sie-nigdy.html" => "en/blog/ikkyo-the-first-teaching-that-never-ends.html",
        "blog/yugen-glebia-ktorej-nie-da-sie-splaszczyc.html" => "en/blog/yugen-depth-that-cannot-be-flattened.html",
        "blog/egzamin-w-budo-pokaz-drogi-nie-wystep.html" => "en/blog/exams-in-budo-showing-the-road-not-performing.html",
        "blog/ukemi-bezpiecznie-upasc-zachowac-strukture-wrocic-do-dzialania.html" => "en/blog/ukemi-falling-safely-keeping-structure-returning-to-action.html",
        "blog/tessen-miecz-bez-miecza-ktory-porzadkuje-ruch.html" => "en/blog/tessen-the-sword-that-is-not-a-sword.html",
        "blog/genkikai-cialo-ktore-wraca-na-miejsce.html" => "en/blog/genkikai-the-body-that-returns-to-order.html",
        "blog/inna-sciezka-na-ten-sam-szczyt.html" => "en/blog/another-path-to-the-same-summit.html",
        "blog/ikigai-sens-regularnej-praktyki.html" => "en/blog/ikigai-the-reason-to-return-to-practice.html",
        "blog/misogi-oczyszczenie-przez-praktyke.html" => "en/blog/misogi-purification-through-practice.html",
        "blog/5-zasad-kazdej-techniki.html" => "en/blog/five-principles-behind-every-technique.html",
        "blog/dlaczego-w-aikido-nosi-sie-hakame.html" => "en/blog/why-aikido-practitioners-wear-hakama.html",
        "blog/dla-kogo-jest-aikido.html" => "en/blog/who-is-aikido-for.html",
        "blog/czy-warto-cwiczyc-aikido.html" => "en/blog/is-aikido-worth-practicing.html",
        "blog/aikido-w-kazdym-wieku.html" => "en/blog/aikido-at-every-age.html",
        "blog/aikido-dla-nastolatkow.html" => "en/blog/aikido-for-teenagers.html",
        "blog/ichi-go-ichi-e-kazde-spotkanie-zdarza-sie-tylko-raz.html" => "en/blog/ichi-go-ichi-e-every-encounter-happens-only-once.html",
        "blog/jeden-nauczyciel-jeden-przekaz.html" => "en/blog/one-teacher-one-transmission.html",
        "blog/styl-aikido-fumio-toyody-technika-i-zen.html" => "en/blog/toyoda-aikido-style-technique-and-zen.html",
        "blog/linia-toyoda-germanov-jak-cwiczymy.html" => "en/blog/toyoda-germanov-lineage-how-we-train.html",
        "blog/omoiyari-uwazna-troska.html" => "en/blog/omoiyari-considerate-compassion.html",
        "blog/jiko-sekinin-odpowiedzialnosc-osobista.html" => "en/blog/jiko-sekinin-personal-responsibility.html",
        "blog/kuzushi-kontrolowana-nierownowaga.html" => "en/blog/kuzushi-controlled-imbalance.html",
        "blog/droga-i-mistrzostwo.html" => "en/blog/the-path-and-mastery.html",
        "en/" => "",
        "en/index.html" => "",
        "en/contact.html" => "kontakt.html",
        "en/aikido/what_is.html" => "aikido/czym_jest.html",
        "en/aikido/history.html" => "aikido/historia.html",
        "en/aikido/benefits.html" => "aikido/korzysci.html",
        "en/aikido/beginners.html" => "aikido/dla_poczatkujacych.html",
        "en/aikido/aiki_taiso.html" => "aikido/aiki_taiso.html",
        "en/aikido/reishiki.html" => "aikido/reishiki.html",
        "en/aikido/budo_zen.html" => "aikido/budo_zen.html",
        "en/aikido/ki_kokyu.html" => "aikido/ki_kokyu.html",
        "en/glossary.html" => "slowniczek.html",
        "en/requirements/kyu.html" => "wymagania_egzaminacyjne/kyu.html",
        "en/requirements/dan.html" => "wymagania_egzaminacyjne/dan.html",
        "en/lineage.html" => "lineage.html",
        "en/biographies/o-sensei.html" => "biografie/o-sensei.html",
        "en/biographies/kisshomaru.html" => "biografie/kisshomaru.html",
        "en/biographies/moriteru.html" => "biografie/moriteru.html",
        "en/biographies/mitsuteru.html" => "biografie/mitsuteru.html",
        "en/biographies/toyoda.html" => "biografie/toyoda.html",
        "en/biographies/germanov.html" => "biografie/germanov.html",
        "en/biographies/ostrowski.html" => "biografie/ostrowski.html",
        "en/biographies/szrajer.html" => "biografie/szrajer.html",
        "en/events/2026.html" => "wydarzenia/2026.html",
        "en/faq.html" => "faq.html",
        "en/gdynia.html" => "gdynia.html",
        "en/yudansha.html" => "yudansha.html",
        "en/blog.html" => "blog.html",
        "en/blog-2.html" => "blog-2.html",
        "en/blog-3.html" => "blog-3.html",
        "en/blog-4.html" => "blog-4.html",
        "en/blog-5.html" => "blog-5.html",
        "en/blog/bushido-way-of-the-warrior.html" => "blog/bushido-droga-wojownika.html",
        "en/blog/kaizen-continuous-improvement.html" => "blog/kaizen-ciagle-doskonalenie.html",
        "en/blog/gaman-endurance-and-composure.html" => "blog/gaman-wytrwalosc.html",
        "en/blog/kintsugi-golden-repair.html" => "blog/kintsugi-zlota-naprawa.html",
        "en/blog/wabi-sabi-beauty-of-imperfection.html" => "blog/wabi-sabi-piekno-niedoskonalosci.html",
        "en/blog/mushin-no-mind.html" => "blog/mushin-umysl-bez-umyslu.html",
        "en/blog/sesshin-deep-practice.html" => "blog/sesshin-gleboka-praktyka.html",
        "en/blog/zenshin-full-commitment.html" => "blog/zenshin-pelne-zaangazowanie.html",
        "en/blog/zanshin-awareness-after-execution.html" => "blog/zanshin-czujnosc-po-technice.html",
        "en/blog/enso-circle-of-presence.html" => "blog/enso-krag-obecnosci.html",
        "en/blog/hyoshi-timing-reveals-unity-of-movement.html" => "blog/hyoshi-rytm-timing-jednosci-ruchu.html",
        "en/blog/fudoshin-immovable-mind.html" => "blog/fudoshin-niewzruszony-umysl.html",
        "en/blog/shoshin-beginners-mind.html" => "blog/shoshin-umysl-poczatkujacego.html",
        "en/blog/shuhari-stages-of-maturation-in-training.html" => "blog/shuhari-etapy-dojrzewania-w-treningu.html",
        "en/blog/hansei-honest-self-reflection-without-excuses.html" => "blog/hansei-uczciwa-autorefleksja-bez-wymowek.html",
        "en/blog/aiki-harmony-in-action.html" => "blog/aiki-harmonia-w-dzialaniu.html",
        "en/blog/wa-harmony-without-submission.html" => "blog/wa-harmonia-bez-uleglosci.html",
        "en/blog/giri-duty-without-excuses.html" => "blog/giri-obowiazek-bez-wymowek.html",
        "en/blog/ninjo-human-feeling-without-losing-direction.html" => "blog/ninjo-ludzkie-uczucia-bez-utraty-kierunku.html",
        "en/blog/omotenashi-hospitality-that-builds-the-dojo.html" => "blog/omotenashi-goscinnosc-ktora-buduje-dojo.html",
        "en/blog/nemawashi-laying-groundwork-before-action.html" => "blog/nemawashi-przygotowanie-gruntu-przed-dzialaniem.html",
        "en/blog/mottainai-do-not-waste-what-can-teach-you.html" => "blog/mottainai-nie-marnuj-tego-co-moze-cie-nauczyc.html",
        "en/blog/mono-no-aware-sensitivity-to-impermanence.html" => "blog/mono-no-aware-czulosc-wobec-przemijania.html",
        "en/blog/ikkyo-the-first-teaching-that-never-ends.html" => "blog/ikkyo-pierwsza-nauka-ktora-nie-konczy-sie-nigdy.html",
        "en/blog/yugen-depth-that-cannot-be-flattened.html" => "blog/yugen-glebia-ktorej-nie-da-sie-splaszczyc.html",
        "en/blog/exams-in-budo-showing-the-road-not-performing.html" => "blog/egzamin-w-budo-pokaz-drogi-nie-wystep.html",
        "en/blog/ukemi-falling-safely-keeping-structure-returning-to-action.html" => "blog/ukemi-bezpiecznie-upasc-zachowac-strukture-wrocic-do-dzialania.html",
        "en/blog/tessen-the-sword-that-is-not-a-sword.html" => "blog/tessen-miecz-bez-miecza-ktory-porzadkuje-ruch.html",
        "en/blog/genkikai-the-body-that-returns-to-order.html" => "blog/genkikai-cialo-ktore-wraca-na-miejsce.html",
        "en/blog/another-path-to-the-same-summit.html" => "blog/inna-sciezka-na-ten-sam-szczyt.html",
        "en/blog/ikigai-the-reason-to-return-to-practice.html" => "blog/ikigai-sens-regularnej-praktyki.html",
        "en/blog/misogi-purification-through-practice.html" => "blog/misogi-oczyszczenie-przez-praktyke.html",
        "en/blog/five-principles-behind-every-technique.html" => "blog/5-zasad-kazdej-techniki.html",
        "en/blog/why-aikido-practitioners-wear-hakama.html" => "blog/dlaczego-w-aikido-nosi-sie-hakame.html",
        "en/blog/who-is-aikido-for.html" => "blog/dla-kogo-jest-aikido.html",
        "en/blog/is-aikido-worth-practicing.html" => "blog/czy-warto-cwiczyc-aikido.html",
        "en/blog/aikido-at-every-age.html" => "blog/aikido-w-kazdym-wieku.html",
        "en/blog/aikido-for-teenagers.html" => "blog/aikido-dla-nastolatkow.html",
        "en/blog/ichi-go-ichi-e-every-encounter-happens-only-once.html" => "blog/ichi-go-ichi-e-kazde-spotkanie-zdarza-sie-tylko-raz.html",
        "en/blog/one-teacher-one-transmission.html" => "blog/jeden-nauczyciel-jeden-przekaz.html",
        "en/blog/toyoda-aikido-style-technique-and-zen.html" => "blog/styl-aikido-fumio-toyody-technika-i-zen.html",
        "en/blog/toyoda-germanov-lineage-how-we-train.html" => "blog/linia-toyoda-germanov-jak-cwiczymy.html",
        "en/blog/omoiyari-considerate-compassion.html" => "blog/omoiyari-uwazna-troska.html",
        "en/blog/jiko-sekinin-personal-responsibility.html" => "blog/jiko-sekinin-odpowiedzialnosc-osobista.html",
        "en/blog/kuzushi-controlled-imbalance.html" => "blog/kuzushi-kontrolowana-nierownowaga.html",
        "en/blog/the-path-and-mastery.html" => "blog/droga-i-mistrzostwo.html",
      }.freeze

      def current_lang
        path = current_path.to_s
        path.start_with?("en/") ? "en" : "pl"
      end

      def alternate_lang
        current_lang == "pl" ? "en" : "pl"
      end

      def alternate_url
        path = current_path.to_s

        if (match = path.match(/\Ablog-(\d+)\.html\z/))
          return "#{site_url}/en/blog-#{match[1]}.html"
        end

        if (match = path.match(%r{\Aen/blog-(\d+)\.html\z}))
          return "#{site_url}/blog-#{match[1]}.html"
        end

        mapped = LANG_URL_MAP[path]
        return nil unless mapped

        url = "#{site_url}/#{mapped}"
        url = url.gsub(%r{(?<!:)/+}, "/")
        url.chomp("/")
      end

      def page_hreflang_tags
        alt_url = alternate_url
        return "" unless alt_url

        if current_lang == "pl"
          <<~HTML
            <link rel="alternate" hreflang="pl" href="#{canonical_url}" />
            <link rel="alternate" hreflang="en" href="#{alt_url}" />
            <link rel="alternate" hreflang="x-default" href="#{canonical_url}" />
          HTML
        else
          <<~HTML
            <link rel="alternate" hreflang="en" href="#{canonical_url}" />
            <link rel="alternate" hreflang="pl" href="#{alt_url}" />
            <link rel="alternate" hreflang="x-default" href="#{alt_url}" />
          HTML
        end
      end

      def asset_path(path)
        if URI(path).absolute?
          path
        else
          assets[path]
        end
      end

      def asset_path_with_version(path)
        "#{asset_path(path)}?v=#{asset_version(path)}"
      end

      # Content-derived version: stable across builds and machines, so the
      # generated site is byte-identical between builds (a timestamp-based
      # version made every build differ and churned gh-pages commits).
      def asset_version(path)
        asset_file = File.join(root || Site::Container.root, "assets", path.sub(%r{\A/}, ""))
        return "1" unless File.file?(asset_file)

        Digest::MD5.file(asset_file).hexdigest[0, 10]
      end

      def new(**new_options)
        dup.tap do |ctx|
          new_options.each do |key, value|
            ctx.instance_variable_set(:"@#{key}", value)
          end
        end
      end

      def article_schema(name:, description:, image:, lang: "pl", date_published: "2024-01-01", date_modified: "2024-01-01")
        jsonld = {
          "@context" => "https://schema.org",
          "@type" => "Article",
          "headline" => name,
          "description" => description,
          "image" => image,
          "url" => canonical_url,
          "inLanguage" => lang == "pl" ? "pl-PL" : "en-US",
          "author" => {
            "@type" => "Organization",
            "name" => "Polska Organizacja Aikido",
            "url" => site_url
          },
          "publisher" => {
            "@type" => "Organization",
            "name" => site_name,
            "logo" => {
              "@type" => "ImageObject",
              "url" => "#{site_url}#{asset_path('images/toyoda.svg')}"
            }
          },
          "datePublished" => date_published,
          "dateModified" => date_modified
        }.to_json

        <<~HTML
          <script type="application/ld+json">
          #{jsonld}
          </script>
        HTML
      end

      def event_schema(name:, start_date:, end_date: nil, location:, description:, image:, lang: "pl")
        end_date ||= start_date
        jsonld = {
          "@context" => "https://schema.org",
          "@type" => "Event",
          "name" => name,
          "description" => description,
          "image" => image,
          "url" => canonical_url,
          "startDate" => start_date,
          "endDate" => end_date,
          "inLanguage" => lang == "pl" ? "pl-PL" : "en-US",
          "location" => {
            "@type" => "Place",
            "name" => location[:name],
            "address" => {
              "@type" => "PostalAddress",
              "streetAddress" => location[:street],
              "addressLocality" => location[:city],
              "addressCountry" => location[:country] || "PL"
            }
          },
          "organizer" => {
            "@type" => "Organization",
            "name" => site_name,
            "url" => site_url
          }
        }.to_json

        <<~HTML
          <script type="application/ld+json">
          #{jsonld}
          </script>
        HTML
      end

      def faq_schema(questions)
        jsonld = {
          "@context" => "https://schema.org",
          "@type" => "FAQPage",
          "mainEntity" => questions.map do |q|
            {
              "@type" => "Question",
              "name" => q[:question],
              "acceptedAnswer" => {
                "@type" => "Answer",
                "text" => q[:answer]
              }
            }
          end
        }.to_json

        <<~HTML
          <script type="application/ld+json">
          #{jsonld}
          </script>
        HTML
      end

      def breadcrumb_schema(items)
        item_list = items.map.with_index do |item, index|
          {
            "@type" => "ListItem",
            "position" => index + 1,
            "name" => item[:name],
            "item" => item[:url]
          }
        end

        jsonld = {
          "@context" => "https://schema.org",
          "@type" => "BreadcrumbList",
          "itemListElement" => item_list
        }.to_json

        <<~HTML
          <script type="application/ld+json">
          #{jsonld}
          </script>
        HTML
      end
    end
  end
end
