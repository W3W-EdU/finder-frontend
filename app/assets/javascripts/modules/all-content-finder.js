window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  'use strict'

  // Enhances the all content finder with dynamic behaviour and analytics tracking
  class AllContentFinder {
    constructor (module) {
      this.module = module

      this.$form = module.querySelector('.js-all-content-finder-form')
      this.$taxonomySelect = module.querySelector('.js-all-content-finder-taxonomy-select')
    }

    init () {
      this.setupTaxonomySelect()

      if (this.userHasConsentedToAnalytics()) {
        this.setupGa4FinderTracker()
      }
    }

    userHasConsentedToAnalytics () {
      return GOVUK.getConsentCookie() && GOVUK.getConsentCookie().usage
    }

    setupTaxonomySelect () {
      const taxonomySelect = new GOVUK.TaxonomySelect({ $el: this.$taxonomySelect })
      taxonomySelect.update() // Taxonomy select needs an initial update on setup

      this.$taxonomySelect.addEventListener('change', () => taxonomySelect.update())
    }

    setupGa4FinderTracker () {
      this.$form.addEventListener('change', (event) => {
        const $closestCategoryWrapper = event.target.closest('[data-ga4-change-category]')

        if ($closestCategoryWrapper) {
          const category = $closestCategoryWrapper.getAttribute('data-ga4-change-category')
          GOVUK.analyticsGa4.Ga4FinderTracker.trackChangeEvent(event.target, category)
        }
      })
    }
  }

  Modules.AllContentFinder = AllContentFinder
})(window.GOVUK.Modules)
