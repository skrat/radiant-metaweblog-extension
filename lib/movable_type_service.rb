module MovableTypeStructs
  class ArticleTitle < ActionWebService::Struct
    member :dateCreated,  :time
    member :userid,       :string
    member :postid,       :string
    member :title,        :string
  end

  class CategoryList < ActionWebService::Struct
    member :categoryId,   :string
    member :categoryName, :string
  end

  class CategoryPerPost < ActionWebService::Struct
    member :categoryName, :string
    member :categoryId,   :string
    member :isPrimary,    :bool
  end

  class TextFilter < ActionWebService::Struct
    member :key,    :string
    member :label,  :string
  end

  class TrackBack < ActionWebService::Struct
    member :pingTitle,  :string
    member :pingURL,    :string
    member :pingIP,     :string
  end
end


class MovableTypeApi < ActionWebService::API::Base
  inflect_names false

  api_method :getCategoryList,
    :expects => [ {:blogid => :string}, {:username => :string}, {:password => :string} ],
    :returns => [[MovableTypeStructs::CategoryList]]

  api_method :getPostCategories,
    :expects => [ {:postid => :string}, {:username => :string}, {:password => :string} ],
    :returns => [[MovableTypeStructs::CategoryPerPost]]

  api_method :getRecentPostTitles,
    :expects => [ {:blogid => :string}, {:username => :string}, {:password => :string}, {:numberOfPosts => :int} ],
    :returns => [[MovableTypeStructs::ArticleTitle]]

  api_method :setPostCategories,
    :expects => [ {:postid => :string}, {:username => :string}, {:password => :string}, {:categories => [MovableTypeStructs::CategoryPerPost]} ],
    :returns => [:bool]

  api_method :supportedMethods,
    :expects => [],
    :returns => [[:string]]

  api_method :supportedTextFilters,
    :expects => [],
    :returns => [[MovableTypeStructs::TextFilter]]

  api_method :getTrackbackPings,
    :expects => [ {:postid => :string}],
    :returns => [[MovableTypeStructs::TrackBack]]

  api_method :publishPost,
    :expects => [ {:postid => :string}, {:username => :string}, {:password => :string} ],
    :returns => [:bool]
end


class MovableTypeService < RadiantWebService
  web_service_api MovableTypeApi

  before_invocation :authenticate, :except => [:getTrackbackPings, :supportedMethods, :supportedTextFilters]

  def getRecentPostTitles(blogid, username, password, numberOfPosts)
    Page.find(:all, :order => "created_at DESC", :limit => numberOfPosts).collect do |article|
      MovableTypeStructs::ArticleTitle.new(
            :dateCreated => article.created_at,
            :userid      => article.created_by.name,
            :postid      => article.id.to_s,
            :title       => article.title
          )
    end
  end

  def getCategoryList(blogid, username, password)
    Page.find_all_by_class_name("PaginatedArchive").collect do |c|
      MovableTypeStructs::CategoryList.new(
          :categoryId   => c.id.to_s,
          :categoryName => c.title
        )
    end
  end

  def getPostCategories(postid, username, password)
    Page.find(postid).parent do |p|
      MovableTypeStructs::CategoryPerPost.new(
          :categoryName => p.title,
          :categoryId   => p.id.to_s,
          :isPrimary    => true
        )
    end
  end

  def setPostCategories(postid, username, password, categories)
    unless categories.empty?
      page = Page.find(postid)
      page.parent = Page.find(categories[0]['categoryId'].to_i)
      page.save
    end
  end

  def supportedMethods()
    MovableTypeApi.api_methods.keys.collect { |method| method.to_s }
  end

  # Support for markdown and textile formatting dependant on the relevant
  # translators being available.
  def supportedTextFilters()
    TextFilter.find(:all).collect do |filter|
      MovableTypeStructs::TextFilter.new(:key => filter.filter_name, :label => filter.description)
    end
  end

  def getTrackbackPings(postid)
    []
  end

  def publishPost(postid, username, password)
    page            = Page.find(postid)
    page.status_id  = 100
    page.save
  end
end
