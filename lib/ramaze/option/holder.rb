#          Copyright (c) 2008 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the Ruby license.

require 'ramaze/option/merger'

module Ramaze
  module Option
    class Holder
      include Merger

      def initialize(options = {})
        @members = Set.new

        options.each do |key, value|
          add_option(key, value, complain = false)
        end
      end

      def add_option(key, value, complain = true)
        Log.warn("Adding #{key} to #{self}") if complain

        self.class.class_eval do
          attr_reader key unless method_defined?(key)
          attr_writer key unless method_defined?("#{key}=")
        end

        self[key] = value
      end

      def [](key)
        __send__(key)
      end

      def []=(key, value)
        @members << key.to_s.to_sym
        __send__("#{key}=", value)
      end

      include Enumerable

      def each
        @members.each do |member|
          yield member, self[member]
        end
      end

      def startup(options)
        options.each do |key, value|
          self[key] = value
        end

        merge!(ARGV)
        merge!(ENV)

        self.root ||= File.dirname(File.expand_path(runner))
        [self.load_engines].flatten.compact.each do |engine|
          Ramaze::Template.const_get(engine)
        end
      end

      # batch-assignment of key/value from hash, yields self if a block is given.
      def setup(hash = {})
        merge!(hash)
        yield(self) if block_given?
      end

      # Modified options

      def port=(number)
        @port = number.to_i
      end

      def public_root=(pr)
        @public_root = pr
      end

      # Find a suitable public_root, if none of these is a directory just use the
      # currently set one.
      def public_root
        r = [ pr = @public_root,
          root/pr,
        ].find{|path| File.directory?(path) } || @public_root

        File.expand_path(r)
      end

      def view_root=(vr)
        @view_root = vr
      end

      # Find a suitable view_root, if none of these is a directory just use
      # the currently set one.
      def view_root
        r = [ vr = @view_root,
          root/vr,
          root/'template',
        ].find{|path| File.directory?(path) } || @view_root

        File.expand_path(r)
      end

      def template_root=(tr)
        Ramaze::deprecated "Global.template_root=", "Global.view_root="
        self.view_root = tr
      end

      def template_root
        Ramaze::deprecated "Global.template_root", "Global.view_root"
        self.view_root
      end

      def adapter
        find_from_aliases(@adapter, :adapter_aliases, Ramaze::Adapter, "ramaze/adapter")
      end

      def cache
        find_from_aliases(@cache, :cache_aliases, Ramaze, "ramaze/cache")
      end

      def cookie_secret
        return @cookie_secret if @cookie_secret
        file = cookie_secret_path

        if File.file?(file) and File.readable?(file)
          @cookie_secret = File.read(file).strip
        else
          self.cookie_secret = Session.random_key
        end
      end

      def cookie_secret=(cs)
        @cookie_secret = cs
        file = cookie_secret_path

        if File.writable?(file)
          File.open(file, 'w+'){|io| io.write(cs) }
        else
          Log.warn("Unable to write cookie secret file: #{file}")
        end
      end

      private

      def cookie_secret_path
        File.expand_path(root/cookie_secret_file)
      end

      def find_from_aliases(name, alias_key, mod, path)
        case name
        when String, Symbol
          name = name.to_s
          name = self[alias_key][name] || name
          find_require(name, mod, path)
        else
          name
        end
      end

      def find_require(name, mod, path)
        class_name = name.to_s
        file_path = File.join(path, class_name.downcase)

        require(file_path) unless mod.const_defined?(class_name)

        mod.const_get(class_name)
      end
    end
  end
end
