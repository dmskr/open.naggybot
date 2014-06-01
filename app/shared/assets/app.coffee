$ ->
  if ace && $('#review_json').length > 0
    editor = ace.edit("review_json")
    editor.setTheme("ace/theme/chrome")
    editor.getSession().setMode("ace/mode/json")

    editor.setOptions maxLines: Infinity
    editor.setReadOnly(true)


