# Comments would not really be in the spirit of this thing
module Abominations
	module JustLikeInheritance; end
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

class Object
	def metaclass
		class << self; self; end
	end

	def module_name do
		self.class.to_s.split(/::/).first.to_sym
	end

	def instance_variables_hash
		instance_variables.map{|n| [n, instance_variable_get(n)]}.to_hash
	end
end

class Module
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
end

class Class
	def unmetaclass(string = inspect.gsub(/^<\#Class:(.*)>$/, '\1'), recur = 0)
		begin
			Object.const_get_full(string)
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
end

module Enumerable
	alias_method :fold, :inject
	alias_method :filter, :select

	def to_hash
		Hash[*fold(:+)]
	end
end

module Abominations::JustLikeInheritance
	def self.included(base)
		instance = instance_variables_hash
		klass = class_variables_hash

		base.metaclass.class_eval do
			define_method(:included) do |base|
				metaclass.metaclass.instance_variable_get(:@blocks).each do |block|
					base.metaclass.class_eval(&block)
				end

				instance.each{|name, value| instance_variable_set(name, value)}
				klass.each{|name, value| class_variable_set(name, value)}
			end
		end

		base.metaclass.metaclass.class_eval do
			@blocks = []

			define_method(:class_eval) do |&block|
				metaclass.instance_variable_get(:@blocks) << block
			end
		end
	end
end
