require 'brakeman/util'
require 'brakeman/tracker/method_info'

module Brakeman
  class Collection
    include Brakeman::Util

    attr_reader :collection, :files, :includes, :name, :options, :parent, :src, :tracker

    def initialize name, parent, file_name, src, tracker
      @name = name
      @parent = parent
      @files = []
      @src = {}
      @includes = []
      @methods = { :public => {}, :private => {}, :protected => {} }
      @class_methods = {}
      @options = {}
      @tracker = tracker

      add_file file_name, src
    end

    def ancestor? parent, seen={}
      seen[self.name] = true

      if self.parent == parent or seen[self.parent]
        true
      elsif parent_model = collection[self.parent]
        parent_model.ancestor? parent, seen
      else
        false
      end
    end

    def add_file file_name, src
      @files << file_name unless @files.include? file_name
      @src[file_name] = src
    end

    def add_include class_name
      @includes << class_name
    end

    def add_option name, exp
      @options[name] ||= []
      @options[name] << exp
    end

    def add_method visibility, name, src, file_name
      meth_info = Brakeman::MethodInfo.new(name, src, self, file_name)

      if src.node_type == :defs
        @class_methods[name] = meth_info

        # TODO fix this weirdness
        name = :"#{src[1]}.#{name}"
      end

      @methods[visibility][name] = meth_info
    end

    def each_method
      @methods.each do |_vis, meths|
        meths.each do |name, info|
          yield name, info
        end
      end
    end

    def get_method name, type = :instance
      case type
      when :class
        get_class_method name
      when :instance
        get_instance_method name
      else
        raise "Unexpected method type: #{type.inspect}"
      end
    end

    def get_instance_method name
      @methods.each do |_vis, meths|
        if meths[name]
          return meths[name]
        end
      end

      nil
    end

    def get_class_method name
      @class_methods[name]
    end

    def file
      @files.first
    end

    def top_line
      if sexp? @src[file]
        @src[file].line
      else
        @src.each_value do |source|
          if sexp? source
            return source.line
          end
        end
      end
    end

    def methods_public
      @methods[:public]
    end
  end
end
