# Core data structures for domain and hosting information
Domain = Data.define(:domain, :dns, :registrar)
Hosting = Data.define(:hosting, :cdn, :ssl, :repo)
