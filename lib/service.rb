class Service < Data.define(:service, :url, :children, :image_url)
  def initialize(service:, url: nil, children: [], image_url: nil)
    raise ArgumentError, "Service cannot be empty" if service.nil? || service.empty?

    service => String
    url => String if url
    children => Array if children
    image_url => String if image_url

    super
  end

  def has_children?
    !children.empty?
  end
end