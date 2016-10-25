require("../../shared/specs/helpers");

describe("Reviews Admin Controller", function() {
  describe("index", function() {
    var action;
    testPagingFor({
      collection: "reviews"
    });
    action = "index";

    it("should render proper view", function(done) {
      res.render = function(template, options) {
        template.should.eql(Bot.root + "/app/reviews/admin/index.jade");
        return done();
      };

      return Bot.apps.reviews.controller.admin[action] (req, res, next);
    });

    it("should not fail if no reviews found", function(done) {
      return Bot.db.reviews.deleteMany({}, function(err) {
        if (err) {
          return done(err);
        }
        res.render = function(template, params) {
          params.total.should.eql(0);
          params.data.length.should.eql(0);
          return done();
        };

        return Bot.apps.reviews.controller.admin[action](req, res, next);
      });
    });

    it ("should show recent first", function(done) {
      res.render = function(view, params) {
        params.data.each (function(review, index) {
          return params.data[index + 1] && review.createdAt.should.be.above(params.data[index + 1].createdAt);
        });
        return done();
      };

      return Bot.apps.reviews.controller.admin.index(req, res, next);
    });

    return it ("should return correct tab name", function(done) {
      res.render = function(template, params) {
        params.tab.should.eql ("all");
        return done();
      };
      return Bot.apps.reviews.controller.admin.index(req, res, next);
    });
  });

  describe ("active", function() {
    var action;
    testPagingFor({
      collection: "reviews",
      action: "active"
    });

    action = "active";
    beforeEach(function(done) {
      return Bot.db.reviews.update ({}, {
        $set: {
          status: "inprogress"
        }
      }, {
        multi: true
      }, function(err) {
        return done();
      });
    });

    it ("should render proper view", function(done) {
      res.render = function(template, options) {
        template.should.eql (Bot.root + "/app/reviews/admin/index.jade");
        return done();
      };
      return Bot.apps.reviews.controller.admin[action](req, res, next);
    });

    it ("should not fail if no reviews found", function(done) {
      return Bot.db.reviews.deleteMany (function(err) {
        if (err) {
          return done(err);
        }
        res.render = function(template, params) {
          params.total.should.eql(0);
          params.data.length.should.eql(0);
          return done();
        };
      return Bot.apps.reviews.controller.admin[action](req, res, next);
    });
  });

    it ("should show recent first", function(done) {
      res.render = function(view, params) {
        params.data.each (function(review, index) {
          return params.data[index + 1] && review.createdAt.should.be.above(params.data[index + 1].createdAt);
        });

        return done();
      };
      return Bot.apps.reviews.controller.admin[action](req, res, next);
    });

    it("should return correct tab name", function(done) {
      res.render = function(template, params) {
        params.tab.should.eql ("active");
        return done();
      };
      return Bot.apps.reviews.controller.admin[action](req, res, next);
    });

    return it("should only render reviews in inprogress status", function(done) {
      return Bot.db.reviews.update({}, {
        $set: {
          status: "pending"
        }
      }, {
        multi: true
      }, function(err) {
        if (err) {
          return done(err);
        }
        return Bot.db.reviews.update({
          title: 51
        }, {
          $set: {
            status: "inprogress"
          }
        }, {
          multi: true
        }, function(err) {
          if (err) {
            return done(err);
          }
          res.render = function(template, params) {
            params.data.length.should.eql(1);
            params.data.first().title.should.eql(51);
            return done();
          };
          return Bot.apps.reviews.controller.admin[action](req, res, next);
        });
      });
    });
  });

  describe("error", function() {
    var action;
    testPagingFor({
      collection: "reviews",
      action: "error"
    });

    action = "error";
    beforeEach (function(done) {
      return Bot.db.reviews.update({}, {
        $set: {
          status: "error"
        }
      }, {
        multi: true
      }, function(err) {
        return done();
      });
    });

    it ("should render proper view", function(done) {
      res.render = function(template, options) {
        template.should.eql(Bot.root + "/app/reviews/admin/index.jade");
        return done();
      };
      return Bot.apps.reviews.controller.admin[action] (req, res, next);
    });

    it ("should not fail if no reviews found", function(done) {
      return Bot.db.reviews.deleteMany (function(err) {
        if (err) {
          return done(err);
        }
        res.render = function(template, params) {
          params.total.should.eql(0);
          params.data.length.should.eql(0);
          return done();
        };
        return Bot.apps.reviews.controller.admin[action] (req, res, next);
      });
    });

    it("should show recent first", function(done) {
      res.render = function(view, params) {
        params.data.each (function(review, index) {
          return params.data[index + 1] && review.createdAt.should.be.above(params.data[index + 1].createdAt);
        });
        return done();
      };
      return Bot.apps.reviews.controller.admin[action] (req, res, next);
    });

    it ("should return correct tab name", function(done) {
      res.render = function(template, params) {
        params.tab.should.eql ("error");
        return done();
      };
      return Bot.apps.reviews.controller.admin[action] (req, res, next);
    });

    return it ("should only render reviews in error status", function(done) {
      return Bot.db.reviews.update ({}, {
        $set: {
          status: "pending"
        }
      }, {
        multi: true
      }, function(err) {
        if (err) {
          return done(err);
        }
        return Bot.db.reviews.update({
          title: 51
        }, {
          $set: {
            status: "error"
          }
        }, {
          multi: true
        }, function(err) {
          if (err) {
            return done(err);
          }
          res.render = function(template, params) {
            params.data.length.should.eql(1);
            params.data.first().title.should.eql(51);
            return done();
          };
          return Bot.apps.reviews.controller.admin[action] (req, res, next);
        });
      });
    });
  });

  describe ("completed", function() {
    var action;
    testPagingFor({
      collection: "reviews",
      action: "completed"
    });

    action = "completed";
    beforeEach (function(done) {
      return Bot.db.reviews.update ({}, {
        $set: {
          status: "completed"
        }
      }, {
        multi: true
      }, function(err) {
        return done();
      });
    });

    it ("should render proper view", function(done) {
      res.render = function(template, options) {
        template.should.eql (Bot.root + "/app/reviews/admin/index.jade");
        return done();
      };
      return Bot.apps.reviews.controller.admin[action] (req, res, next);
    });

    it ("should not fail if no reviews found", function(done) {
      return Bot.db.reviews.deleteMany (function(err) {
        if (err) {
          return done(err);
        }
        res.render = function(template, params) {
          params.total.should.eql(0);
          params.data.length.should.eql(0);
          return done();
        };
        return Bot.apps.reviews.controller.admin[action](req, res, next);
      });
    });

    it("should show recent first", function(done) {
      res.render = function(view, params) {
        params.data.each (function(review, index) {
          return params.data[index + 1] && review.createdAt.should.be.above(params.data[index + 1].createdAt);
        });

        return done();
      };
      return Bot.apps.reviews.controller.admin[action] (req, res, next);
    });

    it ("should return correct tab name", function(done) {
      res.render = function(template, params) {
        params.tab.should.eql ("completed");
        return done();
      };
      return Bot.apps.reviews.controller.admin[action] (req, res, next);
    });

    return it ("should only render reviews in completed status", function(done) {
      return Bot.db.reviews.update ({}, {
        $set: {
          status: "pending"
        }
      }, {
        multi: true
      }, function(err) {
        if (err) {
          return done(err);
        }
        return Bot.db.reviews.update({
          title: 51
        }, {
          $set: {
            status: "completed"
          }
        }, {
          multi: true
        }, function(err) {
          if (err) {
            return done(err);
          }
          res.render = function(template, params) {
            params.data.length.should.eql (1);
            params.data.first().title.should.eql (51);
            return done();
          };
          return Bot.apps.reviews.controller.admin[action] (req, res, next);
        });
      });
    });
  });

  describe ("pending", function() {
    var action;
    testPagingFor({
      collection: "reviews",
      action: "pending"
    });

    action = "pending";
    beforeEach (function(done) {
      return Bot.db.reviews.update ({}, {
        $set: {
          status: "pending"
        }
      }, {
        multi: true
      }, function(err) {
        return done();
      });
    });

    it ("should render proper view", function(done) {
      res.render = function(template, options) {
        template.should.eql (Bot.root + "/app/reviews/admin/index.jade");
        return done();
      };
      return Bot.apps.reviews.controller.admin[action] (req, res, next);
    });

    it ("should not fail if no reviews found", function(done) {
      return Bot.db.reviews.deleteMany (function(err) {
        if (err) {
          return done(err);
        }
        res.render = function(template, params) {
          params.total.should.eql(0);
          params.data.length.should.eql(0);
          return done();
        };
        return Bot.apps.reviews.controller.admin[action] (req, res, next);
      });
    });

    it ("should show recent first", function(done) {
      res.render = function(view, params) {
        params.data.each (function(review, index) {
          return params.data[index + 1] && review.createdAt.should.be.above(params.data[index + 1].createdAt);
        });

        return done();
      };
      return Bot.apps.reviews.controller.admin[action] (req, res, next);
    });

    it ("should return correct tab name", function(done) {
      res.render = function(template, params) {
        params.tab.should.eql ("pending");
        return done();
      };
      return Bot.apps.reviews.controller.admin[action] (req, res, next);
    });

    return it ("should only render reviews in pending status", function(done) {
      return Bot.db.reviews.update ({}, {
        $set: {
          status: "completed"
        }
      }, {
        multi: true
      }, function(err) {
        if (err) {
          return done(err);
        }
        return Bot.db.reviews.update({
          title: 51
        }, {
          $set: {
            status: "pending"
          }
        }, {
          multi: true
        }, function(err) {
          if (err) {
            return done(err);
          }
          res.render = function(template, params) {
            params.data.length.should.eql(1);
            params.data.first().title.should.eql(51);
            return done();
          };
          return Bot.apps.reviews.controller.admin[action](req, res, next);
        });
      });
    });
  });

  describe("show", function() {
    var review;
    review = null;
    beforeEach (function(done) {
      return Bot.db.reviews.save({
        type: "some"
      }, function(err, t) {
        if (err) {
          return done(err);
        }
        review = t;
        return done();
      });
    });

    it ("should render correct template", function(done) {
      req.params.id = review._id;
      res.render = function(template, params) {
        template.should.eql (Bot.root + "/app/reviews/admin/show.jade");
        should.exist (params.review);
        params.review._id.should.eql (review._id);
        return done();
      };

      return Bot.apps.reviews.controller.admin.show (req, res, next);
    });

    return it ("should return 'next' action with no error if review is not found", function(done) {
      req.params.id = (review._id + '1').slice(1); // not existing
      return Bot.apps.reviews.controller.admin.show(req, res, function(err) {
        should.not.exist(err);
        return done();
      });
    });
  });

  describe('pull', function() {
    var review;
    review = null;
    beforeEach (function(done) {
      nonmock.replace (Bot.db.reviews, 'pull', function(rev, callback) {
        return callback(null, rev);
      });
      return Bot.db.reviews.save({
        github: {}
      }, function(err, result) {
        if (err) {
          return done(err);
        }
        review = result;
        req.params.id = review._id;
        return done();
      });
    });

    it ("should run review pulling", function(done) {
      nonmock.replace(Bot.db.reviews, 'pull', function(pullthis, callback) {
        should.exist(pullthis);
        pullthis._id.should.eql(review._id);
        return done();
      });

      return Bot.apps.reviews.controller.admin.pull(req, res, next);
    });

    return it ("should redirect to review#show url", function(done) {
      res.redirect = function(url) {
        url.should.eql('/admin/reviews/' + review._id);
        return done();
      };
      return Bot.apps.reviews.controller.admin.pull(req, res, next);
    });
  });

  describe('analyze', function() {
    var review;
    review = null;
    beforeEach(function(done) {
      nonmock.replace(Bot.db.reviews, 'analyze', function(rev, callback) {
        return callback(null, rev);
      });
      return Bot.db.reviews.save({
        github: {}
      }, function(err, result) {
        if (err) {
          return done(err);
        }
        review = result;
        req.params.id = review._id;
        return done();
      });
    });

    it("should run review analyzing", function(done) {
      nonmock.replace(Bot.db.reviews, 'analyze', function(analyze, callback) {
        should.exist(analyze);
        analyze._id.should.eql(review._id);
        return done();
      });

      return Bot.apps.reviews.controller.admin.analyze(req, res, next);
    });

    return it("should redirect to review#show url", function(done) {
      res.redirect = function(url) {
        url.should.eql('/admin/reviews/' + review._id);
        return done();
      };
      return Bot.apps.reviews.controller.admin.analyze(req, res, next);
    });
  });

  describe ('push', function() {
    var review;
    review = null;
    beforeEach(function(done) {
      nonmock.replace(Bot.db.reviews, 'push', function(rev, callback) {
        return callback(null, rev);
      });
      return Bot.db.reviews.save({
        github: {}
      }, function(err, result) {
        if (err) {
          return done(err);
        }
        review = result;
        req.params.id = review._id;
        return done();
      });
    });

    it("should run review analyzing", function(done) {
      nonmock.replace(Bot.db.reviews, 'push', function(push, callback) {
        should.exist(push);
        push._id.should.eql(review._id);
        return done();
      });

      return Bot.apps.reviews.controller.admin.push(req, res, next);
    });

    return it("should redirect to review#show url", function(done) {
      res.redirect = function(url) {
        url.should.eql('/admin/reviews/' + review._id);
        return done();
      };
      return Bot.apps.reviews.controller.admin.push(req, res, next);
    });
  });

  describe ('delete', function() {
    var review;
    review = null;
    beforeEach(function(done) {
      return Bot.db.reviews.save({
        some: 'value'
      }, function(err, result) {
        if (err) {
          return done(err);
        }
        review = result;
        req.params.id = review._id.toString();
        return done();
      });
    });

    it("should redirect to review list after the deletion", function(done) {
      res.redirect = function(url) {
        should.exist(url);
        url.should.eql('/admin/reviews');
        return done();
      };

      return Bot.apps.reviews.controller.admin["delete"](req, res, next);
    });

    it("should set successfull message", function(done) {
      req.flash = function(status, message) {
        status.should.eql('success');
        should.exist(message);
        return done();
      };

      return Bot.apps.reviews.controller.admin["delete"](req, res, next);
    });

    return it("should remove the review", function(done) {
      res.redirect = function() {
        return Bot.db.reviews.findById(review._id, function(err, result) {
          if (err) {
            return done(err);
          }
          should.not.exist(result);
          return done();
        });
      };

      return Bot.apps.reviews.controller.admin["delete"](req, res, next);
    });
  });

  describe('raw', function() {
    return it('should render the raw json representing the review', function(done) {
      return Bot.db.reviews.save({
        status: 'pending'
      }, function(err, review) {
        if (err) {
          return done(err);
        }
        req.params.id = review._id;
        res.send = function(text) {
          should.exist(text);
          JSON.parse(text).should.eql(JSON.parse(JSON.stringify(review)));
          return done();
        };

        return Bot.apps.reviews.controller.admin.raw(req, res, next);
      });
    });
  });

  return describe ('comments', function() {
    return it("should render the raw json representing the review's comments", function(done) {
      return Bot.db.reviews.save({
        status: 'pending',
        analyze: {
          report: {
            everything: 'isok'
          }
        }
      }, function(err, review) {
        if (err) {
          return done(err);
        }
        req.params.id = review._id;
        res.json = function(object) {
          should.exist(object);
          object.should.eql({
            everything: 'isok'
          });
          return done();
        };

        return Bot.apps.reviews.controller.admin.comments(req, res, next);
      });
    });
  });
});
