(function() {
  'use strict';

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
        behavior: 'smooth'
      });
    }

    window.addEventListener('scroll', toggleVisibility, { passive: true });
    button.addEventListener('click', scrollToTop);
    toggleVisibility();
  }

  function initFadeInAnimations() {
    const animatedElements = document.querySelectorAll(
      '.fade-in-section, .fade-in-left, .fade-in-right, .content h2, .principle-card, .exercise-card, .beginner-card, .step'
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
    const images = document.querySelectorAll('img:not([loading])');
    
    if ('loading' in HTMLImageElement.prototype) {
      images.forEach(img => {
        img.setAttribute('loading', 'lazy');
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
            <img src="${post.img}" alt="Instagram post - ${post.caption}" loading="lazy">
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
        
        const targetElement = document.querySelector(targetId);
        if (targetElement) {
          e.preventDefault();
          targetElement.scrollIntoView({
            behavior: 'smooth',
            block: 'start'
          });
        }
      });
    });
  }

  function initHeaderAutoHide() {
    const nav = document.querySelector('nav');
    if (!nav) return;

    let lastScrollTop = 0;
    const headerHeight = nav.offsetHeight;

    function handleScroll() {
      const scrollTop = window.scrollY || document.documentElement.scrollTop;
      
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
    nav.style.transition = 'transform 0.3s ease';
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
  }

  init();
})();
