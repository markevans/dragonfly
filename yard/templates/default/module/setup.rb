def init
  super
  sections.place(:configuration_summary).before(:method_summary)
end
