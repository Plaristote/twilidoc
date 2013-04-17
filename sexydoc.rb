module SexyDoc
  ATTR_PTR      = 1
  ATTR_REF      = 2
  ATTR_CONST    = 4
  ATTR_UNSIGNED = 8
  ATTR_STATIC   = 16
  ATTR_INLINE   = 32
  ATTR_VIRTUAL  = 64
  ATTR_TYPEDEF  = 128

  class Typedef
    attr_accessor :name, :typedef_to, :pointer_to
    
    def initialize typename, type
      @pointer_to = type
      @typedef_to = typename
    end
    
    def is_typedef?
      true
    end
    
    def method_missing method, *args, &block
      if @pointer-to.nil?
	super
      else
        @pointer_to.send method, args, block
      end
    end
  end

  class Type
    attr_accessor :name, :desc
    attr_accessor :functions
    attr_accessor :attributes
    attr_accessor :declared_as
    attr_accessor :declared_in
    attr_accessor :ancestors

    def initialize project
      @project     = project
      @name        = 'unresolved type'
      @desc        = 'no description'
      @declared_in = ''
      @functions   = []
      @attributes  = []
      @declared_as = ''
      @ancestors   = []
    end
    
    def is_typedef?
      false
    end

    def namespaces project
      parts   = @name.split '::'
      domains = []
      combo   = nil
      parts.each do |part|
        combo = if combo.nil? then part else "#{combo}::#{part}" end
        domains << combo 
      end
      @ancestors.each do |ancestor|
        type     = project.find_type ancestor[:class], domains
        domains += type.namespaces project unless type.nil?
      end
      domains
    end

    def documentation
      if @doc.nil?
        @doc = @project.doc[@name]
      end
      @doc
    end
  end

  class Documentable
    def initialize project, type
      @project   = project
      @doc       = nil
      @attr_type = type
    end

    def documentation
      return nil if @klass.nil?
      if @doc.nil?
        doc = @project.doc
        cat = case @attr_type
        when :method
          'methods'
        when :attribute
          'attributes'
        end

        doc     = @klass.documentation
        cat_doc = doc[cat] unless doc.nil?
        array   = @klass.send cat
        index   = array.index self
        if not cat_doc.nil? and not index.nil?
	  if @attr_type == :method
	    throw @name
	  end
          @doc  = cat_doc[index]
        end
      end
      @doc
    end
  end

  class Function < Documentable
    attr_accessor :name, :type, :visibility, :klass
    attr_accessor :attrs, :code
    attr_accessor :return_type
    attr_accessor :parameters

    def initialize project
      super project, :method
      @name        = 'unresolved symbol'
      @desc        = 'no description'
      @return_type = { type: (Type.new project), attrs: 0 }
      @attrs       = 0
      @klass       = nil
      @code        = ''
    end

    def desc
    end
  end

  class Attribute < Documentable
    attr_accessor :name, :desc, :type, :visibility, :klass
    attr_accessor :attrs

    def initialize
      super nil, :attribute
      @name       = ''
      @visibility = 'public'
      @attrs      = 0
      @desc       = 'no description'
      @klass      = nil
    end

    def project= project
      @project = project
    end

    def has_attr? attr
      (@attrs & attr) != 0
    end
  end

  class Project
    attr_accessor :functions, :types, :name, :desc, :doc

    def initialize
      @functions = []
      @types     = []
      @name      = 'Unnamed project'
      @desc      = 'No description'
      @doc       = {}
    end

    def find_type name, namespaces = []
      name = name.name if name.class == SexyDoc::Type
      ret  = ''
      namespaces << ''
      @types.each do |type|
        namespaces.each do |namespace|
          full_name = if namespace == '' then name else namespace + '::' + name end
          return type if type.name == full_name
        end
      end
      nil
    end
    
    def typedefs
      @types.select {|x| x.is_typedef? }
    end
  end
end

