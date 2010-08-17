
Avoiding Denial-of-service attacks
----------------------------------
The url given above, `/2009/11/29/145804_file.gif?m=resize&o[geometry]=30x30`, could easily be modified to
generate all different sizes of thumbnails, just by changing the size, e.g.

`/2009/11/29/145804_file.gif?m=resize&o[geometry]=30x31`,

`/2009/11/29/145804_file.gif?m=resize&o[geometry]=30x32`,

etc.

Therefore the app can protect the url by generating a unique sha from a secret specified by you

    Dragonfly[:images].configure do |c|
      c.protect_from_dos_attacks = true                           # Actually this is true by default
      c.secret = 'You should supply some random secret here'
    end

Then the required urls become something more like

`/2009/12/10/215214_file.gif?m=resize&o[geometry]=30x30&s=aa78e877ad3f6bc9`,

with a sha parameter on the end.
If we try to hack this url to get a different thumbnail,

`/2009/12/10/215214_file.gif?m=resize&o[geometry]=30x31&s=aa78e877ad3f6bc9`,

then we get a 400 (bad parameters) error.
