watch( 'lib/.*\.rb' )  {|md| system("rake yard:changed") }
