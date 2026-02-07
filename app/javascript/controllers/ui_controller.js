import { Controller } from "@hotwired/stimulus"

// Enhanced UI controller with accessibility and UX improvements
export default class extends Controller {
  static targets = ["loading", "content", "notification"]

  connect() {
    this.setupKeyboardShortcuts()
    this.setupAccessibility()
    this.setupPerformanceOptimizations()
  }

  // Loading states
  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove("hidden", "opacity-0")
      this.loadingTarget.classList.add("opacity-100")
    }
    if (this.hasContentTarget) {
      this.contentTarget.classList.add("opacity-50", "pointer-events-none", "transition-opacity", "duration-200")
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove("opacity-100")
      this.loadingTarget.classList.add("opacity-0")
      setTimeout(() => this.loadingTarget.classList.add("hidden"), 200)
    }
    if (this.hasContentTarget) {
      this.contentTarget.classList.remove("opacity-50", "pointer-events-none")
    }
  }

  // Keyboard shortcuts
  setupKeyboardShortcuts() {
    document.addEventListener("keydown", (e) => {
      // ESC to close panels
      if (e.key === "Escape") {
        this.closeAllPanels()
      }

      // Ctrl/Cmd + / for help (future feature)
      if ((e.ctrlKey || e.metaKey) && e.key === "/") {
        e.preventDefault()
        this.showKeyboardShortcuts()
      }
    })
  }

  // Accessibility setup
  setupAccessibility() {
    this.addSkipLinks()
    this.setupFocusManagement()
    this.setupAriaLiveRegions()
  }

  addSkipLinks() {
    // Skip to main content
    const skipLink = document.createElement("a")
    skipLink.href = "#main-content"
    skipLink.className = "sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 bg-purple-600 text-white px-4 py-2 rounded-md z-50 shadow-lg"
    skipLink.textContent = "Skip to main content"
    document.body.insertBefore(skipLink, document.body.firstChild)

    // Skip to navigation
    const navSkipLink = document.createElement("a")
    navSkipLink.href = "#navigation"
    navSkipLink.className = "sr-only focus:not-sr-only focus:absolute focus:top-16 focus:left-4 bg-purple-600 text-white px-4 py-2 rounded-md z-50 shadow-lg"
    navSkipLink.textContent = "Skip to navigation"
    document.body.insertBefore(navSkipLink, document.body.firstChild.nextSibling)
  }

  setupFocusManagement() {
    // Focus trap for modals
    document.addEventListener("turbo:frame-load", () => {
      this.manageFocusTrap()
    })

    // Focus management for dynamic content
    document.addEventListener("turbo:before-stream-render", () => {
      // Store current focus before turbo updates
      this.lastFocusedElement = document.activeElement
    })

    document.addEventListener("turbo:frame-load", () => {
      // Restore focus or move to logical next element
      if (this.lastFocusedElement && this.lastFocusedElement !== document.activeElement) {
        setTimeout(() => {
          if (this.lastFocusedElement.isConnected) {
            this.lastFocusedElement.focus()
          }
        }, 100)
      }
    })
  }

  setupAriaLiveRegions() {
    // Create live region for announcements
    const liveRegion = document.createElement("div")
    liveRegion.setAttribute("aria-live", "polite")
    liveRegion.setAttribute("aria-atomic", "true")
    liveRegion.className = "sr-only"
    liveRegion.id = "live-region"
    document.body.appendChild(liveRegion)
  }

  // Performance optimizations
  setupPerformanceOptimizations() {
    // Debounce scroll events
    this.setupScrollOptimization()

    // Image lazy loading
    this.setupLazyLoading()

    // Reduce motion for users who prefer it
    this.respectReducedMotion()
  }

  setupScrollOptimization() {
    let ticking = false
    document.addEventListener("scroll", () => {
      if (!ticking) {
        requestAnimationFrame(() => {
          this.handleScroll()
          ticking = false
        })
        ticking = true
      }
    })
  }

  setupLazyLoading() {
    const images = document.querySelectorAll('img[data-src]')
    const imageObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const img = entry.target
          img.src = img.dataset.src
          img.classList.remove("blur-sm")
          imageObserver.unobserve(img)
        }
      })
    })

    images.forEach(img => imageObserver.observe(img))
  }

  respectReducedMotion() {
    const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (prefersReducedMotion) {
      document.documentElement.style.setProperty("--transition-duration", "0s")
    }
  }

  // UI Methods
  closeAllPanels() {
    const panels = document.querySelectorAll('[data-panel-target="container"], [data-modal-target="container"]')
    panels.forEach(panel => {
      if (!panel.classList.contains("hidden")) {
        const closeButton = panel.querySelector('[data-action*="close"], [data-action*="hide"]')
        if (closeButton) closeButton.click()
      }
    })
  }

  showKeyboardShortcuts() {
    // Future: Show keyboard shortcuts modal
    this.announce("Keyboard shortcuts help will be available soon")
  }

  manageFocusTrap() {
    const modal = document.querySelector('[role="dialog"], [data-modal-target="container"]:not(.hidden)')
    if (!modal) return

    const focusableElements = modal.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )

    if (focusableElements.length === 0) return

    const firstFocusable = focusableElements[0]
    const lastFocusable = focusableElements[focusableElements.length - 1]

    const handleTab = (e) => {
      if (e.key !== "Tab") return

      if (e.shiftKey) {
        if (document.activeElement === firstFocusable) {
          lastFocusable.focus()
          e.preventDefault()
        }
      } else {
        if (document.activeElement === lastFocusable) {
          firstFocusable.focus()
          e.preventDefault()
        }
      }
    }

    modal.addEventListener("keydown", handleTab)

    // Focus first element
    setTimeout(() => firstFocusable.focus(), 100)

    // Cleanup when modal closes
    const observer = new MutationObserver(() => {
      if (modal.classList.contains("hidden") || !modal.isConnected) {
        modal.removeEventListener("keydown", handleTab)
        observer.disconnect()
      }
    })
    observer.observe(modal, { attributes: true, attributeFilter: ["class"] })
  }

  // Animation utilities
  fadeIn(element, duration = 300) {
    element.classList.remove("hidden", "opacity-0")
    element.classList.add("opacity-100", "transition-opacity")
    element.style.transitionDuration = `${duration}ms`
  }

  fadeOut(element, duration = 300) {
    element.classList.remove("opacity-100")
    element.classList.add("opacity-0")
    element.style.transitionDuration = `${duration}ms`
    setTimeout(() => element.classList.add("hidden"), duration)
  }

  slideDown(element, duration = 300) {
    element.classList.remove("hidden")
    const height = element.scrollHeight
    element.style.maxHeight = "0px"
    element.style.overflow = "hidden"
    element.style.transition = `max-height ${duration}ms ease-out`

    requestAnimationFrame(() => {
      element.style.maxHeight = `${height}px`
    })

    setTimeout(() => {
      element.style.maxHeight = ""
      element.style.overflow = ""
      element.style.transition = ""
    }, duration)
  }

  slideUp(element, duration = 300) {
    element.style.maxHeight = `${element.scrollHeight}px`
    element.style.overflow = "hidden"
    element.style.transition = `max-height ${duration}ms ease-out`

    requestAnimationFrame(() => {
      element.style.maxHeight = "0px"
    })

    setTimeout(() => {
      element.classList.add("hidden")
      element.style.maxHeight = ""
      element.style.overflow = ""
      element.style.transition = ""
    }, duration)
  }

  // Notification system
  showNotification(message, type = "info", duration = 5000) {
    const notification = document.createElement("div")
    notification.className = `fixed top-4 right-4 z-50 p-4 rounded-lg shadow-lg max-w-sm ${
      type === "success" ? "bg-green-500" :
      type === "error" ? "bg-red-500" :
      type === "warning" ? "bg-yellow-500" : "bg-blue-500"
    } text-white transform translate-x-full transition-transform duration-300`

    notification.innerHTML = `
      <div class="flex items-center justify-between">
        <span>${message}</span>
        <button class="ml-4 text-white hover:text-gray-200" onclick="this.parentElement.parentElement.remove()">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      </div>
    `

    document.body.appendChild(notification)

    // Animate in
    setTimeout(() => notification.classList.remove("translate-x-full"), 100)

    // Auto remove
    if (duration > 0) {
      setTimeout(() => {
        notification.classList.add("translate-x-full")
        setTimeout(() => notification.remove(), 300)
      }, duration)
    }
  }

  announce(message) {
    const liveRegion = document.getElementById("live-region") || document.createElement("div")
    if (!liveRegion.id) {
      liveRegion.id = "live-region"
      liveRegion.setAttribute("aria-live", "polite")
      liveRegion.className = "sr-only"
      document.body.appendChild(liveRegion)
    }
    liveRegion.textContent = message
  }

  handleScroll() {
    // Throttle scroll-based features
    const scrolled = window.pageYOffset
    const rate = scrolled * -0.5

    // Parallax effect for hero sections (if any)
    const parallaxElements = document.querySelectorAll('[data-parallax]')
    parallaxElements.forEach(element => {
      element.style.transform = `translate3d(0, ${rate}px, 0)`
    })
  }

  // Theme switching (future enhancement)
  toggleTheme() {
    const html = document.documentElement
    const currentTheme = html.getAttribute("data-theme")
    const newTheme = currentTheme === "dark" ? "light" : "dark"

    html.setAttribute("data-theme", newTheme)
    localStorage.setItem("theme", newTheme)
    this.announce(`Switched to ${newTheme} theme`)
  }
}