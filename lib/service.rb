class Service < Data.define(:service, :url, :children)
  def initialize(service:, url: nil, children: [])
    raise ArgumentError, "Service cannot be empty" if service.nil? || service.empty?

    service => String
    url => String if url
    children => Array if children

    super
  end
end