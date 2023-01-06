require 'pagy/extras/bootstrap'

Pagy::DEFAULT[:link_extra] = 'data-remote="true"'
Pagy::DEFAULT[:items] = 10
Pagy::DEFAULT.freeze