import { Controller } from "@hotwired/stimulus"
import Prism from "prismjs"

// Import core Prism CSS
import "prismjs/themes/prism.css"

// Import common languages
import "prismjs/components/prism-javascript"
import "prismjs/components/prism-ruby"
import "prismjs/components/prism-python"
import "prismjs/components/prism-sql"
import "prismjs/components/prism-json"
import "prismjs/components/prism-markup" // XML/HTML
import "prismjs/components/prism-css"
import "prismjs/components/prism-bash"
import "prismjs/components/prism-yaml"

// Syntax highlighting for code blocks
export default class extends Controller {
  connect() {
    // Wait a bit for content to load, then highlight
    setTimeout(() => {
      this.highlightCodeBlocks()
    }, 100)

    // Also highlight on turbo frame loads
    document.addEventListener('turbo:frame-load', () => {
      setTimeout(() => {
        this.highlightCodeBlocks()
      }, 50)
    })
  }

  highlightCodeBlocks() {
    // Check if Prism is available
    if (typeof Prism === 'undefined') {
      console.warn('Prism.js not available, skipping syntax highlighting')
      return
    }

    try {
      // Find all code blocks that haven't been highlighted yet
      const codeBlocks = this.element.querySelectorAll('pre code:not(.language-markup):not(.language-none)')

      codeBlocks.forEach((block) => {
        // Only highlight if not already highlighted
        if (!block.classList.contains('highlighted')) {
          Prism.highlightElement(block)
          block.classList.add('highlighted')
        }
      })
    } catch (error) {
      console.warn('Syntax highlighting failed:', error)
    }
  }
}