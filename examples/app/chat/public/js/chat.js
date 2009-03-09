(function () {
  function say() {
    var input = $('input#talk')[0],
        text  = encodeURIComponent(input.value);

    if (text) {
      $.post('/say', 'text=' + text, update, 'text/plain');
    }

    input.value = '';
    return false;
  }

  function update() {
    $('#main').load('/listen')
  }

  function poll() {
    update();
    setTimeout(poll, 1000.0);
  }

  $('body').ready(function () {
    $('#chat').submit(say);
    $('input#talk').focus();
    poll();
  });
})();
