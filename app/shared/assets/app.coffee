$ ->
  editor = ace.edit("review_json")
  editor.setTheme("ace/theme/chrome")
  editor.getSession().setMode("ace/mode/javascript")

  editor.setOptions maxLines: Infinity
  editor.setReadOnly(true)


