watch('lib/.*\.rb|yard/.*')  {|md| system("rake yard:changed") }
