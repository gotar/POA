(function() {
  'use strict';

  function getScrollBehavior() {
    return typeof window.matchMedia === 'function' &&
      window.matchMedia('(prefers-reduced-motion: reduce)').matches
      ? 'auto'
      : 'smooth';
  }

  function getReducedMotionScrollOptions() {
    return getScrollBehavior() === 'auto' ? { behavior: 'auto' } : {};
  }

  function initScrollProgress() {
    const progressBar = document.querySelector('.scroll-progress-bar');
    if (!progressBar) return;

    function updateProgress() {
      const scrollTop = window.scrollY || document.documentElement.scrollTop;
      const docHeight = document.documentElement.scrollHeight - document.documentElement.clientHeight;
      const progress = docHeight > 0 ? (scrollTop / docHeight) * 100 : 0;
      progressBar.style.width = progress + '%';
    }

    window.addEventListener('scroll', updateProgress, { passive: true });
    updateProgress();
  }

  function initBackToTop() {
    const button = document.querySelector('.back-to-top');
    if (!button) return;

    function toggleVisibility() {
      const scrollTop = window.scrollY || document.documentElement.scrollTop;
      if (scrollTop > 300) {
        button.classList.add('visible');
      } else {
        button.classList.remove('visible');
      }
    }

    function scrollToTop() {
      window.scrollTo({
        top: 0,
        behavior: getScrollBehavior()
      });
    }

    window.addEventListener('scroll', toggleVisibility, { passive: true });
    button.addEventListener('click', scrollToTop);
    toggleVisibility();
  }

  function initFadeInAnimations() {
    // UIUX-15: animowane były też nagłówki prozy i karty (content h2,
    // principle-card, exercise-card, beginner-card, step) — chwilowo
    // niewidoczne przy zrzucie. Dziś fade/slide tylko dla jawnych klas
    // .fade-in-* w szablonach; proza zawsze widoczna, także bez JS.
    const animatedElements = document.querySelectorAll(
      '.fade-in-section, .fade-in-left, .fade-in-right'
    );
    
    if (animatedElements.length === 0) return;

    const observerOptions = {
      root: null,
      rootMargin: '0px 0px -50px 0px',
      threshold: 0.1
    };

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
          observer.unobserve(entry.target);
        }
      });
    }, observerOptions);

    animatedElements.forEach((el, index) => {
      if (!el.classList.contains('fade-in-section') && 
          !el.classList.contains('fade-in-left') && 
          !el.classList.contains('fade-in-right')) {
        el.classList.add('fade-in-section');
      }
      el.style.transitionDelay = (index % 5) * 0.1 + 's';
      observer.observe(el);
    });
  }

  function initLazyLoading() {
    // UIUX-15: logos/hero (fetchpriority="high") nigdy nie lazy-loadowane —
    // krytyczne zasoby wczytują się od razu; lazy tylko poniżej fold.
    const images = document.querySelectorAll('img:not([loading]):not([fetchpriority])');
    
    if ('loading' in HTMLImageElement.prototype) {
      images.forEach(img => {
        img.setAttribute('loading', 'lazy');
        img.setAttribute('decoding', 'async');
        img.classList.add('lazy-image');
        
        img.addEventListener('load', function() {
          this.classList.add('loaded');
        });
        
        if (img.complete) {
          img.classList.add('loaded');
        }
      });
    } else {
      const imageObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            const img = entry.target;
            img.classList.add('lazy-image');
            
            if (img.dataset.src) {
              img.src = img.dataset.src;
              img.removeAttribute('data-src');
            }
            
            img.addEventListener('load', function() {
              this.classList.add('loaded');
            });
            
            observer.unobserve(img);
          }
        });
      }, {
        rootMargin: '50px'
      });

      images.forEach(img => {
        imageObserver.observe(img);
      });
    }
  }

  function initInstagramWidget() {
    const widgets = document.querySelectorAll('.instagram-widget');
    if (widgets.length === 0) return;

    const instagramPosts = [
      {
        url: 'https://www.instagram.com/sesshinkan_aikido/',
        img: '/assets/favicons/android-chrome-192x192.png',
        caption: 'Trening w dojo Sesshinkan Aikido Gdynia'
      },
      {
        url: 'https://www.instagram.com/sesshinkan_aikido/',
        img: '/assets/favicons/android-chrome-192x192.png',
        caption: 'Seminarium Aikido z sensei'
      },
      {
        url: 'https://www.instagram.com/sesshinkan_aikido/',
        img: '/assets/favicons/android-chrome-192x192.png',
        caption: 'Praktyka Aikido w naszym dojo'
      }
    ];

    function getRandomPost() {
      const randomIndex = Math.floor(Math.random() * instagramPosts.length);
      return instagramPosts[randomIndex];
    }

    widgets.forEach(widget => {
      const container = widget.querySelector('.instagram-widget-content');
      if (!container) return;

      const post = getRandomPost();
      
      const postHTML = `
        <div class="instagram-widget-image">
          <a href="${post.url}" target="_blank" rel="noopener noreferrer">
            <img src="${post.img}" alt="Instagram post - ${post.caption}" loading="lazy" decoding="async">
          </a>
        </div>
        <p class="instagram-widget-caption">${post.caption}</p>
        <a href="https://www.instagram.com/sesshinkan_aikido/" target="_blank" rel="noopener noreferrer" class="instagram-widget-follow">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="vertical-align: middle; margin-right: 0.5rem;">
            <rect x="2" y="2" width="20" height="20" rx="5" ry="5"></rect>
            <path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"></path>
            <line x1="17.5" y1="6.5" x2="17.51" y2="6.5"></line>
          </svg>
          Obserwuj nas na Instagramie
        </a>
      `;
      
      container.innerHTML = postHTML;
      container.classList.remove('instagram-widget-loading');
    });
  }

  function initSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
      anchor.addEventListener('click', function(e) {
        const targetId = this.getAttribute('href');
        if (targetId === '#') return;
        
        // getElementById: ids like 7kyu are valid HTML but not valid
        // CSS selectors, so querySelector would throw on grade links.
        const targetElement = document.getElementById(targetId.slice(1));
        if (targetElement) {
          e.preventDefault();
          if (targetId === '#main-content') {
            targetElement.focus({ preventScroll: true });
          }
          targetElement.scrollIntoView({
            behavior: 'smooth',
            block: 'start',
            ...getReducedMotionScrollOptions()
          });
        }
      });
    });
  }

  function initHeaderAutoHide() {
    const nav = document.querySelector('nav');
    if (!nav) return;

    // UIUX-15: przy prefers-reduced-motion auto-hide jest wyłączony —
    // nagłówek nigdy nie znika (bez „flash" ukrytego tekstu i bez animacji).
    if (typeof window.matchMedia === 'function' &&
        window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      return;
    }

    let lastScrollTop = 0;
    const headerHeight = nav.offsetHeight;

    function menuOrFocusActive() {
      return nav.querySelector('.nav-toggle[aria-expanded="true"]') !== null ||
        nav.querySelector('.dropdown-label[aria-expanded="true"]') !== null ||
        nav.contains(document.activeElement);
    }

    function handleScroll() {
      const scrollTop = window.scrollY || document.documentElement.scrollTop;

      // Never auto-hide while a menu is open or focus sits inside the header:
      // scrolling a long open menu must not hide it mid-interaction.
      if (menuOrFocusActive()) {
        nav.style.transform = 'translateY(0)';
        lastScrollTop = scrollTop;
        return;
      }
            
      if (scrollTop > headerHeight) {
        if (scrollTop > lastScrollTop) {
          nav.style.transform = 'translateY(-100%)';
        } else {
          nav.style.transform = 'translateY(0)';
        }
      } else {
        nav.style.transform = 'translateY(0)';
      }
      
      lastScrollTop = scrollTop;
    }

    window.addEventListener('scroll', handleScroll, { passive: true });
  }

  function initDropdownNavigation() {
    const dropdowns = Array.from(document.querySelectorAll('.dropdown')).map(dropdown => {
      const toggle = dropdown.querySelector('.dropdown-label[aria-controls]');
      const menu = toggle && document.getElementById(toggle.getAttribute('aria-controls'));

      return toggle && menu ? { dropdown, toggle } : null;
    }).filter(Boolean);

    if (dropdowns.length === 0) return;

    function setExpanded(toggle, expanded) {
      toggle.setAttribute('aria-expanded', String(expanded));
    }

    function closeAll(except = null) {
      dropdowns.forEach(({ toggle }) => {
        if (toggle !== except) setExpanded(toggle, false);
      });
    }

    dropdowns.forEach(({ dropdown, toggle }) => {
      dropdown.dataset.dropdownReady = 'true';

      toggle.addEventListener('click', function() {
        const expanded = toggle.getAttribute('aria-expanded') !== 'true';
        closeAll(toggle);
        setExpanded(toggle, expanded);
      });

      dropdown.addEventListener('focusout', function(event) {
        if (!dropdown.contains(event.relatedTarget)) setExpanded(toggle, false);
      });
    });

    document.addEventListener('click', function(event) {
      if (!event.target.closest('.dropdown')) closeAll();
    });

    document.addEventListener('keydown', function(event) {
      if (event.key !== 'Escape') return;

      const openDropdowns = dropdowns.filter(({ toggle }) =>
        toggle.getAttribute('aria-expanded') === 'true'
      );

      if (openDropdowns.length === 0) return;

      // Close only the innermost layer: keep the outer mobile menu open so a
      // second Escape can close it and return focus to the hamburger.
      // (Only truly open menus count: mere focus inside a closed dropdown
      // must not swallow the Escape meant for the mobile menu.)
      const activeDropdown = openDropdowns.find(({ dropdown }) =>
        dropdown.contains(document.activeElement)
      ) || openDropdowns[0];

      closeAll();
      setExpanded(activeDropdown.toggle, false);
      activeDropdown.toggle.focus();
      event.stopImmediatePropagation();
    });

    // A breakpoint change resets dropdown state so no stale open menu
    // survives a mobile <-> desktop transition.
    const desktopViewport = window.matchMedia('(min-width: 769px)');
    function resetDropdownsOnBreakpointChange() {
      closeAll();
    }
    if (desktopViewport.addEventListener) {
      desktopViewport.addEventListener('change', resetDropdownsOnBreakpointChange);
    } else {
      desktopViewport.addListener(resetDropdownsOnBreakpointChange);
    }
  }

  function initMobileNavigation() {
    const toggle = document.querySelector('.nav-toggle');
    if (!toggle) return;

    const menu = document.getElementById(toggle.getAttribute('aria-controls'));
    if (!menu) return;

    menu.dataset.mobileMenuReady = 'true';
    toggle.hidden = false;

    const openLabel = toggle.dataset.openLabel;
    const closeLabel = toggle.dataset.closeLabel;

    function setExpanded(expanded, restoreFocus = false) {
      toggle.setAttribute('aria-expanded', String(expanded));
      toggle.setAttribute('aria-label', expanded ? closeLabel : openLabel);

      if (restoreFocus) toggle.focus();
    }

    // Native buttons already support Enter and Space; do not rebuild that
    // behavior with brittle custom keyboard handlers.
    toggle.addEventListener('click', function() {
      setExpanded(toggle.getAttribute('aria-expanded') !== 'true');
    });

    document.addEventListener('keydown', function(event) {
      if (event.key === 'Escape' && toggle.getAttribute('aria-expanded') === 'true') {
        setExpanded(false, true);
      }
    });

    // A tap outside the header closes the open mobile menu.
    document.addEventListener('click', function(event) {
      if (toggle.getAttribute('aria-expanded') !== 'true') return;
      if (!event.target.closest('nav')) setExpanded(false);
    });

    // Activating a link inside the menu closes it (matters for same-page anchors).
    menu.addEventListener('click', function(event) {
      if (event.target.closest('a')) setExpanded(false);
    });

    function closeOnDesktop(event) {
      if (!event.matches) setExpanded(false);
    }

    const mobileViewport = window.matchMedia('(max-width: 768px)');
    if (mobileViewport.addEventListener) {
      mobileViewport.addEventListener('change', closeOnDesktop);
    } else {
      mobileViewport.addListener(closeOnDesktop);
    }
  }

  // UIUX-06: blog reader TOC. The TOC is a native <details> rendered
  // server-side, so content and links work without JS. This only
  // enhances: open the disclosure on desktop widths (closed on
  // mobile), keep the URL hash in sync when smooth scrolling (so
  // back/forward and deep links keep working), and move keyboard
  // focus to the target heading. Never hides content on failure.
  function initBlogToc() {
    const tocLinks = document.querySelectorAll('.toc a[href^="#"]');
    const tocDisclosure = document.querySelector('details.toc');
    if (tocLinks.length === 0 || !tocDisclosure) return;

    const desktopViewport = window.matchMedia('(min-width: 769px)');
    let userToggled = false;
    tocDisclosure.addEventListener('toggle', function() {
      userToggled = true;
    });

    function applyDisclosureState() {
      if (userToggled) return;
      if (desktopViewport.matches) {
        tocDisclosure.open = true;
      } else {
        tocDisclosure.open = false;
      }
    }
    applyDisclosureState();
    if (desktopViewport.addEventListener) {
      desktopViewport.addEventListener('change', function() {
        userToggled = false;
        applyDisclosureState();
      });
    }

    tocLinks.forEach(function(link) {
      link.addEventListener('click', function() {
        const targetId = link.getAttribute('href');
        if (!targetId || targetId === '#') return;
        const target = document.querySelector(targetId);
        if (!target) return;
        try {
          history.pushState(null, '', targetId);
        } catch (err) { /* file:// or sandboxed preview: hash sync is best-effort */ }
        if (typeof target.focus === 'function') {
          target.focus({ preventScroll: true });
        }
      });
    });
  }

  // UIUX-08: blog discovery. Progressive enhancement over the
  // server-rendered index (which stays intact for no-JS): builds a
  // search + category filter over the WHOLE catalog (embedded
  // #blog-index JSON, every pagination page), syncs ?q=&cat= to the
  // URL (reload/back/forward restore), announces the result count
  // via aria-live, and renders cards with DOM APIs only (textContent
  // everywhere, so user queries and metadata can never inject HTML).
  // Only the results region re-renders, so the search input never
  // loses focus while typing.
  var BLOG_DISCOVERY_STRINGS = {
    pl: {
      sectionLabel: 'Wyszukiwanie i filtry bloga',
      searchLabel: 'Szukaj wpisów',
      searchPlaceholder: 'np. hakama, oddech, kuzushi…',
      searchHelp: 'Wyszukiwarka przeszukuje tytuły i opisy wszystkich wpisów.',
      categoryLabel: 'Filtruj po kategorii',
      allCategories: 'Wszystkie',
      reset: 'Wyczyść',
      emptyTitle: 'Brak wyników.',
      emptyHint: 'Zmień zapytanie albo wyczyść wyszukiwanie i filtry.',
      readMore: 'Czytaj więcej →',
      readMorePrefix: 'Czytaj więcej',
      resultsCount: function(n) {
        if (n === 1) return '1 wynik';
        var mod10 = n % 10, mod100 = n % 100;
        if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return n + ' wyniki';
        return n + ' wyników';
      }
    },
    en: {
      sectionLabel: 'Blog search and filters',
      searchLabel: 'Search posts',
      searchPlaceholder: 'e.g. hakama, breath, kuzushi…',
      searchHelp: 'Search covers titles and summaries of all posts.',
      categoryLabel: 'Filter by category',
      allCategories: 'All',
      reset: 'Clear',
      emptyTitle: 'No results.',
      emptyHint: 'Change your query or clear search and filters.',
      readMore: 'Read more →',
      readMorePrefix: 'Read more',
      resultsCount: function(n) {
        return n === 1 ? '1 result' : n + ' results';
      }
    }
  };

  // Case/diacritics folding for PL/EN. Mirrors the Ruby contract
  // Context#blog_fold_text (pinned in test/blog_discovery_test.rb):
  // lowercase, explicit PL mapping (ł has no NFD decomposition),
  // then strip combining marks. No locale lowercasing surprises:
  // toLowerCase is stable for the PL/EN alphabet.
  function blogFoldText(value) {
    var s = String(value == null ? '' : value).toLowerCase();
    s = s.replace(/ą/g, 'a').replace(/ć/g, 'c').replace(/ę/g, 'e')
      .replace(/ł/g, 'l').replace(/ń/g, 'n').replace(/ó/g, 'o')
      .replace(/ś/g, 's').replace(/ź/g, 'z').replace(/ż/g, 'z');
    if (typeof s.normalize === 'function') {
      s = s.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
    }
    return s;
  }

  function initBlogDiscovery() {
    var indexEl = document.getElementById('blog-index');
    var article = indexEl && indexEl.closest('.article');
    var serverList = article && article.querySelector('.news-list');
    if (!indexEl || !article || !serverList) return;

    var lang = indexEl.getAttribute('data-lang') === 'en' ? 'en' : 'pl';
    var strings = BLOG_DISCOVERY_STRINGS[lang];

    var catalog;
    try {
      catalog = JSON.parse(indexEl.textContent || '[]');
    } catch (err) {
      return;
    }
    if (!Array.isArray(catalog) || catalog.length === 0) return;

    var pagination = article.querySelector('nav.pagination');
    var startHere = article.querySelector('.blog-start-here');

    // Build the discovery section before the server list.
    var section = document.createElement('section');
    section.className = 'blog-discovery';
    section.setAttribute('aria-label', strings.sectionLabel);

    var form = document.createElement('form');
    form.className = 'blog-search-form';
    form.setAttribute('role', 'search');
    form.setAttribute('method', 'get');
    form.setAttribute('action', window.location.pathname);

    var label = document.createElement('label');
    label.setAttribute('for', 'blog-search');
    label.textContent = strings.searchLabel;

    var input = document.createElement('input');
    input.setAttribute('type', 'search');
    input.setAttribute('id', 'blog-search');
    input.setAttribute('name', 'q');
    input.setAttribute('autocomplete', 'off');
    input.setAttribute('placeholder', strings.searchPlaceholder);

    var help = document.createElement('p');
    help.className = 'blog-search-help';
    help.textContent = strings.searchHelp;

    form.appendChild(label);
    form.appendChild(input);
    form.appendChild(help);

    var pillsWrap = document.createElement('div');
    pillsWrap.className = 'blog-categories';
    pillsWrap.setAttribute('role', 'group');
    pillsWrap.setAttribute('aria-label', strings.categoryLabel);

    // Category pills in first-appearance order (catalog order).
    var seenCats = [];
    catalog.forEach(function(post) {
      if (post && post.category && seenCats.indexOf(post.category) === -1) {
        seenCats.push(post.category);
      }
    });

    function pillLabel(cat) {
      if (cat === 'all') return strings.allCategories;
      for (var i = 0; i < catalog.length; i++) {
        if (catalog[i] && catalog[i].category === cat) return catalog[i].category_label || cat;
      }
      return cat;
    }

    var pillButtons = {};
    ['all'].concat(seenCats).forEach(function(cat) {
      var pill = document.createElement('button');
      pill.setAttribute('type', 'button');
      pill.className = 'blog-category-pill';
      pill.setAttribute('data-cat', cat);
      pill.setAttribute('aria-pressed', cat === 'all' ? 'true' : 'false');
      pill.textContent = pillLabel(cat);
      pill.addEventListener('click', function() {
        applyState({ q: input.value, cat: cat }, 'push');
        input.focus();
      });
      pillButtons[cat] = pill;
      pillsWrap.appendChild(pill);
    });

    var statusWrap = document.createElement('div');
    statusWrap.className = 'blog-discovery-status';

    var count = document.createElement('p');
    count.className = 'blog-result-count';
    count.setAttribute('role', 'status');
    count.setAttribute('aria-live', 'polite');

    var reset = document.createElement('button');
    reset.setAttribute('type', 'button');
    reset.className = 'blog-reset';
    reset.textContent = strings.reset;
    reset.hidden = true;
    reset.addEventListener('click', function() {
      applyState({ q: '', cat: 'all' }, 'push');
      input.focus();
    });

    statusWrap.appendChild(count);
    statusWrap.appendChild(reset);

    var results = document.createElement('div');
    results.className = 'blog-results';
    results.hidden = true;

    var resultsList = document.createElement('div');
    resultsList.className = 'news-list blog-results-list';

    var empty = document.createElement('div');
    empty.className = 'blog-empty';
    empty.hidden = true;
    var emptyTitle = document.createElement('p');
    emptyTitle.className = 'blog-empty-title';
    emptyTitle.textContent = strings.emptyTitle;
    var emptyHint = document.createElement('p');
    emptyHint.textContent = strings.emptyHint;
    empty.appendChild(emptyTitle);
    empty.appendChild(emptyHint);

    results.appendChild(resultsList);
    results.appendChild(empty);

    section.appendChild(form);
    section.appendChild(pillsWrap);
    section.appendChild(statusWrap);
    section.appendChild(results);
    article.insertBefore(section, serverList);

    function findPosts(q, cat) {
      var folded = blogFoldText(q).replace(/^\s+|\s+$/g, '');
      return catalog.filter(function(post) {
        if (!post) return false;
        if (cat && cat !== 'all' && String(post.category) !== cat) return false;
        if (!folded) return true;
        return blogFoldText(post.title + ' ' + post.summary).indexOf(folded) !== -1;
      });
    }

    function buildCard(post) {
      var card = document.createElement('article');
      card.className = 'news-card';

      var meta = document.createElement('div');
      meta.className = 'news-meta';
      meta.textContent = post.date || '';

      var cat = document.createElement('p');
      cat.className = 'news-category';
      cat.textContent = post.category_label || '';

      var heading = document.createElement('h2');
      var titleLink = document.createElement('a');
      titleLink.className = 'news-card-title';
      titleLink.setAttribute('href', post.url);
      titleLink.textContent = post.title;
      heading.appendChild(titleLink);

      var summary = document.createElement('p');
      summary.textContent = post.summary || '';

      var more = document.createElement('a');
      more.className = 'news-read-more';
      more.setAttribute('href', post.url);
      more.setAttribute('aria-label', strings.readMorePrefix + ': ' + post.title);
      more.textContent = strings.readMore;

      card.appendChild(meta);
      card.appendChild(cat);
      card.appendChild(heading);
      card.appendChild(summary);
      card.appendChild(more);
      return card;
    }

    function syncUrl(state, mode) {
      var url;
      try {
        url = new URL(window.location.href);
      } catch (err) {
        return;
      }
      var q = String(state.q || '').replace(/^\s+|\s+$/g, '');
      if (q) {
        url.searchParams.set('q', q);
      } else {
        url.searchParams.delete('q');
      }
      if (state.cat && state.cat !== 'all') {
        url.searchParams.set('cat', state.cat);
      } else {
        url.searchParams.delete('cat');
      }
      try {
        if (mode === 'push') {
          window.history.pushState({ blogDiscovery: true }, '', url);
        } else {
          window.history.replaceState({ blogDiscovery: true }, '', url);
        }
      } catch (err) { /* file:// or sandboxed preview: URL sync is best-effort */ }
    }

    function applyState(state, urlMode) {
      var q = String(state.q == null ? '' : state.q);
      var cat = state.cat && pillButtons[state.cat] ? state.cat : 'all';
      var active = blogFoldText(q).replace(/^\s+|\s+$/g, '') !== '' || cat !== 'all';

      // Never rewrite the input while the user is typing in it (that
      // would drop the caret); sync it on popstate/init, reset and
      // pill clicks originating outside the field.
      if (input.value !== q && (urlMode === 'none' || document.activeElement !== input)) {
        input.value = q;
      }

      Object.keys(pillButtons).forEach(function(key) {
        pillButtons[key].setAttribute('aria-pressed', key === cat ? 'true' : 'false');
      });

      // Clear previous results (DOM nodes only, no HTML strings:
      // user data stays text).
      while (resultsList.firstChild) resultsList.removeChild(resultsList.firstChild);

      if (!active) {
        serverList.hidden = false;
        if (pagination) pagination.hidden = false;
        if (startHere) startHere.hidden = false;
        results.hidden = true;
        empty.hidden = true;
        count.textContent = '';
        reset.hidden = true;
      } else {
        var matches = findPosts(q, cat);
        matches.forEach(function(post) {
          resultsList.appendChild(buildCard(post));
        });
        serverList.hidden = true;
        if (pagination) pagination.hidden = true;
        if (startHere) startHere.hidden = true;
        results.hidden = false;
        empty.hidden = matches.length !== 0;
        count.textContent = strings.resultsCount(matches.length);
        reset.hidden = false;
      }

      if (urlMode === 'push' || urlMode === 'replace') syncUrl({ q: q, cat: cat }, urlMode);
    }

    var debounceTimer = null;
    input.addEventListener('input', function() {
      if (debounceTimer) window.clearTimeout(debounceTimer);
      debounceTimer = window.setTimeout(function() {
        applyState({ q: input.value, cat: currentCat() }, 'replace');
      }, 120);
    });

    function currentCat() {
      var pressed = pillsWrap.querySelector('[aria-pressed="true"]');
      return pressed ? pressed.getAttribute('data-cat') : 'all';
    }

    form.addEventListener('submit', function(event) {
      event.preventDefault();
      applyState({ q: input.value, cat: currentCat() }, 'push');
    });

    window.addEventListener('popstate', function() {
      var params;
      try {
        params = new URL(window.location.href).searchParams;
      } catch (err) {
        return;
      }
      applyState({ q: params.get('q') || '', cat: params.get('cat') || 'all' }, 'none');
    });

    // Restore filter state after reload or deep link (?q=&cat=).
    try {
      var initial = new URL(window.location.href).searchParams;
      var initQ = initial.get('q') || '';
      var initCat = initial.get('cat') || 'all';
      if (initQ || (initCat && initCat !== 'all')) {
        applyState({ q: initQ, cat: initCat }, 'none');
      }
    } catch (err) { /* URL parsing unavailable: leave the server view */ }
  }

  // UIUX-12: glossary search. Progressive enhancement over the
  // server-rendered dictionary (which stays intact for no-JS): builds a
  // search form into [data-glossary-search-mount], filters the existing
  // table rows in place (no re-render, table semantics preserved),
  // hides fully-filtered sections only while a query is active, syncs
  // ?q= to the URL (reload/back/forward restore), announces the match
  // count via aria-live without moving focus, and builds no HTML
  // strings (textContent everywhere, the query is never echoed into
  // the DOM, so unknown input cannot inject markup).
  var GLOSSARY_SEARCH_STRINGS = {
    pl: {
      sectionLabel: 'Wyszukiwanie w słowniczku',
      searchLabel: 'Szukaj terminów',
      searchPlaceholder: 'np. ukemi, głowa, 合気道…',
      searchHelp: 'Wyszukiwarka przeszukuje terminy i opisy we wszystkich kategoriach.',
      reset: 'Wyczyść',
      emptyTitle: 'Brak wyników.',
      emptyHint: 'Zmień zapytanie albo wyczyść wyszukiwanie.',
      resultsCount: function(n) {
        if (n === 1) return '1 wynik';
        var mod10 = n % 10, mod100 = n % 100;
        if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return n + ' wyniki';
        return n + ' wyników';
      }
    },
    en: {
      sectionLabel: 'Glossary search',
      searchLabel: 'Search terms',
      searchPlaceholder: 'e.g. ukemi, head, 合気道…',
      searchHelp: 'Search covers terms and descriptions in every category.',
      reset: 'Clear',
      emptyTitle: 'No results.',
      emptyHint: 'Change your query or clear the search.',
      resultsCount: function(n) {
        return n === 1 ? '1 result' : n + ' results';
      }
    }
  };

  function initGlossarySearch() {
    var mount = document.querySelector('[data-glossary-search-mount]');
    if (!mount) return;
    var content = mount.closest('.content');
    var nav = content && content.querySelector('.glossary-categories');
    if (!content || !nav) return;

    var lang = document.documentElement.getAttribute('lang') === 'en' ? 'en' : 'pl';
    var strings = GLOSSARY_SEARCH_STRINGS[lang];

    // Pair each category anchor with its heading + section body.
    var sections = [];
    Array.prototype.forEach.call(nav.querySelectorAll('a[href^="#"]'), function(link) {
      var id = link.getAttribute('href').slice(1);
      var heading = id && content.querySelector('#' + id);
      var body = heading && heading.nextElementSibling;
      if (!heading || !body || !body.classList.contains('glossary-section')) return;
      var rows = [];
      Array.prototype.forEach.call(body.querySelectorAll('table tr'), function(row) {
        rows.push({ el: row, haystack: blogFoldText(row.textContent || '') });
      });
      sections.push({ heading: heading, body: body, rows: rows });
    });
    if (sections.length === 0) return;

    var section = document.createElement('section');
    section.className = 'glossary-search';
    section.setAttribute('aria-label', strings.sectionLabel);

    var form = document.createElement('form');
    form.className = 'glossary-search-form';
    form.setAttribute('role', 'search');
    form.setAttribute('method', 'get');
    form.setAttribute('action', window.location.pathname);

    var label = document.createElement('label');
    label.setAttribute('for', 'glossary-search');
    label.textContent = strings.searchLabel;

    var input = document.createElement('input');
    input.setAttribute('type', 'search');
    input.setAttribute('id', 'glossary-search');
    input.setAttribute('name', 'q');
    input.setAttribute('autocomplete', 'off');
    input.setAttribute('placeholder', strings.searchPlaceholder);

    var help = document.createElement('p');
    help.className = 'glossary-search-help';
    help.textContent = strings.searchHelp;

    form.appendChild(label);
    form.appendChild(input);
    form.appendChild(help);

    var statusWrap = document.createElement('div');
    statusWrap.className = 'glossary-search-status';

    var count = document.createElement('p');
    count.className = 'glossary-result-count';
    count.setAttribute('role', 'status');
    count.setAttribute('aria-live', 'polite');

    var reset = document.createElement('button');
    reset.setAttribute('type', 'button');
    reset.className = 'glossary-reset';
    reset.textContent = strings.reset;
    reset.hidden = true;
    reset.addEventListener('click', function() {
      applyState('', 'push');
      input.focus();
    });

    statusWrap.appendChild(count);
    statusWrap.appendChild(reset);

    var empty = document.createElement('div');
    empty.className = 'glossary-empty';
    empty.hidden = true;
    var emptyTitle = document.createElement('p');
    emptyTitle.className = 'glossary-empty-title';
    emptyTitle.textContent = strings.emptyTitle;
    var emptyHint = document.createElement('p');
    emptyHint.textContent = strings.emptyHint;
    empty.appendChild(emptyTitle);
    empty.appendChild(emptyHint);

    section.appendChild(form);
    section.appendChild(statusWrap);
    section.appendChild(empty);
    mount.appendChild(section);

    function syncUrl(q, mode) {
      var url;
      try {
        url = new URL(window.location.href);
      } catch (err) {
        return;
      }
      var trimmed = String(q || '').replace(/^\s+|\s+$/g, '');
      if (trimmed) {
        url.searchParams.set('q', trimmed);
      } else {
        url.searchParams.delete('q');
      }
      try {
        if (mode === 'push') {
          window.history.pushState({ glossarySearch: true }, '', url);
        } else {
          window.history.replaceState({ glossarySearch: true }, '', url);
        }
      } catch (err) { /* file:// or sandboxed preview: URL sync is best-effort */ }
    }

    function applyState(q, urlMode) {
      var raw = String(q == null ? '' : q);
      var folded = blogFoldText(raw).replace(/^\s+|\s+$/g, '');
      var active = folded !== '';

      // Never rewrite the input while the user is typing in it (that
      // would drop the caret); sync it on popstate/init and reset.
      if (input.value !== raw && (urlMode === 'none' || document.activeElement !== input)) {
        input.value = raw;
      }

      var matches = 0;
      sections.forEach(function(sec) {
        var visible = 0;
        sec.rows.forEach(function(row) {
          var show = !active || row.haystack.indexOf(folded) !== -1;
          row.el.hidden = !show;
          if (show) visible += 1;
        });
        // Empty sections hide only while a filter is active; the
        // full dictionary (with headings and illustrations) returns
        // untouched once the query is cleared.
        var hideSection = active && visible === 0;
        sec.heading.hidden = hideSection;
        sec.body.hidden = hideSection;
        matches += visible;
      });

      if (!active) {
        count.textContent = '';
        reset.hidden = true;
        empty.hidden = true;
      } else {
        count.textContent = strings.resultsCount(matches);
        reset.hidden = false;
        empty.hidden = matches !== 0;
      }

      if (urlMode === 'push' || urlMode === 'replace') syncUrl(raw, urlMode);
    }

    // A category shortcut while a filter is active first clears the
    // filter (synchronously, so the target section is visible again)
    // and then lets the native anchor jump proceed. Focus stays where
    // the user put it: no focus jump on filter changes.
    Array.prototype.forEach.call(nav.querySelectorAll('a[href^="#"]'), function(link) {
      link.addEventListener('click', function() {
        if (blogFoldText(input.value).replace(/^\s+|\s+$/g, '') !== '') {
          applyState('', 'replace');
        }
      });
    });

    var debounceTimer = null;
    input.addEventListener('input', function() {
      if (debounceTimer) window.clearTimeout(debounceTimer);
      debounceTimer = window.setTimeout(function() {
        applyState(input.value, 'replace');
      }, 120);
    });

    form.addEventListener('submit', function(event) {
      event.preventDefault();
      applyState(input.value, 'push');
    });

    window.addEventListener('popstate', function() {
      var params;
      try {
        params = new URL(window.location.href).searchParams;
      } catch (err) {
        return;
      }
      applyState(params.get('q') || '', 'none');
    });

    // Restore filter state after reload or deep link (?q=).
    try {
      var initial = new URL(window.location.href).searchParams.get('q') || '';
      if (initial) applyState(initial, 'none');
    } catch (err) { /* URL parsing unavailable: leave the server view */ }
  }

  // UIUX-13: FAQ + kyu quick navigation. The anchors are
  // server-rendered and the full content stays visible without JS, so
  // this only enhances: keep the URL hash in sync (deep links and
  // back/forward keep working), move keyboard focus to the jump
  // target, and mark the currently visible section link with
  // aria-current. Never hides content on failure.
  function initFaqKyuNav() {
    var navs = document.querySelectorAll('.faq-toc, .kyu-index');
    if (navs.length === 0) return;

    Array.prototype.forEach.call(navs, function(nav) {
      Array.prototype.forEach.call(nav.querySelectorAll('a[href^="#"]'), function(link) {
        link.addEventListener('click', function() {
          var targetId = link.getAttribute('href');
          if (!targetId || targetId === '#') return;
          // getElementById: ids like 7kyu are valid HTML but not valid
          // CSS selectors, so querySelector would throw on them.
          var target = document.getElementById(targetId.slice(1));
          if (!target) return;
          try {
            history.pushState(null, '', targetId);
          } catch (err) { /* file:// or sandboxed preview: hash sync is best-effort */ }
          if (typeof target.focus === 'function') {
            target.focus({ preventScroll: true });
          }
        });
      });
    });

    // Section spy: section-level links only (direct children), so the
    // mark always lands on a pill with its own background, never on a
    // plain nested question link.
    var pairs = [];
    Array.prototype.forEach.call(navs, function(nav) {
      Array.prototype.forEach.call(
        nav.querySelectorAll(':scope > ul > li > a[href^="#"]'),
        function(link) {
          var id = link.getAttribute('href');
          if (!id || id === '#') return;
          var target = document.getElementById(id.slice(1));
          if (target) pairs.push({ link: link, target: target });
        }
      );
    });
    if (pairs.length === 0 || typeof IntersectionObserver !== 'function') return;

    var current = null;
    var observer = new IntersectionObserver(function(entries) {
      entries.forEach(function(entry) {
        if (!entry.isIntersecting) return;
        var found = null;
        pairs.forEach(function(pair) {
          if (pair.target === entry.target) found = pair;
        });
        if (!found || current === found.link) return;
        if (current) current.removeAttribute('aria-current');
        found.link.setAttribute('aria-current', 'true');
        current = found.link;
      });
    }, { rootMargin: '-40% 0px -55% 0px' });
    pairs.forEach(function(pair) { observer.observe(pair.target); });
  }

  function init() {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', initAll);
    } else {
      initAll();
    }
  }

  function initAll() {
    initScrollProgress();
    initBackToTop();
    initFadeInAnimations();
    initLazyLoading();
    initInstagramWidget();
    initSmoothScroll();
    initHeaderAutoHide();
    initDropdownNavigation();
    initMobileNavigation();
    initBlogToc();
    initBlogDiscovery();
    initGlossarySearch();
    initFaqKyuNav();
  }

  init();
})();
