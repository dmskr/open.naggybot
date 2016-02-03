require("../../shared/specs/helpers") (err, Bot) ->
  describe "Users Public Controller", ->
    describe "new", ->
      it "should render signup public template", (done) ->
        res.render = (template) ->
          template.should.eql Bot.root + '/app/users/public/signup.jade'
          done()
        Bot.apps.users.controller.public.new req, res, next


