watch('lib/.*\.rb|yard/.*|extra_docs/.*')  {|md| system("rake yard:changed") }
