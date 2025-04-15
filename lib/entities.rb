class Service < Data.define(:service, :url, :children)
  def initialize(service:, url: nil, children: [])
    raise ArgumentError, "Сервис не может быть пустым" if service.nil? || service.empty?

    service => String
    url => String if url
    children => Array if children
    # type => String if type

    super
  end
end


Domain = Data.define(:domain, :dns, :registrar)
Hosting = Data.define(:hosting, :cdn, :ssl, :repo)
# Deploy = Data.define(:deploy_method, :ci)
# Mail = Data.define(:service, :address, :aliases)

# STRUCTURE = {
#   domain: Domain,
#   hosting: Hosting,
#   deploy: Deploy,
#   integrations: Integrations,
#   infrastructure: Infrastructure
# }
