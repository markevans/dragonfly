Example Use Cases
=================



Text image replacement
----------------------
Configure the dragonfly app to use RMagick if not already done. Then

    url = app.generate(:text, 'Some text here!!!').url

will give you the required url. See {file:Generators} for more info.



Attachments with no processing or encoding
------------------------------------------
This should just work out of the box - just don't call process or encode methods.
