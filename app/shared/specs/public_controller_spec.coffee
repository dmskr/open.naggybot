require("../../shared/specs/helpers")

describe "Public Controller", ->
  describe 'index', ->
    it "should render public#index template", (done) ->
      res.render = (template) ->
        template.should.eql Bot.root + '/app/shared/public/index.jade'
        done()
      Bot.apps.shared.controller.public.index req, res, next

    it "should redirect user to private side if logged in alread", (done) ->
      req.user = login: 'monkey'
      res.redirect = (url) ->
        url.should.eql '/private'
        done()
      Bot.apps.shared.controller.public.index req, res, next

