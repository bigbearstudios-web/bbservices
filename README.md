# BBServices

[![pipeline status](https://gitlab.com/big-bear-studios-open-source/bbservices/badges/master/pipeline.svg)](https://gitlab.com/big-bear-studios-open-source/bbservices/-/commits/master) [![coverage report](https://gitlab.com/big-bear-studios-open-source/bbservices/badges/master/coverage.svg)](https://big-bear-studios-open-source.gitlab.io/bbservices)

## Table of Contents

- [BBServices](#bbservices)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Quick Start](#quick-start)
    - [Params](#params)
    - [Complete Example](#complete-example)
    - [Chaining Services](#chaining-services)
    - [Safe vs Unsafe Execution](#safe-vs-unsafe-execution)
  - [Contributing](#contributing)
    - [Running Tests](#running-tests)
    - [Running Rubocop](#running-rubocop)
    - [Publishing (Required Ruby Gems Access)](#publishing-required-ruby-gems-access)
    - [Future Development](#future-development)
  - [License](#license)

## Introduction

BBServices is a lightweight service framework which allows you to create re-usable and testable code. Its purpose is to try and standardise the use of services across a project and provide a simple yet scalable iterface to allow developers to create, use and test service objects.

There are three main parts of BBServices:

- BBServices::Service, The extendable service class.
- BBServices::ServiceProvider, A module to aid the calling of services from a `service provider`
- BBServices::ServiceChain, The chain class which encapsulates the chaining of services.

You then have some extensions such as: 

- BBServices::Extensions::WithParams, allows a param hash to be accepted

## Installation

Add it to your Gemfile:

``` ruby
gem 'bbservices'
```

## Usage

### Quick Start

To create a service, simply create a new class and extend it with `BBServices::Service` and override the following methods:

``` ruby
class MyService < BBServices::Service

  def initalize(my_number)
    # Here you can setup any member variales you require and wish to put to
    # use within the on_run / on_run! methods
    @my_number = my_number
  end

  #
  # Please note that only one of the methods needs to be created in most cases.
  # See 'safe vs unsafe' execution for more information

  ##
  # This method is called when calling 'run / call' or 'run_service' from a provider.
  def on_run
    @output = @my_number * 5
  end

  ##
  # This method is called when calling 'run! / call!' or 'run_service!' from a provider.
  def on_run!
    @output = @my_number * 5
  end
end
```

One you have created your service and overriden the on_run OR on_run! methods you can then call the service via the class methods of `run` / `run!`. Its worth noting here that the return of `run` and `run!` is the BBServices::Service itself or a block can be passed which will return the given service which by default will return the BBServices::Service instance.

``` ruby
MyService.run(10) or MyService.run!(10)
# Service instance will be return from both

MyService.run(10) { |service| }

```

Internally this will run the service calling the `initialize` method as it would be on any ruby class, then `on_run` and will handle the internal state / errors which you can access via the following methods.

Check if the service has been ran:

``` ruby
service.run? or service.ran?
# Will return true for a ran class, false for a class which is yet to be ran
```

Check the overall completion state of the service:

``` ruby
service.successful? or service.succeeded?
# Will return true if the run was successful, false if not
service.failed?
# Will return false if a run was successful, true if not
```

Check the completion state via block:

``` ruby

# Similar syntax to the format blocks in Rails
# Please note this will cause two if statements to be processed, E.g. one for success, one for failure
service.success { # Do things on success }
service.failure { # Do things on failure }

# Cheaper programatically but uglier syntax
service.on(
  success: Proc.new { 
    # On Success 
  }, 
  failure: Proc.new { 
    # On Failure 
  }
)

# Using the good old if statement, cheapest in terms of performance.
if service.success 
  # On Success
else 
  # On Failure
end

```

Check for errors, get the errors:

``` ruby
service.error?
# Will return true / false if there is any errors present

service.errors
# Will return an array of all the errors thrown

service.error
# Will return the first error
```

### Complete Example

#### CSV Parsing Service

``` ruby
require 'csv'

class CSVReader < BBServices::Service
  def initialize(file_path)
    @file_path = file_path
  end

  def on_run 
    csv = CSV.read(@file_path)
    csv.each do |row|
      #Do something with each row, any error here will be captured
    end
  end
end
 
CSVReader.run(file_path: 'my_csv_file.csv') do |service| 
  service.success { puts 'CSV was read!' }
  service.failure { puts "CSV Failed to read, this was the error #{ service.error.message }" }
end

```

### Chaining Services

With the entire point behind services being that they should perform a single action, you will no doubt run into the problem of 'How do I run multiple services which depend on one another?', BBServices has solved this with the `.then` method when can be used via any service:

```ruby

# Note that your inital service needs to be ran, this is because without this BBServices would know if
# you wish to use the ! method on run or not
CreateUserService.run(params)
  .then { |chain| EmailUserService.run!(chain.first.user) }
  .then { |chain| PushNotifyUserService.run!(chain.first.user) }

```
<!-- 
There are a given set of rules which are always followed when using the .chain method.

1. A BBService object can be returned from .chain, this will be stored within the ServiceChain. Any other value will be treat as a success / fail based on truthiness.
2. The params value is the value from the current call to .chain.
3. Success of the chain will be denoted by, All of the services being successful or All of the chained blocks returning a 'non-nil' value
4. Any failures (E.g. Errors been thrown) will result in the chain stopping
5. Any failures using run! will result in the error being throw and require catching -->

### Safe vs Unsafe Execution

BBServices uses a similar concept to Rails / ActiveRecord with its concept of save vs save! where in that the first method will capture any exceptions and store them where as the other will throw an exception which then should be handled by the developer. This can be useful using testing when you want the first exception to bubble up to your tests and not be swolled by the BBServices::Service.

### Extensions 

All extensions can be included into a service via `include`. See below for examples of the extensions:

#### WithParams

<!-- ``` ruby
#Called with:
MyService.run(first_name: 'John', last_name: 'Griswald')

class MyService < BBServices::Service
  include BBServices::Extensions::WithParams

  # This is how the constructor is 
  # def initalize(params = {})
  # @params = params
  # end

  def on_run
    param_for(:first_name) #John 
    param(:first_name) #John

    params #{ first_name => 'John', last_name => 'Griswald' }

    number_of_params #2
  end
end
``` -->

## Contributing

- Clone the repository
- Install bundler `gem install bundler`
- Install gems `bundle`
- Write / push some code
- Create a PR via `https://gitlab.com/big-bear-studios-open-source/bbservices/-/merge_requests`

### Running Tests

``` bash
bundle exec rspec
```

### Publishing (Requires Ruby Gems Access)

``` bash
gem build bbservices.gemspec
gem push bbservices-*.*.*.gem
```

### Future Development

- Add complete error handling on overriden methods.
- Rspec Test Helpers

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
