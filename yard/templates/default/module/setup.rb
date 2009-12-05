def init
  super
  sections.place(:configuration_summary).before(:method_summary)
end

# Highlight stuff
def hl(code)
  case code
  when :do, :end then %(<span class="kw">#{code}</span>)
  when Symbol then %(<span class="symbol">#{code.inspect}</span>)
  when Integer then %(<span class="integer val">#{code}</span>)
  when String then %(<span class="string val">#{code.inspect}</span>)
  when true, false then %(<span class="kw">#{code.inspect}</span>)
  when nil then %(<span class="nil kw">#{code.inspect}</span>)
  else code
  end    
end