# Comments would not really be in the spirit of this thing
module Abominations
	module DelayMetaclassEval; end
end

class String
	def upcase?
		self == upcase
	end

	def downcase?
		self == downcase
	end

	def capitalized?
		self == capitalize
	end
end

class Fixnum
	BYTES = 0.size
	BITS = (BYTES << 3) - 2
	MIN = -1 << BITS
	MAX = ~MIN
end

class Fixnum
	def to_fixnum
		self
	end
end

class Bignum
	def to_fixnum
		self[Fixnum::BITS] == 1 ? ~(~(self) & Fixnum::MAX) : self & Fixnum::MAX
	end
end

class Module
	def namespace
		raise NameError, "#{self} is not in a namespace" unless name
		names = name.split(/::/)
		Kernel.const_get(names.size > 1 ? names[0].to_sym : :Kernel)
	end

	def const_get_full(name)
		first, rest = name.to_s.split(/::/, 2)
		rest ? const_get(first).const_get_full(rest) : const_get(first)
	end

	def constants_hash
		constants.map{|n| [n, const_get(n)]}.to_hash
	end

	def class_variables_hash
		class_variables.map{|n| [n, class_variable_get(n)]}.to_hash
	end

	def owns?(method)
		metaclass == method(method).owner rescue false
	end

	private
	def override_method(method, &block)
		original = instance_method(method)
		define_method(method) do |*args|
			instance_exec(original.bind(self), *args, &block)
		end
	end

	def before(method, &block)
		if hookified?
			metaclass.class_eval{@hooks[method][:before].unshift(block)}
		else
			override_method(method) do |original, *args|
				puts raise rescue $!.backtrace
				instance_exec(*args, &block)
				original.(*args)
			end
		end
	end

	def after(method, &block)
		if hookified?
			metaclass.class_eval{@hooks[method][:after] << block}
		else
			override_method(method) do |original, *args|
				result = original.(*args)
				instance_exec(*args, &block)
				result
			end
		end
	end

	def hookify
		@hookified = true
		metaclass.class_eval do
			@hooks = Hash.new{|h, k| h[k] = {:before => [], :after => []}}

			define_method(:new) do |*args|
				metaclass.instance_variable_get(:@hooks).each do |method, hooks|
					override_method(method) do |original, *args|
						hooks[:before].each{|hook| instance_exec(*args, &hook)}
						result = original.(*args)
						hooks[:after].each{|hook| instance_exec(*args, &hook)}
						result
					end
				end

				super(*args)
			end

			def inherited(klass)
				klass.send :hookify
			end
		end
	end

	def hookified?
		!!@hookified
	end
end

class Module
	instance_methods.grep(/instance_methods$/).each do |methods|
		override_method(methods) do |original|
			original.call.sort
		end

		define_method("my_#{methods}") do
			(send methods).filter{|m| owns? m}
		end
	end
end

module Kernel
	def metaclass
		class << self; self; end
	end

	def namespace
		self.class.namespace
	end

	def instance_variables_hash
		instance_variables.map{|n| [n, instance_variable_get(n)]}.to_hash
	end

	def owns?(method)
		[self.class, metaclass].include? method(method).owner rescue false
	end

	def all_methods
		public_methods + protected_methods + private_methods
	end

	instance_methods.grep(/methods$/).each do |methods|
		override_method(methods) do |original|
			original.call.sort
		end

		define_method("my_#{methods}") do
			(send methods).filter{|m| owns? m}
		end
	end
end

class Hash
	def sort!
		sort.each do |key, value|
			delete(key)
			self[key] = value
		end
		self
	end

	def symbolify!
		select{|key| !(Symbol === key)}.each do |key, value|
			delete(key)
			self[key.to_s.to_sym] ||= value
		end
		self
	end
	def symbolify; dup.symbolify!; end

	def stringify!
		select{|key| !(String === key)}.each do |key, value|
			delete(key)
			self[key.to_s] ||= value
		end
		self
	end
	def stringify; dup.stringify!; end
end

class Class
	def metaclass?
		self != unmetaclass
	end

	def unmetaclass(string = inspect.gsub(/^<\#Class:(.*)>$/, '\1'), recur = 0)
		begin
			Kernel.const_get_full(string)
		rescue NameError
			string.gsub!(/^\#<(?:[A-Zmf](?:[A-Za-z_]*)(?:::)?)+:(.*)>$/, '\1')
			if string =~ /^0x[a-f0-9]+$/
				ObjectSpace._id2ref((string.to_i(16) / 2).to_fixnum)
			else
				object = unmetaclass(string, recur + 1)
				recur > 0 ? object.metaclass : object
			end
		end
	end

	private
	def before(method, &block)
		hookify unless metaclass? or hookified?
		super
	end

	def after(method, &block)
		hookify unless metaclass? or hookified?
		super
	end
end

module Enumerable
	alias_method :fold, :inject
	alias_method :filter, :select

	def to_hash
		Hash[*fold(:+)]
	end
end

module Abominations::DelayMetaclassEval
	def self.included(base)
		def (base.metaclass).class_eval(&block)
			(@blocks ||= []) << block
		end

		def base.included(base)
			blocks = metaclass.instance_variable_get(:@blocks)
			blocks.each{|block| base.metaclass.class_eval(&block)}
		end

		base.send :hookify
	end
end

def (GLib::Object).inherited(klass)
	klass.type_register
end rescue nil
