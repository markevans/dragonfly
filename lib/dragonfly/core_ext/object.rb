class Object
  
  # Will eventually get this by cherry-picking from activesupport
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
  
  # instance_exec, taken from http://blog.jayfields.com/2006/09/ruby-instanceexec-aka-instanceeval.html
  # and http://eigenclass.org/hiki.rb?cmd=view&p=bounded+space+instance_exec&key=instance_exec
  # Annoyingly, ruby 1.8 doesn't allow passing args into instance_eval
  unless defined? instance_exec
    module InstanceExecHelper; end
    include InstanceExecHelper
    def instance_exec(*args, &block)
      begin
        old_critical, Thread.critical = Thread.critical, true
        n = 0
        n += 1 while respond_to?(mname="__instance_exec#{n}")
        InstanceExecHelper.module_eval{ define_method(mname, &block) }
      ensure
        Thread.critical = old_critical
      end
      begin
        ret = send(mname, *args)
      ensure
        InstanceExecHelper.module_eval{ remove_method(mname) } rescue nil
      end
      ret
    end
  end
  
end