Bot.db.keywords = {
  fromText: (text, done) ->
    result = (text or "").toString().split(/[.,\/ !(){}\[\]-\]{}()*+?.,\\^$|#\s\@]/).exclude (w) ->
      not w or w.length is 0
    result = result.map (w) ->
      w.toLowerCase()
    done null, result.unique()

  toConditions: (text, done) ->
    words = (text or "").toString().toLowerCase().split(/[.,\/ (){}\[\]+*?$~^\-:\@]/)
    words = words.exclude (w) ->
      not w or w.length is 0
    conditions = words.unique().map (w) ->
      keywords: new RegExp("^" + w)
    return done(null, null)  if conditions.length is 0
    done null,
      $and: conditions

}
