# frozen_string_literal: true

require_relative 'service_chain'

module BBServices

  # The lightweight service object provided by BBServices. The basic functionality includes:
  # - Ability to access user defined initalization. E.g. initalize(one = 1, two = 2)
  # - Ability to chain services via '.then'
  # - Ability to check success / failure
  # - Ability to store errors thrown via services
  class Service
    

    class << self
      
      # Creates the service instances and calls run upon said instance
      # @param [Array] args The array of params which has been passed to run
      # @param [Block] block The block which will be called upon the service finishing running
      # @return [BBServices.Service] returns the service instance
      def run(*args, **kwargs, &block)
        new(*args, **kwargs).tap do |service|
          service.run(&block)
        end
      end

      # Creates the service instances and calls run! upon said instance
      # @param [Array] args The array of params which has been passed to run!
      # @param [Block] block The block which will be called upon the service finishing running successfully
      # @return [BBServices.Service] returns the service instance
      def run!(*args, **kwargs, &block)
        new(*args, **kwargs).tap do |service|
          service.run!(&block)
        end
      end
    end

    # Runs the service using 'safe' execution. The @run variable will be set to true, then
    # the run method will be called
    # @param [Block] block The block which will be called upon the service finishing running
    # @return [BBServices.Service] returns the service instance
    def run(&block)
      begin
        @ran = true
        successful = on_run
        set_successful(successful == nil ? true : !!successful)
      rescue => e
        set_successful(false)
        register_error(e)
      ensure
        call_block(block) if block_given?
      end
    end

    # Runs the service using 'unsafe' execution. The @run variable will be set to true, then
    # the run! method will be called
    # @param [Block] block The block which will be called upon the service finishing running
    # @return [BBServices.Service] returns the service instance
    def run!(&block)
      begin
        @ran = true
        successful = on_run!
        set_successful(successful == nil ? true : !!successful)
        call_block(block) if block_given?
      rescue => e
        set_successful(false)
        register_error(e)
        raise e
      end
    end

    # Returns a ServiceChain with the service as a registered service.
    # The service must have been ran in order to call this chaining method.
    def then(*args, &block)
      raise BBServices::ServiceMustRunBeforeChainingError if !self.ran?

      BBServices::ServiceChain.new(self).then(block)
    end

    # Returns true/false on if the service has been ran
    # @return [Boolean] True/False value on if the service has been ran
    def ran?
      !!@ran
    end

    def run?
      !!@ran
    end

    # Returns true/false on if the service was successful.
    # @return [Boolean] true/false on if the service was successful.
    def successful?
      (@successful == nil ? false : @successful) 
    end

    # Returns true/false on if the service was unsuccessful. This will always be the inverse of successful?
    # @return [Boolean] true/false on if the service failed.
    def failed?
      (@successful == nil ? false : !@successful) 
    end

    # Calls the given block if the service was successful
    def success(&block)
      yield(self) if succeeded?
    end

    # Calls the given block if the service failed
    def failure(&block)
      yield(self) if failed?
    end

    # Calls success on success?, failure on !success?
    # @param [Proc] success The proc to be called upon a successful service
    # @param [Proc] failure
    # @return [Boolean] true/false if the service has any params
    def on(success: proc {}, failure: proc {})
      if successful?
        success.call
      elsif failed?
        failure.call
      end
    end

    # Returns true / false if the service threw an error.
    # @return [Boolean] true/false on if an error has occurred
    def error?
      errors.count > 0
    end

    def error
      errors.first
    end

    def errors
      @errors ||= []
    end

    alias_method :succeeded?, :successful?
    alias_method :call, :run
    alias_method :call!, :run!

    protected

    # Called upon run. 
    # @return (nil, boolean) a nil value will automatically set the successful value as
    # success upon exiting of this method, a true / false value will set the successful value
    # to that return
    def on_run
      raise NotImplementedError.new('#run must be implemented on subclass')
    end

    # Called upon run.
    # @return (nil, boolean) a nil value will automatically set the successful value as
    # success upon exiting of this method, a true / false value will set the successful value
    # to that return
    def on_run!
      raise NotImplementedError.new('#run must be implemented on subclass')
    end

    def call_block(block)
      block.call(self)
    end

    private

    # Sets the internal @successful instance variable
    # @param [Boolean] successful True / False if the service has been successful
    def set_successful(successful = true)
      @successful = successful
    end

    # Adds an error to the errors list
    # @param [Error] error The error to be assigned
    def register_error(error)
      errors << error
    end
  end
end
