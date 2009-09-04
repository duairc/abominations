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
end

class Module
	def const_get_full(name)
		first, rest = name.to_s.split(/::/, 2)
		rest ? const_get(first).const_get_full(rest) : const_get(first)
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
		base.metaclass.class_eval do
			define_method(:included) do |base|
				metaclass.metaclass.instance_variable_get(:@blocks).each do |block|
					base.metaclass.class_eval(&block)
				end

				instance_variables.each do |name|
					instance_variable_set(name, instance_variable_get(name))
				end

				class_variables.each do |name|
					class_variable_set(name, class_variable_get(name))
				end
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
