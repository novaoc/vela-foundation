# frozen_string_literal: true

module Madmin
  class ApplicationController < Madmin::BaseController
    include Rails.application.routes.url_helpers
    include Foundation::AdminAccess
  end
end
