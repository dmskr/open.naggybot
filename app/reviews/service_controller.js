module.exports = function(Bot, done) {
  var exports;
  exports = {};
  exports.create = function(req, res, next) {
    var payload, review;
    if (req.headers['x-github-event'] === 'ping') {
      return res.json({
        status: 'ok'
      });
    }
    if (['pull_request'].indexOf(req.headers['x-github-event']) === -1) {
      return next();
    }

    payload = JSON.parse((req.body || {}).payload);
    review = {
      title: payload.pull_request.title,
      username: payload.pull_request.user.login,
      refid: payload.pull_request.id.toString(),
      url: payload.pull_request.url,
      github: payload
    };

    return Bot.db.reviews.save(review, function(err, review) {
      if (err) {
        return next(err);
      }
      return res.json({
        status: 'ok'
      });
    });
  };
  exports.work = function(next) {};
  return done(null, exports);
};
