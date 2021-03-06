module OkComputer
  class DelayedJobBackedUpCheck < SizeThresholdCheck
    attr_accessor :priority
    attr_accessor :threshold
    attr_accessor :greater_than_priority

    # Public: Initialize a check for backed-up Delayed Job jobs
    #
    # priority - Which priority to check for
    # threshold - An Integer to compare the jobs count against
    #   to consider it backed up
    #
    # Example:
    #   check = new(10, 50)
    #   # => The check will look for jobs with priority between
    #   # 0 and 10, considering the jobs as backed up if there
    #   # are more than 50 of them
    def initialize(priority, threshold, options = {})
      self.priority = Integer(priority)
      self.threshold = Integer(threshold)
      self.greater_than_priority = !!options[:greater_than_priority]
      self.name = greater_than_priority ? "Delayed Jobs with priority higher than '#{priority}'" : "Delayed Jobs with priority lower than '#{priority}'"
    end

    # Public: How many delayed jobs are pending within the given priority
    def size
      if defined?(::Delayed::Backend::Mongoid::Job) && Delayed::Worker.backend == Delayed::Backend::Mongoid::Job
        query = greater_than_priority ? Delayed::Job.gte(priority: priority) : Delayed::Job.lte(priority: priority)
      else
        operator = greater_than_priority ? ">=" : "<="
        query = Delayed::Job.where("priority #{operator} ?", priority)
      end
      query.where(:locked_at => nil, :last_error => nil).count
    end
  end
end
