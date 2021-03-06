# Very useful helper function to remove array items
Array::remove = (e) -> @[t..t] = [] if (t = @indexOf(e)) > -1

special = (char) ->
  '\x1b[' + {
    green: '32m'
    red: '31m'
    clear: '0m'
  }[char]

class Tron
  constructor: ->
    @timers = []
    @scale = 1.0
    @subscriptions = [
      (method, args) -> console[method](args...)
    ]
    @named_tests = {}
    @announce = false
  
  subscribe: ( fn ) ->
    ###
    Subscribe to console events with a function that takes two arguments
    
    The first argument is the console function being called, the second
    is a list of arguments passed to that console function.
    ###
    handle = `undefined`
    tron.test( 'check_subscribe_fn', fn )
    switch typeof fn
      when 'list'
        handle = ( @subscribe(f) for f in fn )
      when 'function'
        handle = @subscriptions.length
        @subscriptions.push( fn )
    return handle
  
  unsubscribe: ( handle ) ->
    ###
    Unsubscribe from tron with the handle returned by subscribe.
    FIXME: Using an index for handles breaks with unsubcriptions.
    ###
    if handle?
      s = @subscriptions
      result = s[handle]
      @subscriptions = s[...handle].concat(s[handle+1..])
      return result
    else
      return ( @unsubscribe( i ) for s, i in @subscriptions )
  
  capture: ( fn ) ->
    ###
    Temperarily overrides all subscriptions and returns logs instead.
    ###
    tron.test( 'check_is_function', fn )
    tmp = @subscriptions
    r = []
    @subscriptions = [ (args...) -> r.push( args ) ]
    fn()
    @subscriptions = tmp
    return r
    
  test: (input, args...) =>
    ###
     This simple function will define the way we test Socrenchus. You can do
     things in most of the same ways you did them with the console.

     Call it with your test function like this:
      
      my_test = (your, args, here) ->
        tron.log( 'this writes to the log' )
        tron.info( "this is \#{your} info message" )
        tron.warn( "this is warning about your \#{args}" )
        tron.error( "there is an error \#{here}" )
        
      tron.test(my_test, 'your', 'args', 'here')
    ###
    args ?= []
    found = false
    return unless Math.random() < @scale
    switch typeof input
      when 'function'
        input(args...)
      when 'object'
        for k,v of input
          @named_tests[k] = v
      when 'string'
        if input[0..3] is 'try_'
          `crillic = 'Г'`
          tron.log( " #{crillic} #{input} started.\n" )
          @announce = true
          @named_tests[input]()
          @announce = false
          tron.log( " L #{input} finished.\n" )
          return
        try 
          color = special('green')
          @named_tests[input]( args... )
          `check = '✓'`
          tron.log( "   #{check} #{color}#{input} passed." ) if @announce
        catch error
          color = special('red')
          `err_mark = '✗'`
          tron.warn( "   #{err_mark} #{color}failure in #{input}:" )
          tron.log( special('clear') )
          tron.trace( error )
        finally
          tron.log( special('clear') )
      when 'undefined'
        for k,v of @named_tests
          @test( k ) if k[0..3] is 'try_'
      else throw "expected function, got #{typeof input}."
    return found

      
  
  throttle: ( scale ) ->
    u = """
    
     Use this to throttle the number of tests being run. Scale is a fraction
     that represents the probability that any given test function will get run.
    
    """
    @scale = scale

  stopwatch: ( timer_name ) ->
    u = """
    
     This function acts as both console.time and console.timeEnd, just pass it
     a string to start the timer, and the same string to stop it.
    
    """
    unless timer_name?
      @warn(u)
    else unless timer_name in @timers
      @timers.push( timer_name )
      @console.time( timer_name )
    else
      r = console.timeEnd( timer_name )
      @timers.remove( timer_name )
      return r
  
  _name_of_function: ( fn ) ->
    for key, value of @
      return key if value is fn
  
  level: ( fn ) ->
    u = """
     
     In the example: 
     
     tron.level( tron.warn )
     
     Tron will be set to only show information that is at least as severe as a
     warning.
     
    """
    level = @_name_of_function( fn )
    unless level?
      @warn(u)
    else
      @min_level = level

  write: (method, args) ->
    suppress = ( =>
      return false unless @min_level
      for key of @
        return false if key is @min_level
        return true if key is method
    )()
    unless suppress
      for s in @subscriptions
        s(method, args)


  dir:    (args...) -> @write('dir', args) 
  trace:  (args...) -> @write('trace', args)
  log:    (args...) -> @write('log', args)
  info:   (args...) -> @write('info', args)
  warn:   (args...) -> @write('warn', args)
  error:  (args...) -> @write('error', args)
  assert: (args...) -> @write('assert', args)
  
@tron = tron = new Tron()

tron.test(
  check_subscribe_fn: ( fn ) ->
    m = [ "tron.subscribe( fn ) was expecting fn to",
          "but got" ]
    # check that it is a list or function
    t = typeof fn
    unless t in ['list', 'function']
      throw "#{m[0]} be a function #{m[1]} #{t}."
    # make sure that it accepts the right ammount of arguments
    incorrect_args = true
    switch fn.length
      when 0
        if /arguments/.test( fn.toString() )
          incorrect_args = false
      when 2 then incorrect_args = false
    if incorrect_args
      throw "#{m[0]} have 2 arguments #{m[1]} #{fn.length} argument(s)"
  check_is_function: ( fn ) ->
    t = typeof fn
    throw "was expecting function, but got #{t}." unless t is 'function'
  try_varargs_subscribe: ->
    result = undefined
    fn = tron.unsubscribe( 0 )
    h = tron.subscribe( (args...) -> result = args )
    tron.log( 'test' )
    tron.unsubscribe( h )
    tron.subscribe( fn )
    unless [].concat(result...).join(':') is 'log:test'
      throw 'there was a problem adding a subscription.'
  try_capture: ->
    result = tron.capture( ->
      tron.log( 'hello, I am a log.')
    )
    result = [].concat(result...).join(':')
    unless result is 'log:hello, I am a log.'
      throw 'there was a problem trying to capture logs.'
)

if exports?
  for k,v of @tron
    exports[k] = v