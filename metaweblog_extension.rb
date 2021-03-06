# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class MetaweblogExtension < Radiant::Extension
  version "0.1"
  description "Enhances Radiant with MetaWeblog API for publishing posts (Pages)."
  url "http://code.google.com/p/feed-me/wiki/MetaWeblogAPIextension"
  
  define_routes do |map|
    map.connect "api/:action", :controller => "api"
  end
  
  def activate
    # admin.tabs.add "Meta Weblog", "/admin/meta_weblog", :after => "Layouts", :visibility => [:all]
  end
  
  def deactivate
    # admin.tabs.remove "Meta Weblog"
  end
  
end
