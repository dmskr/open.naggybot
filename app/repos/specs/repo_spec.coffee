require "../../shared/specs/helpers"

describe "Repo", ->
  describe 'skin save', ->
    shouldHaveCreatedAt('repos')
    shouldHaveUpdatedAt('repos')
