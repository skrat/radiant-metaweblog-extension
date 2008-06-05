module BloggerStructs
  class Blog < ActionWebService::Struct
    member :url,      :string
    member :blogid,   :string
    member :blogName, :string
  end
  class User < ActionWebService::Struct
    member :userid, :string
    member :firstname, :string
    member :lastname, :string
    member :nickname, :string
    member :email, :string
    member :url, :string
  end
end


class BloggerApi < ActionWebService::API::Base
  inflect_names false

  api_method :deletePost,
    :expects => [ {:appkey => :string}, {:postid => :int}, {:username => :string}, {:password => :string},
                  {:publish => :bool} ],
    :returns => [:bool]

  api_method :getUserInfo,
    :expects => [ {:appkey => :string}, {:username => :string}, {:password => :string} ],
    :returns => [BloggerStructs::User]

  api_method :getUsersBlogs,
    :expects => [ {:appkey => :string}, {:username => :string}, {:password => :string} ],
    :returns => [[BloggerStructs::Blog]]

  api_method :newPost,
    :expects => [ {:appkey => :string}, {:blogid => :string}, {:username => :string}, {:password => :string},
                  {:content => :string}, {:publish => :bool} ],
    :returns => [:int]
end


class BloggerService < RadiantWebService
  web_service_api BloggerApi
  before_invocation :authenticate

  def deletePost(appkey, postid, username, password, publish)
    Page.destroy(postid)
    true
  end

  def getUserInfo(appkey, username, password)
    BloggerStructs::User.new(
      :userid => username,
      :firstname => @user.name,
      :lastname => "",
      :nickname => username,
      :email => @user.email,
      :url => @location
    )
  end

  def getUsersBlogs(appkey, username, password)
    [BloggerStructs::Blog.new(
      :url      => @location, # this_blog.base_url,
      :blogid   => "", # this_blog.id,
      :blogName => "radiant" # this_blog.blog_name
    )]
  end

  def newPost(appkey, blogid, username, password, content, publish)
    title, categories, body = content.match(%r{^<title>(.+?)</title>(?:<category>(.+?)</category>)?(.+)$}mi).captures rescue nil

    page          = Page.new_with_defaults
    body_part     = page.part("body")
    extended_part = page.part("extended")
    
    c = body || content || ''
    
    if c.match(/<hr/)
      body_part.content     = c.split("<hr")[0]
      extended_part.content = c
    else
      perex                 = c.gsub(/<\/?[^>]*>/, "")
      body_part.content     = "<p>"+(perex.length > 512 ? perex[0..512] : perex)+"</p>"
      extended_part.content = c
    end

    page.title          = title || content.split.slice(0..5).join(' ') || ''
    page.status_id      = publish ? 100 : 1
    page.published_at = struct['dateCreated'].to_time.getlocal rescue Time.now
    page.save

    if categories
      page.parent = Page.find_by_title(categories.split(",")[0].strip) rescue nil
    end

    page.id
  end

end
