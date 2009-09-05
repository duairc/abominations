# Ruby Abominations

This [discussion](http://news.ycombinator.com/item?id=791762) on Hacker News the other day got me thinking about design patterns. I'd already known that I wasn't likely to write [crap like this](http://ws.apache.org/xmlrpc/apidocs/org/apache/xmlrpc/server/RequestProcessorFactoryFactory.html?rel=html) when programming in Ruby, but the discussion got me thinking about common patterns I that I do find myself using in Ruby, and how I could abstract them. The result of that thinking is this set of abominations. Its highlights include:

- `Bignum#to_fixnum`: This will truncate a `Bignum` into a (signed) `Fixnum`.
- `Class#unmetaclass`: If `klass` is a metaclass of `x`, then `klass.unmetaclass` will return `x`.
- `Abominations::JustLikeInheritance`: This is a mixin that can be included into another mixin to make that mixin be "just like inheritance" when you mix it into a class. This means that not only are instance methods copied over, but class methods, class variables and class-instance variables are too. It will only copy class methods which are defined inside a `metaclass.class_eval` block (it will actually evaluate that block in the context of the class into which you include your mixin, y'see).

Some of the things it includes are genuinely useful abstractions, while some are downright silly (I use the metaclass of a metaclass at one point). I make liberal use of monkey patching and do other "bad" things, so you should probably be reluctant to use this in real code.
