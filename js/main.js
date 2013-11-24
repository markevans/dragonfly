(function ($) {
  $(document).ready(function () {
    var subHeadings = []

    $('section h2').each(function () {
      var $h2 = $(this),
          name = $h2.text()

      // Give the subheading an id if it doesn't already have one
      if( !$h2.attr('id') ) {
        $h2.attr('id', name.replace(/\W/g, '-').replace(/[A-Z]/g, function (ch) { return ch.toLowerCase() }) )
      }

      subHeadings.push({
        name: name,
        id: $h2.attr('id')
      })
    })

    if( subHeadings.length ) {
      var currentPath = window.location.pathname.replace(/\/$/, '')
      var $ul = $('<ul>')
        .addClass('subnav')
        .html(
          subHeadings.map(function (sh) {
            return '<li><a href="#' + sh.id + '">' + sh.name + '</a></li>'
          })
        )

      var $navLink = $('header li a[href$="' + currentPath + '"]')

      $navLink.after($ul)
    }
  })
})($)
