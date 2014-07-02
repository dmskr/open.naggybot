$ ->
  if ace && $('#review_json').length > 0
    editor = ace.edit("review_json")
    editor.setTheme("ace/theme/chrome")
    editor.getSession().setMode("ace/mode/json")

    editor.setOptions maxLines: Infinity
    editor.setReadOnly(true)

  $('#pull').click ->
    return confirm 'Are you sure you wanna pull results for the review. All previously pulled data will be erased'

  $('#analyze').click ->
    return confirm 'Are you sure you wanna analyze results for the review. All previous results will be erased'

  $('#push').click ->
    return confirm 'Are you sure you wanna push results for the review. This may affect users watching the reviewed repo'

  $('#delete').click ->
    return confirm 'Are you sure you wanna delete the review'

